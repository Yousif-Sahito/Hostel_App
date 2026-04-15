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

export const generateMonthlyBillsService = async (month, year, memberId, hostelId) => {
  // Validate month and year
  if (!month || !year || month < 1 || month > 12 || year < 2000) {
    throw new Error('Invalid month (1-12) or year (2000+)');
  }

  const userFilter = {
    hostelId,
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
    where: { month, year, hostelId }
  });

  const messOffPeriods = await prisma.messOffPeriod.findMany({
    where: {
      hostelId,
      status: "ACTIVE"
    }
  });

  const attendanceRecords = await prisma.attendance.findMany({
    where: {
      hostelId,
      attendanceDate: {
        gte: new Date(year, month - 1, 1),
        lt: new Date(year, month, 1)
      }
    }
  });

  const mealEntries = await prisma.mealEntry.findMany({
    where: {
      hostelId,
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
    const currentMember = members.find((m) => m.id === meal.userId);
    if (!currentMember || currentMember.mealUnitEnabled === false) continue;

    const isMessOff = messOffPeriods.some(
      (period) =>
        period.userId === meal.userId &&
        isDateInRange(meal.mealDate, period.fromDate, period.toDate)
    );

    // Only disable units when an attendance record explicitly marks the member as absent.
    // Present attendance should not prevent meal units from being counted.
    const isAbsentAttendance = attendanceRecords.some(
      (record) =>
        record.userId === meal.userId &&
        record.attendanceDate.toDateString() === meal.mealDate.toDateString() &&
        record.isPresent === false
    );

    if (isMessOff || isAbsentAttendance) continue;

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

  const settings = await prisma.hostelSetting.findFirst({ where: { hostelId } });

  if (!settings) {
    throw new Error("Hostel settings not found");
  }

  const breakfastRate = settings.breakfastPrice || settings.mealRate || 0;
  const lunchRate = settings.lunchPrice || settings.mealRate || 0;
  const dinnerRate = settings.dinnerPrice || settings.mealRate || 0;
  const guestMealRate = settings.guestMealPrice || settings.mealRate || 0;
  const helperPerMember = helperCharge?.perMemberAmount || 0;

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

    totalMealExpense += baseAmount;

    const existingBill = await prisma.bill.findUnique({
      where: {
        hostelId_userId_month_year: {
          hostelId,
          userId: member.id,
          month,
          year
        }
      }
    });

    const existingPaidAmount = existingBill ? existingBill.paidAmount : 0;
    const existingExtraCharges = existingBill ? existingBill.extraCharges : 0;
    const finalTotal = totalAmount + existingExtraCharges;
    const currentDueBeforeAdvance = Math.max(finalTotal - existingPaidAmount, 0);
    const mealDeductionFromAdvance = Math.min(member.advanceBalance || 0, currentDueBeforeAdvance);
    const remainingAdvanceBalance = (member.advanceBalance || 0) - mealDeductionFromAdvance;
    const finalPaidAmount = existingPaidAmount + mealDeductionFromAdvance;
    const finalDue = finalTotal - finalPaidAmount;

    const bill = await prisma.bill.upsert({
      where: {
        hostelId_userId_month_year: {
          hostelId,
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
        paidAmount: finalPaidAmount,
        dueAmount: finalDue,
        paymentStatus:
          finalPaidAmount <= 0
            ? (finalDue <= 0 ? "PAID" : "UNPAID")
            : (finalDue <= 0 ? "PAID" : "PARTIAL")
      },
      create: {
        userId: member.id,
        hostelId,
        month,
        year,
        breakfastUnits: unitData.breakfastUnits,
        lunchUnits: unitData.lunchUnits,
        dinnerUnits: unitData.dinnerUnits,
        guestUnits: unitData.guestUnits,
        helperCharge: helperPerMember,
        extraCharges: 0,
        totalAmount,
        paidAmount: mealDeductionFromAdvance,
        dueAmount: totalAmount - mealDeductionFromAdvance,
        paymentStatus: (totalAmount - mealDeductionFromAdvance) <= 0 ? "PAID" : "UNPAID"
      }
    });

    if (mealDeductionFromAdvance > 0) {
      await prisma.user.update({
        where: { id: member.id },
        data: { advanceBalance: remainingAdvanceBalance }
      });
    }

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