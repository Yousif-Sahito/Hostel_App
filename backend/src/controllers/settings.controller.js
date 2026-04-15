import { prisma } from "../config/prisma.js";

const normalizeHostelName = (value) =>
  String(value || "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ");

export const getSettings = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const hostel = await prisma.hostel.findFirst({
      where: { id: hostelId },
      select: { id: true, name: true }
    });
    const settings = await prisma.hostelSetting.findFirst({
      where: { hostelId },
      orderBy: { id: "desc" }
    });
    const latestHelperCharge = await prisma.helperCharge.findFirst({
      where: { hostelId },
      orderBy: [{ year: "desc" }, { month: "desc" }, { id: "desc" }]
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
      data: {
        ...settings,
        hostelName: hostel?.name || settings.hostelName,
        helperCharge: latestHelperCharge?.perMemberAmount || 0
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch settings" : error.message
    });
  }
};

export const createSettings = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const {
      hostelName,
      messStatus,
      breakfastPrice,
      lunchPrice,
      dinnerPrice,
      guestMealPrice,
      helperCharge
    } = req.body;

    const existing = await prisma.hostelSetting.findFirst({ where: { hostelId } });

    if (existing) {
      return res.status(400).json({
        success: false,
        message: "Settings already exist. Use update instead."
      });
    }

    const settings = await prisma.hostelSetting.create({
      data: {
        hostelName: hostelName || "Hostel Mess",
        hostelId,
        breakfastPrice: Number(breakfastPrice) || 150,
        lunchPrice: Number(lunchPrice) || 200,
        dinnerPrice: Number(dinnerPrice) || 200,
        guestMealPrice: Number(guestMealPrice) || 250,
        messStatus: messStatus || "ON"
      }
    });

    let resolvedHelperCharge = 0;
    if (helperCharge !== undefined) {
      const helperPerMember = Number(helperCharge) || 0;
      const activeMembersCount = await prisma.user.count({
        where: { hostelId, role: "MEMBER", status: "ACTIVE" }
      });
      const now = new Date();
      const month = now.getMonth() + 1;
      const year = now.getFullYear();
      const existingHelperCharge = await prisma.helperCharge.findFirst({
        where: { hostelId, month, year }
      });

      if (existingHelperCharge) {
        await prisma.helperCharge.update({
          where: { id: existingHelperCharge.id },
          data: {
            totalAmount: helperPerMember * activeMembersCount,
            perMemberAmount: helperPerMember
          }
        });
      } else {
        await prisma.helperCharge.create({
          data: {
            hostelId,
            month,
            year,
            totalAmount: helperPerMember * activeMembersCount,
            perMemberAmount: helperPerMember,
            createdBy: req.user.id
          }
        });
      }
      resolvedHelperCharge = helperPerMember;
    }

    res.status(201).json({
      success: true,
      message: "Settings created successfully",
      data: {
        ...settings,
        helperCharge: resolvedHelperCharge
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to update settings" : error.message
    });
  }
};

export const updateSettings = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const existing = await prisma.hostelSetting.findFirst({ where: { hostelId } });

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
      guestMealPrice,
      helperCharge
    } = req.body;

    const settings = await prisma.$transaction(async (tx) => {
      if (hostelName && hostelName.trim().length > 0) {
        const normalizedName = normalizeHostelName(hostelName);
        const existingHostel = await tx.hostel.findUnique({
          where: { normalizedName }
        });
        if (existingHostel && existingHostel.id !== hostelId) {
          throw new Error("Hostel already exists");
        }

        await tx.hostel.update({
          where: { id: hostelId },
          data: {
            name: hostelName.trim(),
            normalizedName
          }
        });
      }

      return tx.hostelSetting.update({
        where: { id: existing.id },
        data: {
          ...(hostelName && { hostelName: hostelName.trim() }),
          ...(breakfastPrice !== undefined && { breakfastPrice: Number(breakfastPrice) }),
          ...(lunchPrice !== undefined && { lunchPrice: Number(lunchPrice) }),
          ...(dinnerPrice !== undefined && { dinnerPrice: Number(dinnerPrice) }),
          ...(guestMealPrice !== undefined && { guestMealPrice: Number(guestMealPrice) }),
          ...(messStatus && { messStatus })
        }
      });
    });

    let resolvedHelperCharge = 0;
    const now = new Date();
    const month = now.getMonth() + 1;
    const year = now.getFullYear();

    if (helperCharge !== undefined) {
      const helperPerMember = Number(helperCharge) || 0;
      const activeMembersCount = await prisma.user.count({
        where: { hostelId, role: "MEMBER", status: "ACTIVE" }
      });
      const existingHelperCharge = await prisma.helperCharge.findFirst({
        where: { hostelId, month, year }
      });

      if (existingHelperCharge) {
        await prisma.helperCharge.update({
          where: { id: existingHelperCharge.id },
          data: {
            totalAmount: helperPerMember * activeMembersCount,
            perMemberAmount: helperPerMember
          }
        });
      } else {
        await prisma.helperCharge.create({
          data: {
            hostelId,
            month,
            year,
            totalAmount: helperPerMember * activeMembersCount,
            perMemberAmount: helperPerMember,
            createdBy: req.user.id
          }
        });
      }
      resolvedHelperCharge = helperPerMember;
    } else {
      const latestHelperCharge = await prisma.helperCharge.findFirst({
        where: { hostelId },
        orderBy: [{ year: "desc" }, { month: "desc" }, { id: "desc" }]
      });
      resolvedHelperCharge = latestHelperCharge?.perMemberAmount || 0;
    }

    res.json({
      success: true,
      message: "Settings updated successfully",
      data: {
        ...settings,
        helperCharge: resolvedHelperCharge
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to toggle mess status" : error.message
    });
  }
};