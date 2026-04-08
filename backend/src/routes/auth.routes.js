import express from "express";
import { login, changePassword, logout, updateFCMToken } from "../controllers/auth.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.post("/login", login);
router.post("/change-password", protect, changePassword);
router.post("/logout", protect, logout);
router.post("/update-fcm-token", protect, updateFCMToken);

export default router;