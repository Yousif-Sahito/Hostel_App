import { prisma } from "../config/prisma.js";

export const getSettings = async (req, res) => {
  try {
    const settings = await prisma.hostelSetting.findFirst({
      orderBy: { id: "desc" }
    });

    if (!settings) {
      return res.status(404).json({
        success: false,
        message: "Settings not found"
      });
    }

    res.json({
      success: true,
      message: "Settings fetched successfully",
      data: settings
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const createSettings = async (req, res) => {
  try {
    const {
      hostelName,
      messStatus,
      breakfastPrice,
      lunchPrice,
      dinnerPrice,
      guestMealPrice
    } = req.body;

    const existing = await prisma.hostelSetting.findFirst();

    if (existing) {
      return res.status(400).json({
        success: false,
        message: "Settings already exist. Use update instead."
      });
    }

    const settings = await prisma.hostelSetting.create({
      data: {
        hostelName: hostelName || "Hostel Mess",
        breakfastPrice: Number(breakfastPrice) || 150,
        lunchPrice: Number(lunchPrice) || 200,
        dinnerPrice: Number(dinnerPrice) || 200,
        guestMealPrice: Number(guestMealPrice) || 250,
        messStatus: messStatus || "ON"
      }
    });

    res.status(201).json({
      success: true,
      message: "Settings created successfully",
      data: settings
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const updateSettings = async (req, res) => {
  try {
    const existing = await prisma.hostelSetting.findFirst();

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Settings not found"
      });
    }

    const {
      hostelName,
      messStatus,
      breakfastPrice,
      lunchPrice,
      dinnerPrice,
      guestMealPrice
    } = req.body;

    const settings = await prisma.hostelSetting.update({
      where: { id: existing.id },
      data: {
        ...(hostelName && { hostelName }),
        ...(breakfastPrice !== undefined && { breakfastPrice: Number(breakfastPrice) }),
        ...(lunchPrice !== undefined && { lunchPrice: Number(lunchPrice) }),
        ...(dinnerPrice !== undefined && { dinnerPrice: Number(dinnerPrice) }),
        ...(guestMealPrice !== undefined && { guestMealPrice: Number(guestMealPrice) }),
        ...(messStatus && { messStatus })
      }
    });

    res.json({
      success: true,
      message: "Settings updated successfully",
      data: settings
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};