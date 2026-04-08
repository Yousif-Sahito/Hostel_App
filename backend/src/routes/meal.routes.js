import express from "express";
import {
  getMeals,
  recordMeal,
  bulkRecordMeals,
  getMemberMeals,
  updateMeal,
  deleteMeal
} from "../controllers/meal.controller.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.get("/", protect, allowRoles("ADMIN"), getMeals);
router.post("/", protect, allowRoles("ADMIN"), recordMeal);
router.post("/bulk", protect, allowRoles("ADMIN"), bulkRecordMeals);
router.get("/member/:id", protect, getMemberMeals);
router.put("/:id", protect, allowRoles("ADMIN"), updateMeal);
router.delete("/:id", protect, allowRoles("ADMIN"), deleteMeal);

export default router;