import express from "express";
import {
  getHelperCharges,
  createHelperCharge,
  updateHelperCharge
} from "../controllers/helpercharge.controller.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.get("/", protect, allowRoles("ADMIN"), getHelperCharges);
router.post("/", protect, allowRoles("ADMIN"), createHelperCharge);
router.put("/:id", protect, allowRoles("ADMIN"), updateHelperCharge);

export default router;