import express from "express";
import {
  getMembers,
  createMember,
  getMemberById,
  updateMember,
  deleteMember
} from "../controllers/member.controller.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.get("/", protect, allowRoles("ADMIN"), getMembers);
router.post("/", protect, allowRoles("ADMIN"), createMember);
router.get("/:id", protect, allowRoles("ADMIN"), getMemberById);
router.put("/:id", protect, allowRoles("ADMIN"), updateMember);
router.delete("/:id", protect, allowRoles("ADMIN"), deleteMember);

export default router;