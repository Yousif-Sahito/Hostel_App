import { prisma } from "../config/prisma.js";

export const getHelperCharges = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const data = await prisma.helperCharge.findMany({
      where: { hostelId },
      include: {
        creator: true
      },
      orderBy: {
        id: "desc"
      }
    });

    res.json({
      success: true,
      message: "Helper charges fetched successfully",
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch helper charges" : error.message
    });
  }
};

export const createHelperCharge = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const { month, year, totalAmount, notes } = req.body;

    if (!month || !year || !totalAmount) {
      return res.status(400).json({
        success: false,
        message: "month, year and totalAmount are required"
      });
    }

    const activeMembersCount = await prisma.user.count({
      where: {
        hostelId,
        role: "MEMBER",
        status: "ACTIVE"
      }
    });

    const perMemberAmount =
      activeMembersCount > 0 ? Number(totalAmount) / activeMembersCount : 0;

    const data = await prisma.helperCharge.create({
      data: {
        month: Number(month),
        year: Number(year),
        hostelId,
        totalAmount: Number(totalAmount),
        perMemberAmount,
        notes: notes || null,
        createdBy: req.user.id
      }
    });

    res.status(201).json({
      success: true,
      message: "Helper charge created successfully",
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to create helper charge" : error.message
    });
  }
};

export const updateHelperCharge = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const id = Number(req.params.id);
    const { totalAmount, notes } = req.body;

    const existing = await prisma.helperCharge.findFirst({
      where: { id, hostelId }
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Helper charge not found"
      });
    }

    const activeMembersCount = await prisma.user.count({
      where: {
        hostelId,
        role: "MEMBER",
        status: "ACTIVE"
      }
    });

    const newTotal = totalAmount !== undefined ? Number(totalAmount) : existing.totalAmount;
    const perMemberAmount =
      activeMembersCount > 0 ? newTotal / activeMembersCount : 0;

    const data = await prisma.helperCharge.update({
      where: { id },
      data: {
        totalAmount: newTotal,
        perMemberAmount,
        notes: notes ?? existing.notes
      }
    });

    res.json({
      success: true,
      message: "Helper charge updated successfully",
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to update helper charge" : error.message
    });
  }
};