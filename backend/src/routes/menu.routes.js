import express from "express";
import {
  getCurrentWeekMenu,
  createMenu,
  updateMenu
} from "../controllers/menu.controller.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.get("/current-week", protect, getCurrentWeekMenu);
router.post("/", protect, allowRoles("ADMIN"), createMenu);
router.put("/:id", protect, allowRoles("ADMIN"), updateMenu);

export default router;