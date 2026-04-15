import { prisma } from "../config/prisma.js";

export const recordMeal = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const { userId, date, breakfast, lunch, dinner, guestCount } = req.body;

    if (!userId || !date) {
      return res.status(400).json({
        success: false,
        message: "userId and date are required"
      });
    }

    const mealDate = new Date(date);
    const member = await prisma.user.findUnique({
      where: { id: Number(userId) },
      select: { id: true, mealUnitEnabled: true, role: true, hostelId: true }
    });

    if (!member || member.role !== "MEMBER" || member.hostelId !== hostelId) {
      return res.status(404).json({
        success: false,
        message: "Member not found"
      });
    }

    const normalizedBreakfast = member.mealUnitEnabled ? Boolean(breakfast) : false;
    const normalizedLunch = member.mealUnitEnabled ? Boolean(lunch) : false;
    const normalizedDinner = member.mealUnitEnabled ? Boolean(dinner) : false;
    const normalizedGuestCount = member.mealUnitEnabled ? Number(guestCount || 0) : 0;

    const existingMeal = await prisma.mealEntry.findFirst({
      where: {
        hostelId,
        userId: Number(userId),
        mealDate
      }
    });

    let meal;

    if (existingMeal) {
      meal = await prisma.mealEntry.update({
        where: { id: existingMeal.id },
        data: {
          breakfastTaken: normalizedBreakfast,
          lunchTaken: normalizedLunch,
          dinnerTaken: normalizedDinner,
          guestCount: normalizedGuestCount
        }
      });

      return res.json({
        success: true,
        message: "Meal updated successfully",
        data: meal
      });
    }

    meal = await prisma.mealEntry.create({
      data: {
        userId: Number(userId),
        hostelId,
        mealDate,
        breakfastTaken: normalizedBreakfast,
        lunchTaken: normalizedLunch,
        dinnerTaken: normalizedDinner,
        guestCount: normalizedGuestCount
      }
    });

    res.status(201).json({
      success: true,
      message: "Meal recorded successfully",
      data: meal
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch meals" : error.message
    });
  }
};

export const getMemberMeals = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const userId = Number(req.params.id);

    const meals = await prisma.mealEntry.findMany({
      where: { userId, hostelId },
      orderBy: { mealDate: "desc" }
    });

    res.json({
      success: true,
      message: "Meals fetched successfully",
      data: meals
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to add meal" : error.message
    });
  }
};
export const getMeals = async (req, res) => {
  try {
    const meals = await prisma.mealEntry.findMany({
      where: { hostelId: req.user.hostelId },
      include: {
        user: true
      },
      orderBy: {
        mealDate: "desc"
      }
    });

    res.json({
      success: true,
      message: "Meals fetched successfully",
      data: meals
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to update meal" : error.message
    });
  }
};
export const updateMeal = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const mealId = Number(req.params.id);
    const { breakfast, lunch, dinner, guestCount, date } = req.body;

    const existingMeal = await prisma.mealEntry.findUnique({
      where: { id: mealId }
    });

    if (!existingMeal || existingMeal.hostelId !== hostelId) {
      return res.status(404).json({
        success: false,
        message: "Meal entry not found"
      });
    }

    const updatedMeal = await prisma.mealEntry.update({
      where: { id: mealId },
      data: {
        mealDate: date ? new Date(date) : existingMeal.mealDate,
        breakfastTaken: breakfast ?? existingMeal.breakfastTaken,
        lunchTaken: lunch ?? existingMeal.lunchTaken,
        dinnerTaken: dinner ?? existingMeal.dinnerTaken,
        guestCount: guestCount !== undefined ? Number(guestCount) : existingMeal.guestCount
      }
    });

    res.json({
      success: true,
      message: "Meal updated successfully",
      data: updatedMeal
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to delete meal" : error.message
    });
  }
};

export const deleteMeal = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const mealId = Number(req.params.id);

    const existingMeal = await prisma.mealEntry.findUnique({
      where: { id: mealId }
    });

    if (!existingMeal || existingMeal.hostelId !== hostelId) {
      return res.status(404).json({
        success: false,
        message: "Meal entry not found"
      });
    }

    await prisma.mealEntry.delete({
      where: { id: mealId }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to get meal summary" : error.message
    });
  }
};

export const bulkRecordMeals = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const { date, meals } = req.body;
    // meals = [{ userId, breakfast, lunch, dinner, guestCount }, ...]

    if (!date || !meals || !Array.isArray(meals)) {
      return res.status(400).json({
        success: false,
        message: "date and meals array are required"
      });
    }

    const mealDate = new Date(date);
    const requestedMemberIds = meals.map((m) => Number(m.userId)).filter((id) => !Number.isNaN(id));
    const members = await prisma.user.findMany({
      where: {
        id: { in: requestedMemberIds },
        hostelId,
        role: "MEMBER"
      },
      select: { id: true, mealUnitEnabled: true }
    });
    const memberById = new Map(members.map((m) => [m.id, m]));

    await prisma.$transaction(async (tx) => {
      for (const m of meals) {
        const currentMember = memberById.get(Number(m.userId));
        if (!currentMember) {
          continue;
        }

        const normalizedBreakfast = currentMember.mealUnitEnabled ? Boolean(m.breakfast) : false;
        const normalizedLunch = currentMember.mealUnitEnabled ? Boolean(m.lunch) : false;
        const normalizedDinner = currentMember.mealUnitEnabled ? Boolean(m.dinner) : false;
        const normalizedGuestCount = currentMember.mealUnitEnabled ? Number(m.guestCount || 0) : 0;

        const existingMeal = await tx.mealEntry.findFirst({
          where: {
            userId: Number(m.userId),
            hostelId,
            mealDate
          }
        });

        if (existingMeal) {
          await tx.mealEntry.update({
            where: { id: existingMeal.id },
            data: {
              breakfastTaken: normalizedBreakfast,
              lunchTaken: normalizedLunch,
              dinnerTaken: normalizedDinner,
              guestCount: normalizedGuestCount
            }
          });
        } else {
          await tx.mealEntry.create({
            data: {
              userId: Number(m.userId),
              hostelId,
              mealDate,
              breakfastTaken: normalizedBreakfast,
              lunchTaken: normalizedLunch,
              dinnerTaken: normalizedDinner,
              guestCount: normalizedGuestCount,
              createdBy: req.user.id
            }
          });
        }
      }
    });

    res.json({
      success: true,
      message: "Bulk meals recorded successfully"
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to get monthly summary" : error.message
    });
  }
};