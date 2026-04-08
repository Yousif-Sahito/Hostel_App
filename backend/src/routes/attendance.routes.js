import { Router } from "express";
import {
  markAttendance,
  getMemberAttendance,
  getAttendanceByDateRange,
  getAllAttendance,
  deleteAttendance,
  bulkMarkAttendance
} from "../controllers/attendance.controller.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = Router();

/**
 * @route   POST /api/attendance
 * @desc    Mark member attendance (ADMIN only)
 * @access  Private (Admin)
 */
router.post("/", protect, allowRoles("ADMIN"), markAttendance);

/**
 * @route   POST /api/attendance/bulk
 * @desc    Bulk mark attendance for multiple members (ADMIN only)
 * @access  Private (Admin)
 */
router.post("/bulk", protect, allowRoles("ADMIN"), bulkMarkAttendance);

/**
 * @route   GET /api/attendance
 * @desc    Get all attendance records (ADMIN only)
 * @access  Private (Admin)
 */
router.get("/", protect, allowRoles("ADMIN"), getAllAttendance);

/**
 * @route   GET /api/attendance/range?fromDate=XXX&toDate=XXX
 * @desc    Get attendance records by date range (ADMIN only)
 * @access  Private (Admin)
 */
router.get("/range", protect, allowRoles("ADMIN"), getAttendanceByDateRange);

/**
 * @route   GET /api/attendance/member/:id
 * @desc    Get attendance records for a specific member
 * @access  Private (Member or Admin)
 */
router.get("/member/:id", protect, getMemberAttendance);

/**
 * @route   DELETE /api/attendance/:id
 * @desc    Delete attendance record (ADMIN only)
 * @access  Private (Admin)
 */
router.delete("/:id", protect, allowRoles("ADMIN"), deleteAttendance);

export default router;
