import { prisma } from "../config/prisma.js";

export const getCurrentWeekMenu = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const today = new Date();

    const menu = await prisma.weeklyMenu.findFirst({
      where: {
        hostelId,
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
      message: process.env.NODE_ENV === "production" ? "Failed to fetch weekly menu" : error.message
    });
  }
};

export const createMenu = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
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
        hostelId,
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
      message: process.env.NODE_ENV === "production" ? "Failed to create menu" : error.message,
    });
  }
};

export const updateMenu = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
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

    const existingMenu = await prisma.weeklyMenu.findFirst({
      where: { id, hostelId },
      select: { id: true }
    });

    if (!existingMenu) {
      return res.status(404).json({
        success: false,
        message: "Menu not found"
      });
    }

    await prisma.weeklyMenuItem.deleteMany({
      where: { weeklyMenuId: id, weeklyMenu: { hostelId } }
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
      message: process.env.NODE_ENV === "production" ? "Failed to update menu" : error.message
    });
  }
};