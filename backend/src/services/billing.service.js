import { prisma } from "../config/prisma.js";

const UNIT_VALUES = {
  breakfast: 1,
  lunch: 1,
  dinner: 1
};

const isDateInRange = (date, fromDate, toDate) => {
  const d = new Date(date);
  const from = new Date(fromDate);
  const to = new Date(toDate);
  return d >= from && d <= to;
};

export const generateMonthlyBillsService = async (month, year, memberId) => {
  // Validate month and year
  if (!month || !year || month < 1 || month > 12 || year < 2000) {
    throw new Error('Invalid month (1-12) or year (2000+)');
  }

  const userFilter = {
    role: "MEMBER",
    status: "ACTIVE",
    ...(memberId ? { id: memberId } : {})
  };

  const members = await prisma.user.findMany({
    where: userFilter
  });

  if (memberId && members.length === 0) {
    throw new Error("Member not found or inactive");
  }

  const helperCharge = await prisma.helperCharge.findFirst({
    where: { month, year }
  });

  const messOffPeriods = await prisma.messOffPeriod.findMany({
    where: {
      status: "ACTIVE"
    }
  });

  const attendanceRecords = await prisma.attendance.findMany({
    where: {
      attendanceDate: {
        gte: new Date(year, month - 1, 1),
        lt: new Date(year, month, 1)
      }
    }
  });

  const mealEntries = await prisma.mealEntry.findMany({
    where: {
      mealDate: {
        gte: new Date(year, month - 1, 1),
        lt: new Date(year, month, 1)
      }
    }
  });

  let totalSystemUnits = 0;
  const memberUnitMap = {};

  for (const member of members) {
    memberUnitMap[member.id] = {
      breakfastUnits: 0,
      lunchUnits: 0,
      dinnerUnits: 0,
      guestUnits: 0,
      totalUnits: 0
    };
  }

  for (const meal of mealEntries) {
    const member = memberUnitMap[meal.userId];
    if (!member) continue;

    const isMessOff = messOffPeriods.some(
      (period) =>
        period.userId === meal.userId &&
        isDateInRange(meal.mealDate, period.fromDate, period.toDate)
    );

    // If member is marked as in attendance, units are disabled (don't count)
    const isInAttendance = attendanceRecords.some(
      (record) =>
        record.userId === meal.userId &&
        record.attendanceDate.toDateString() === meal.mealDate.toDateString() &&
        record.isPresent === true
    );

    if (isMessOff || isInAttendance) continue;

    if (meal.breakfastTaken) {
      member.breakfastUnits += UNIT_VALUES.breakfast;
      member.totalUnits += UNIT_VALUES.breakfast;
      totalSystemUnits += UNIT_VALUES.breakfast;
    }

    if (meal.lunchTaken) {
      member.lunchUnits += UNIT_VALUES.lunch;
      member.totalUnits += UNIT_VALUES.lunch;
      totalSystemUnits += UNIT_VALUES.lunch;
    }

    if (meal.dinnerTaken) {
      member.dinnerUnits += UNIT_VALUES.dinner;
      member.totalUnits += UNIT_VALUES.dinner;
      totalSystemUnits += UNIT_VALUES.dinner;
    }

    if (meal.guestCount > 0) {
      member.guestUnits += meal.guestCount;
    }
  }

  const settings = await prisma.hostelSetting.findFirst();

  if (!settings) {
    throw new Error("Hostel settings not found");
  }

  const breakfastRate = settings.breakfastPrice || settings.mealRate || 0;
  const lunchRate = settings.lunchPrice || settings.mealRate || 0;
  const dinnerRate = settings.dinnerPrice || settings.mealRate || 0;
  const guestMealRate = settings.guestMealPrice || settings.mealRate || 0;
  const helperPerMember = settings.helperCharge || 0;

  let totalMealExpense = 0;

  const generatedBills = [];

  for (const member of members) {
    const unitData = memberUnitMap[member.id];
    const breakfastAmount = unitData.breakfastUnits * breakfastRate;
    const lunchAmount = unitData.lunchUnits * lunchRate;
    const dinnerAmount = unitData.dinnerUnits * dinnerRate;
    const guestAmount = unitData.guestUnits * guestMealRate;
    const baseAmount = breakfastAmount + lunchAmount + dinnerAmount + guestAmount;
    const totalAmount = baseAmount + helperPerMember;
    const dueAmount = totalAmount;

    totalMealExpense += baseAmount;

    const existingBill = await prisma.bill.findUnique({
      where: {
        userId_month_year: {
          userId: member.id,
          month,
          year
        }
      }
    });

    const existingPaidAmount = existingBill ? existingBill.paidAmount : 0;
    const existingExtraCharges = existingBill ? existingBill.extraCharges : 0;
    const finalTotal = totalAmount + existingExtraCharges;
    const finalDue = finalTotal - existingPaidAmount;

    const bill = await prisma.bill.upsert({
      where: {
        userId_month_year: {
          userId: member.id,
          month,
          year
        }
      },
      update: {
        breakfastUnits: unitData.breakfastUnits,
        lunchUnits: unitData.lunchUnits,
        dinnerUnits: unitData.dinnerUnits,
        guestUnits: unitData.guestUnits,
        helperCharge: helperPerMember,
        totalAmount: finalTotal,
        dueAmount: finalDue,
        paymentStatus:
          existingPaidAmount <= 0
            ? (finalDue <= 0 ? "PAID" : "UNPAID")
            : (finalDue <= 0 ? "PAID" : "PARTIAL")
      },
      create: {
        userId: member.id,
        month,
        year,
        breakfastUnits: unitData.breakfastUnits,
        lunchUnits: unitData.lunchUnits,
        dinnerUnits: unitData.dinnerUnits,
        guestUnits: unitData.guestUnits,
        helperCharge: helperPerMember,
        extraCharges: 0,
        totalAmount,
        paidAmount: 0,
        dueAmount,
        paymentStatus: dueAmount <= 0 ? "PAID" : "UNPAID"
      }
    });

    generatedBills.push(bill);
  }

  return {
    totalMembers: members.length,
    totalSystemUnits,
    totalMealExpense,
    helperPerMember,
    bills: generatedBills
  };
};