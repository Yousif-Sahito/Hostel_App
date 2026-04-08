import express from "express";
import {
  getBills,
  generateBills,
  getBillsByMember,
  updateBill,
  getMyBills
} from "../controllers/bill.controller.js";

import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.get("/", protect, allowRoles("ADMIN"), getBills);
router.post("/generate", protect, allowRoles("ADMIN"), generateBills);
router.get("/my", protect, getMyBills);
router.get("/member/:id", protect, getBillsByMember);
router.put("/:id", protect, allowRoles("ADMIN"), updateBill);

export default router;