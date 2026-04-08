import { prisma } from "../config/prisma.js";
import { sendMessOffNotification } from "../services/notification.service.js";

export const getMessOffList = async (req, res) => {
  try {
    const data = await prisma.messOffPeriod.findMany({
      include: {
        user: true,
        creator: true
      },
      orderBy: {
        id: "desc"
      }
    });

    res.json({
      success: true,
      message: "Mess off periods fetched successfully",
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const createMessOff = async (req, res) => {
  try {
    const { userId, fromDate, toDate, reason } = req.body;

    if (!userId || !fromDate || !toDate) {
      return res.status(400).json({
        success: false,
        message: "userId, fromDate and toDate are required"
      });
    }

    const user = await prisma.user.findUnique({
      where: { id: Number(userId) },
      select: { id: true, fullName: true }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    const data = await prisma.messOffPeriod.create({
      data: {
        userId: Number(userId),
        fromDate: new Date(fromDate),
        toDate: new Date(toDate),
        reason: reason || null,
        status: "ACTIVE",
        createdBy: req.user.id
      }
    });

    // Send notification to admin
    await sendMessOffNotification(user.id, user.fullName, "ACTIVE");

    res.status(201).json({
      success: true,
      message: "Mess off period created successfully",
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const updateMessOff = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { fromDate, toDate, reason, status } = req.body;

    const validStatuses = ["ACTIVE", "CANCELLED", "COMPLETED"];

    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid status. Use ACTIVE, CANCELLED, or COMPLETED"
      });
    }

    const existing = await prisma.messOffPeriod.findUnique({
      where: { id },
      include: {
        user: {
          select: { id: true, fullName: true }
        }
      }
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Mess off period not found"
      });
    }

    const data = await prisma.messOffPeriod.update({
      where: { id },
      data: {
        fromDate: fromDate ? new Date(fromDate) : existing.fromDate,
        toDate: toDate ? new Date(toDate) : existing.toDate,
        reason: reason ?? existing.reason,
        status: status ?? existing.status
      }
    });

    // Send notification if status is being changed and new status is CANCELLED
    if (status && status !== existing.status && status === "CANCELLED") {
      await sendMessOffNotification(existing.user.id, existing.user.fullName, "CANCELLED");
    }

    res.json({
      success: true,
      message: "Mess off period updated successfully",
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getMessOffByMember = async (req, res) => {
  try {
    const userId = Number(req.params.id);
    const data = await prisma.messOffPeriod.findMany({
      where: { userId },
      include: {
        user: true,
        creator: true
      },
      orderBy: {
        id: "desc"
      }
    });

    res.json({
      success: true,
      message: "Mess off periods fetched successfully",
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const deleteMessOff = async (req, res) => {
  try {
    const id = Number(req.params.id);
    
    await prisma.messOffPeriod.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: "Mess off period deleted successfully"
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getTomorrowMessOffList = async (req, res) => {
  try {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);

    const data = await prisma.messOffPeriod.findMany({
      where: {
        status: "ACTIVE",
        fromDate: { lte: tomorrow },
        toDate: { gte: tomorrow }
      },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            cmsId: true,
            phone: true
          }
        }
      }
    });

    res.json({
      success: true,
      message: "Tomorrow's mess off list fetched successfully",
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const toggleMessStatus = async (req, res) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    
    // Set 1 PM deadline for today in local time
    // Note: The system time provided in metadata is 2026-04-03T15:03:45+05:00
    // We should use that logic
    const deadline = new Date();
    deadline.setHours(13, 0, 0, 0);

    if (now > deadline) {
      return res.status(400).json({
        success: false,
        message: "Mess off toggle is only allowed before 1 PM for the next day."
      });
    }

    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);

    const existing = await prisma.messOffPeriod.findFirst({
      where: {
        userId,
        status: "ACTIVE",
        fromDate: { lte: tomorrow },
        toDate: { gte: tomorrow }
      }
    });

    if (existing) {
      // Toggle OFF -> Cancel
      await prisma.messOffPeriod.update({
        where: { id: existing.id },
        data: { status: "CANCELLED" }
      });

      res.json({
        success: true,
        message: "Mess status turned ON for tomorrow",
        isOff: false
      });
    } else {
      // Toggle ON -> Create for tomorrow
      await prisma.messOffPeriod.create({
        data: {
          userId,
          fromDate: tomorrow,
          toDate: tomorrow,
          reason: "Self Toggled",
          status: "ACTIVE",
          createdBy: userId
        }
      });

      res.json({
        success: true,
        message: "Mess status turned OFF for tomorrow",
        isOff: true
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};