import express from "express";
import {
  getAdminDashboardStats,
  getMemberDashboardStats,
} from "../controllers/dashboard.controller.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.get("/admin", protect, allowRoles("ADMIN"), getAdminDashboardStats);
router.get("/member", protect, allowRoles("MEMBER"), getMemberDashboardStats);

export default router;