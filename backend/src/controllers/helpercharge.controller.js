import { prisma } from "../config/prisma.js";

export const getHelperCharges = async (req, res) => {
  try {
    const data = await prisma.helperCharge.findMany({
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
      message: error.message
    });
  }
};

export const createHelperCharge = async (req, res) => {
  try {
    const { month, year, totalAmount, notes } = req.body;

    if (!month || !year || !totalAmount) {
      return res.status(400).json({
        success: false,
        message: "month, year and totalAmount are required"
      });
    }

    const activeMembersCount = await prisma.user.count({
      where: {
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
      message: error.message
    });
  }
};

export const updateHelperCharge = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { totalAmount, notes } = req.body;

    const existing = await prisma.helperCharge.findUnique({
      where: { id }
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Helper charge not found"
      });
    }

    const activeMembersCount = await prisma.user.count({
      where: {
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
      message: error.message
    });
  }
};