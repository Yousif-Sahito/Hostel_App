import { prisma } from "../config/prisma.js";

export const getCurrentWeekMenu = async (req, res) => {
  try {
    const today = new Date();

    const menu = await prisma.weeklyMenu.findFirst({
      where: {
        weekStartDate: {
          lte: today
        }
      },
      include: {
        items: true
      },
      orderBy: {
        weekStartDate: "desc"
      }
    });

    res.json({
      success: true,
      message: "Current week menu fetched",
      data: menu
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const createMenu = async (req, res) => {
  try {
    const { weekStartDate, items } = req.body;

    if (!weekStartDate || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: "weekStartDate and items are required"
      });
    }

    const cleanedItems = items.map((item) => ({
      dayName: item.dayName,
      breakfast: item.breakfast,
      lunch: item.lunch,
      dinner: item.dinner,
    }));

    const menu = await prisma.weeklyMenu.create({
      data: {
        weekStartDate: new Date(weekStartDate),
        createdBy: req.user.id,
        items: {
          create: cleanedItems,
        },
      },
      include: {
        items: true,
      },
    });

    res.status(201).json({
      success: true,
      message: "Weekly menu created",
      data: menu,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const updateMenu = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { items } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: "items array is required and cannot be empty"
      });
    }

    const cleanedItems = items.map((item) => ({
      dayName: item.dayName,
      breakfast: item.breakfast,
      lunch: item.lunch,
      dinner: item.dinner,
    }));

    await prisma.weeklyMenuItem.deleteMany({
      where: { weeklyMenuId: id }
    });

    const menu = await prisma.weeklyMenu.update({
      where: { id },
      data: {
        items: {
          create: cleanedItems
        }
      },
      include: { items: true }
    });

    res.json({
      success: true,
      message: "Menu updated",
      data: menu
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};