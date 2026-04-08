import { prisma } from "../config/prisma.js";

export const recordMeal = async (req, res) => {
  try {
    const { userId, date, breakfast, lunch, dinner, guestCount } = req.body;

    if (!userId || !date) {
      return res.status(400).json({
        success: false,
        message: "userId and date are required"
      });
    }

    const mealDate = new Date(date);

    const existingMeal = await prisma.mealEntry.findFirst({
      where: {
        userId: Number(userId),
        mealDate
      }
    });

    let meal;

    if (existingMeal) {
      meal = await prisma.mealEntry.update({
        where: { id: existingMeal.id },
        data: {
          breakfastTaken: breakfast ?? existingMeal.breakfastTaken,
          lunchTaken: lunch ?? existingMeal.lunchTaken,
          dinnerTaken: dinner ?? existingMeal.dinnerTaken,
          guestCount: guestCount !== undefined ? Number(guestCount) : existingMeal.guestCount
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
        mealDate,
        breakfastTaken: Boolean(breakfast),
        lunchTaken: Boolean(lunch),
        dinnerTaken: Boolean(dinner),
        guestCount: Number(guestCount || 0)
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
      message: error.message
    });
  }
};

export const getMemberMeals = async (req, res) => {
  try {
    const userId = Number(req.params.id);

    const meals = await prisma.mealEntry.findMany({
      where: { userId },
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
      message: error.message
    });
  }
};
export const getMeals = async (req, res) => {
  try {
    const meals = await prisma.mealEntry.findMany({
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
      message: error.message
    });
  }
};
export const updateMeal = async (req, res) => {
  try {
    const mealId = Number(req.params.id);
    const { breakfast, lunch, dinner, guestCount, date } = req.body;

    const existingMeal = await prisma.mealEntry.findUnique({
      where: { id: mealId }
    });

    if (!existingMeal) {
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
      message: error.message
    });
  }
};

export const deleteMeal = async (req, res) => {
  try {
    const mealId = Number(req.params.id);

    const existingMeal = await prisma.mealEntry.findUnique({
      where: { id: mealId }
    });

    if (!existingMeal) {
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
      message: error.message
    });
  }
};

export const bulkRecordMeals = async (req, res) => {
  try {
    const { date, meals } = req.body;
    // meals = [{ userId, breakfast, lunch, dinner, guestCount }, ...]

    if (!date || !meals || !Array.isArray(meals)) {
      return res.status(400).json({
        success: false,
        message: "date and meals array are required"
      });
    }

    const mealDate = new Date(date);

    await prisma.$transaction(async (tx) => {
      for (const m of meals) {
        const existingMeal = await tx.mealEntry.findFirst({
          where: {
            userId: Number(m.userId),
            mealDate
          }
        });

        if (existingMeal) {
          await tx.mealEntry.update({
            where: { id: existingMeal.id },
            data: {
              breakfastTaken: Boolean(m.breakfast),
              lunchTaken: Boolean(m.lunch),
              dinnerTaken: Boolean(m.dinner),
              guestCount: Number(m.guestCount || 0)
            }
          });
        } else {
          await tx.mealEntry.create({
            data: {
              userId: Number(m.userId),
              mealDate,
              breakfastTaken: Boolean(m.breakfast),
              lunchTaken: Boolean(m.lunch),
              dinnerTaken: Boolean(m.dinner),
              guestCount: Number(m.guestCount || 0),
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
      message: error.message
    });
  }
};