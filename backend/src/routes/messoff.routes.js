import express from "express";
import {
  getMessOffList,
  createMessOff,
  updateMessOff,
  getMessOffByMember,
  deleteMessOff,
  toggleMessStatus,
  getTomorrowMessOffList
} from "../controllers/messoff.controller.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.get("/", protect, allowRoles("ADMIN"), getMessOffList);
router.get("/tomorrow", protect, allowRoles("ADMIN"), getTomorrowMessOffList);
router.get("/member/:id", protect, getMessOffByMember);
router.post("/", protect, allowRoles("ADMIN"), createMessOff);
router.post("/toggle", protect, toggleMessStatus);
router.put("/:id", protect, allowRoles("ADMIN"), updateMessOff);
router.delete("/:id", protect, allowRoles("ADMIN"), deleteMessOff);

export default router;