import { prisma } from "../config/prisma.js";

/**
 * Mark member as in attendance (units will be disabled for that date)
 */
export const markAttendance = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const { userId, attendanceDate, isPresent, remarks } = req.body;

    if (!userId || !attendanceDate) {
      return res.status(400).json({
        success: false,
        message: "userId and attendanceDate are required",
        errors: null
      });
    }

    const user = await prisma.user.findFirst({
      where: { id: Number(userId), hostelId }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
        errors: null
      });
    }

    const date = new Date(attendanceDate);

    const existingAttendance = await prisma.attendance.findFirst({
      where: {
        hostelId,
        userId: Number(userId),
        attendanceDate: date
      }
    });

    let attendance;

    if (existingAttendance) {
      attendance = await prisma.attendance.update({
        where: { id: existingAttendance.id },
        data: {
          isPresent: isPresent !== undefined ? Boolean(isPresent) : true,
          remarks: remarks || existingAttendance.remarks
        }
      });

      return res.json({
        success: true,
        message: "Attendance updated successfully",
        data: attendance,
        errors: null
      });
    }

    attendance = await prisma.attendance.create({
      data: {
        userId: Number(userId),
        hostelId,
        attendanceDate: date,
        isPresent: isPresent !== undefined ? Boolean(isPresent) : true,
        remarks: remarks || null
      }
    });

    res.status(201).json({
      success: true,
      message: "Attendance marked successfully",
      data: attendance,
      errors: null
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to mark attendance" : error.message,
      errors: null
    });
  }
};

/**
 * Get attendance records for a member
 */
export const getMemberAttendance = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const userId = Number(req.params.id);

    const attendance = await prisma.attendance.findMany({
      where: { userId, hostelId },
      orderBy: { attendanceDate: "desc" }
    });

    res.json({
      success: true,
      message: "Attendance records fetched successfully",
      data: attendance,
      errors: null
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch attendance" : error.message,
      errors: null
    });
  }
};

/**
 * Get attendance for specific date range
 */
export const getAttendanceByDateRange = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const { fromDate, toDate } = req.query;

    if (!fromDate || !toDate) {
      return res.status(400).json({
        success: false,
        message: "fromDate and toDate query parameters are required",
        errors: null
      });
    }

    const start = new Date(fromDate);
    const end = new Date(toDate);

    const attendance = await prisma.attendance.findMany({
      where: {
        hostelId,
        attendanceDate: {
          gte: start,
          lte: end
        }
      },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true
          }
        }
      },
      orderBy: { attendanceDate: "desc" }
    });

    res.json({
      success: true,
      message: "Attendance records fetched successfully",
      data: attendance,
      errors: null
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to update attendance status" : error.message,
      errors: null
    });
  }
};

/**
 * Get all attendance records
 */
export const getAllAttendance = async (req, res) => {
  try {
    const attendance = await prisma.attendance.findMany({
      where: { hostelId: req.user.hostelId },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            cmsId: true
          }
        }
      },
      orderBy: { attendanceDate: "desc" }
    });

    res.json({
      success: true,
      message: "All attendance records fetched successfully",
      data: attendance,
      errors: null
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch member attendance" : error.message,
      errors: null
    });
  }
};

/**
 * Delete attendance record
 */
export const deleteAttendance = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const attendanceId = Number(req.params.id);

    const attendance = await prisma.attendance.findFirst({
      where: { id: attendanceId, hostelId }
    });

    if (!attendance) {
      return res.status(404).json({
        success: false,
        message: "Attendance record not found",
        errors: null
      });
    }

    const deleted = await prisma.attendance.delete({
      where: { id: attendanceId }
    });

    res.json({
      success: true,
      message: "Attendance record deleted successfully",
      data: deleted,
      errors: null
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to update meal unit exemption" : error.message,
      errors: null
    });
  }
};

/**
 * Bulk mark attendance for multiple members on a date
 */
export const bulkMarkAttendance = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const { attendanceDate, memberIds, isPresent } = req.body;

    if (!attendanceDate || !memberIds || !Array.isArray(memberIds)) {
      return res.status(400).json({
        success: false,
        message: "attendanceDate and memberIds (array) are required",
        errors: null
      });
    }

    const date = new Date(attendanceDate);

    const results = [];

    for (const userId of memberIds) {
      const existingAttendance = await prisma.attendance.findFirst({
        where: {
          hostelId,
          userId: Number(userId),
          attendanceDate: date
        }
      });

      let attendance;

      if (existingAttendance) {
        attendance = await prisma.attendance.update({
          where: { id: existingAttendance.id },
          data: {
            isPresent: isPresent !== undefined ? Boolean(isPresent) : true
          }
        });
      } else {
        attendance = await prisma.attendance.create({
          data: {
            userId: Number(userId),
            hostelId,
            attendanceDate: date,
            isPresent: isPresent !== undefined ? Boolean(isPresent) : true
          }
        });
      }

      results.push(attendance);
    }

    res.json({
      success: true,
      message: `Attendance marked for ${results.length} members`,
      data: results,
      errors: null
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch meal unit exemption stats" : error.message,
      errors: null
    });
  }
};
