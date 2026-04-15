import { prisma } from "../config/prisma.js";

const getTodayDayName = () => {
  return new Date().toLocaleDateString("en-US", { weekday: "long" });
};

const getCurrentMonthYear = () => {
  const now = new Date();
  return {
    month: now.getMonth() + 1,
    year: now.getFullYear(),
  };
};

export const getAdminDashboardStats = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const { month, year } = getCurrentMonthYear();
    const todayDay = getTodayDayName();

    const today = new Date();
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const todayEnd = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStart = new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate());
    const tomorrowEnd = new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate() + 1);

    // Get members that are on mess off today
    const membersOnMessOffToday = await prisma.messOffPeriod.findMany({
      where: {
        hostelId,
        status: "ACTIVE",
        fromDate: { lte: todayEnd },
        toDate: { gte: todayStart }
      },
      select: { userId: true }
    });

    const messOffUserIds = membersOnMessOffToday.map(m => m.userId);

    const [
      totalMembers,
      activeMembers,
      pendingBills,
      monthlyBills,
      settings,
      weeklyMenu,
      tomorrowMessOffCount
    ] = await Promise.all([
      prisma.user.count({
        where: { role: "MEMBER", hostelId },
      }),
      prisma.user.count({
        where: { 
          hostelId,
          role: "MEMBER", 
          status: "ACTIVE",
          ...(messOffUserIds.length > 0 && { id: { notIn: messOffUserIds } })
        },
      }),
      prisma.bill.count({
        where: {
          hostelId,
          paymentStatus: {
            in: ["UNPAID", "PARTIAL"],
          },
        },
      }),
      prisma.bill.findMany({
        where: { month, year, hostelId },
        select: { paidAmount: true },
      }),
      prisma.hostelSetting.findFirst({
        where: { hostelId },
        orderBy: { id: "desc" },
      }),
      prisma.weeklyMenu.findFirst({
        where: { hostelId },
        orderBy: { weekStartDate: "desc" },
        include: { items: true },
      }),
      prisma.messOffPeriod.count({
        where: {
          hostelId,
          status: "ACTIVE",
          fromDate: { lte: tomorrowEnd },
          toDate: { gte: tomorrowStart }
        }
      })
    ]);

    const monthlyCollection = monthlyBills.reduce(
      (sum, bill) => sum + Number(bill.paidAmount || 0),
      0
    );

    const todayMenuItem = weeklyMenu?.items?.find(
      (item) => item.dayName?.toLowerCase() === todayDay.toLowerCase()
    );

    const todayMenu = todayMenuItem
      ? `${todayMenuItem.breakfast}, ${todayMenuItem.lunch}, ${todayMenuItem.dinner}`
      : "No menu available";

    return res.json({
      success: true,
      message: "Admin dashboard fetched successfully",
      data: {
        totalMembers,
        activeMembers,
        pendingBills,
        monthlyCollection,
        messStatus: settings?.messStatus || "ON",
        todayMenu,
        tomorrowMessOffCount
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch dashboard data" : error.message,
    });
  }
};

export const getMemberDashboardStats = async (req, res) => {
  try {
    const userId = req.user.id;
    const hostelId = req.user.hostelId;
    const { month, year } = getCurrentMonthYear();
    const todayDay = getTodayDayName();

    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);

    const [settings, weeklyMenu, monthlyMealEntries, currentBill, activeMessOff, tomorrowMessOff] =
      await Promise.all([
        prisma.hostelSetting.findFirst({
          where: { hostelId },
          orderBy: { id: "desc" },
        }),
        prisma.weeklyMenu.findFirst({
          where: { hostelId },
          orderBy: { weekStartDate: "desc" },
          include: { items: true },
        }),
        prisma.mealEntry.findMany({
          where: {
            userId,
            hostelId,
            mealDate: {
              gte: new Date(year, month - 1, 1),
              lt: new Date(year, month, 1),
            },
          },
          select: {
            breakfastTaken: true,
            lunchTaken: true,
            dinnerTaken: true,
            guestCount: true,
          },
        }),
        prisma.bill.findUnique({
          where: {
            hostelId_userId_month_year: {
              hostelId,
              userId,
              month,
              year,
            },
          },
        }),
        prisma.messOffPeriod.findFirst({
          where: {
            userId,
            hostelId,
            status: "ACTIVE",
            fromDate: { lte: new Date() },
            toDate: { gte: new Date() }
          }
        }),
        prisma.messOffPeriod.findFirst({
          where: {
            userId,
            hostelId,
            status: "ACTIVE",
            fromDate: { lte: tomorrow },
            toDate: { gte: tomorrow }
          }
        })
      ]);

    const todayMenuItem = weeklyMenu?.items?.find(
      (item) => item.dayName?.toLowerCase() === todayDay.toLowerCase()
    );

    const todayMenu = todayMenuItem
      ? `${todayMenuItem.breakfast}, ${todayMenuItem.lunch}, ${todayMenuItem.dinner}`
      : "No menu available";

    const monthlyUnits = monthlyMealEntries.reduce((sum, entry) => {
      let units = 0;
      if (entry.breakfastTaken) units += 1;
      if (entry.lunchTaken) units += 1;
      if (entry.dinnerTaken) units += 1;
      units += Number(entry.guestCount || 0);
      return sum + units;
    }, 0);
    
    let finalMessStatus = settings?.messStatus || "ON";
    if (activeMessOff) {
      finalMessStatus = "OFF";
    }

    return res.json({
      success: true,
      message: "Member dashboard fetched successfully",
      data: {
        todayMenu,
        messStatus: finalMessStatus,
        tomorrowMessStatus: tomorrowMessOff ? "OFF" : "ON",
        monthlyUnits,
        currentBill: Number(currentBill?.totalAmount || 0),
        dueAmount: Number(currentBill?.dueAmount || 0),
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch dashboard analytics" : error.message,
    });
  }
};