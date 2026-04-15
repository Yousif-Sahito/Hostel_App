import { sendNotification } from "../config/firebase.js";
import { prisma } from "../config/prisma.js";

const oneDayMs = 24 * 60 * 60 * 1000;

const normalizeData = (data = {}) =>
  Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, String(value)])
  );

const getUserPushTokens = async (userId) => {
  const [deviceTokens, user] = await Promise.all([
    prisma.deviceToken.findMany({
      where: { userId, isActive: true },
      select: { token: true }
    }),
    prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true }
    })
  ]);

  const tokens = new Set(deviceTokens.map((item) => item.token));
  if (user?.fcmToken) {
    tokens.add(user.fcmToken);
  }

  return [...tokens];
};

const deactivateInvalidToken = async (token) => {
  await prisma.deviceToken.updateMany({
    where: { token },
    data: { isActive: false }
  });
};

export const createAndSendNotification = async ({
  hostelId,
  userIds,
  title,
  body,
  type,
  data = {}
}) => {
  if (!Array.isArray(userIds) || userIds.length === 0) {
    return;
  }

  const normalizedData = normalizeData(data);
  const uniqueUserIds = [...new Set(userIds)];

  await prisma.notification.createMany({
    data: uniqueUserIds.map((userId) => ({
      hostelId,
      userId,
      title,
      body,
      type,
      data: normalizedData
    }))
  });

  for (const userId of uniqueUserIds) {
    const tokens = await getUserPushTokens(userId);
    for (const token of tokens) {
      try {
        await sendNotification(token, title, body, {
          ...normalizedData,
          type
        });
      } catch (error) {
        const code = error?.errorInfo?.code || "";
        if (code.includes("registration-token-not-registered")) {
          await deactivateInvalidToken(token);
        }
      }
    }
  }
};

export const sendMessOffNotification = async (userId, memberName, messOffStatus) => {
  const member = await prisma.user.findUnique({
    where: { id: userId },
    select: { hostelId: true }
  });
  if (!member?.hostelId) return;

  const admins = await prisma.user.findMany({
    where: { role: "ADMIN", status: "ACTIVE", hostelId: member.hostelId },
    select: { id: true }
  });

  if (!admins.length) return;

  const isActive = messOffStatus === "ACTIVE";
  await createAndSendNotification({
    userIds: admins.map((admin) => admin.id),
    hostelId: member.hostelId,
    title: "Mess Off Alert",
    body: `${memberName} has ${isActive ? "marked" : "cancelled"} mess off.`,
    type: isActive ? "MESS_OFF_ON" : "MESS_OFF_CANCELLED",
    data: {
      memberId: userId,
      messOffStatus
    }
  });
};

export const sendPaymentReceivedNotification = async ({ memberName, amount, memberId }) => {
  const member = await prisma.user.findUnique({
    where: { id: memberId },
    select: { hostelId: true }
  });
  if (!member?.hostelId) return;

  const admins = await prisma.user.findMany({
    where: { role: "ADMIN", status: "ACTIVE", hostelId: member.hostelId },
    select: { id: true }
  });

  if (!admins.length) return;

  await createAndSendNotification({
    userIds: admins.map((admin) => admin.id),
    hostelId: member.hostelId,
    title: "Payment Received",
    body: `${memberName} paid PKR ${Number(amount).toFixed(0)}.`,
    type: "PAYMENT_RECEIVED",
    data: {
      memberId,
      amount
    }
  });
};

export const sendBatchUnpaidBillNotifications = async () => {
  const overdueBills = await prisma.bill.findMany({
    where: {
      dueAmount: { gt: 0 },
      paymentStatus: { in: ["UNPAID", "PARTIAL"] }
    },
    include: {
      user: {
        select: { id: true, fullName: true }
      }
    }
  });

  for (const bill of overdueBills) {
    const daysOverdue = Math.floor(
      (Date.now() - bill.generatedAt.getTime()) / oneDayMs
    );

    if (daysOverdue !== 20 && daysOverdue !== 30) {
      continue;
    }

    const type = daysOverdue === 20 ? "PAYMENT_OVERDUE_20" : "PAYMENT_OVERDUE_30";
    const title =
      daysOverdue === 20 ? "Payment Reminder (20 days)" : "Payment Reminder (30 days)";
    const body = `Your pending dues are PKR ${bill.dueAmount.toFixed(0)}. Please clear your bill.`;

    await createAndSendNotification({
      hostelId: bill.hostelId,
      userIds: [bill.userId],
      title,
      body,
      type,
      data: {
        billId: bill.id,
        daysOverdue,
        dueAmount: bill.dueAmount
      }
    });
  }
};
