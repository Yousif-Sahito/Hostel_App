import { sendNotification, sendMulticastNotification } from '../config/firebase.js';
import { prisma } from '../config/prisma.js';

// Send notification when member marks mess off
export const sendMessOffNotification = async (userId, memberName, messOffStatus) => {
  try {
    // Get all admin users
    const admins = await prisma.user.findMany({
      where: { role: 'ADMIN', fcmToken: { not: null } },
    });

    if (!admins.length) {
      console.log('No admin with FCM token found');
      return;
    }

    const adminTokens = admins.map((admin) => admin.fcmToken);
    const title = 'Mess Off Alert';
    const body = `${memberName} has ${messOffStatus === 'ACTIVE' ? 'marked' : 'cancelled'} their mess off`;

    const data = {
      type: 'MESS_OFF',
      userId: userId.toString(),
      messOffStatus,
      timestamp: new Date().toISOString(),
    };

    await sendMulticastNotification(adminTokens, title, body, data);
    console.log(`Mess off notification sent to ${adminTokens.length} admins`);
  } catch (error) {
    console.error('Error sending mess off notification:', error);
  }
};

// Send notification to member about unpaid bill
export const sendUnpaidBillNotification = async (userId, userName, amount, daysOverdue) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });

    if (!user?.fcmToken) {
      console.log('User FCM token not found');
      return;
    }

    const title = 'Unpaid Bill Reminder';
    const body = `Your bill of PKR ${amount} is ${daysOverdue} days overdue. Please pay as soon as possible.`;

    const data = {
      type: 'UNPAID_BILL',
      userId: userId.toString(),
      amount: amount.toString(),
      daysOverdue: daysOverdue.toString(),
      timestamp: new Date().toISOString(),
    };

    await sendNotification(user.fcmToken, title, body, data);
    console.log(`Unpaid bill notification sent to user ${userId}`);
  } catch (error) {
    console.error('Error sending unpaid bill notification:', error);
  }
};

// Send notification to admin for new payment received
export const sendPaymentReceivedNotification = async (
  adminId,
  memberName,
  amount
) => {
  try {
    const admin = await prisma.user.findUnique({
      where: { id: adminId },
      select: { fcmToken: true },
    });

    if (!admin?.fcmToken) {
      console.log('Admin FCM token not found');
      return;
    }

    const title = 'Payment Received';
    const body = `${memberName} has paid PKR ${amount}`;

    const data = {
      type: 'PAYMENT_RECEIVED',
      adminId: adminId.toString(),
      amount: amount.toString(),
      timestamp: new Date().toISOString(),
    };

    await sendNotification(admin.fcmToken, title, body, data);
    console.log(`Payment received notification sent to admin ${adminId}`);
  } catch (error) {
    console.error('Error sending payment received notification:', error);
  }
};

// Batch send unpaid bill notifications to all members with overdue bills
export const sendBatchUnpaidBillNotifications = async (daysThreshold = 30) => {
  try {
    // Get all unpaid bills older than specified days
    const unpaidBills = await prisma.bill.findMany({
      where: {
        status: 'UNPAID',
        createdAt: {
          lte: new Date(Date.now() - daysThreshold * 24 * 60 * 60 * 1000),
        },
      },
      include: {
        user: {
          select: { id: true, fullName: true, fcmToken: true },
        },
      },
    });

    for (const bill of unpaidBills) {
      if (bill.user.fcmToken) {
        const daysOverdue = Math.floor(
          (Date.now() - bill.createdAt.getTime()) / (24 * 60 * 60 * 1000)
        );
        await sendUnpaidBillNotification(
          bill.user.id,
          bill.user.fullName,
          bill.amount,
          daysOverdue
        );
      }
    }

    console.log(
      `Sent batch unpaid bill notifications to ${unpaidBills.length} members`
    );
  } catch (error) {
    console.error('Error sending batch unpaid bill notifications:', error);
  }
};
