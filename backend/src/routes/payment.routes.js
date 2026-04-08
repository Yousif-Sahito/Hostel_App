import express from "express";
import {
  createPayment,
  getPaymentsByMember,
  getAllPayments
} from "../controllers/payment.controller.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.post("/", protect, allowRoles("ADMIN"), createPayment);
router.get("/", protect, allowRoles("ADMIN"), getAllPayments);
router.get("/member/:id", protect, getPaymentsByMember);

export default router;