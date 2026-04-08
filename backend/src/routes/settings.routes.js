import express from "express";
import { getSettings, createSettings, updateSettings } from "../controllers/settings.controller.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.get("/", protect, getSettings);
router.post("/", protect, allowRoles("ADMIN"), createSettings);
router.put("/", protect, allowRoles("ADMIN"), updateSettings);

export default router;