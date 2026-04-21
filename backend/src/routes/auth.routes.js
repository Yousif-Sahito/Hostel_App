import express from "express";
import {
  login,
  register,
  changePassword,
  logout,
  updateFCMToken,
  deleteAccount,
  forgotPassword,
  debugForgotPassword,
  resetPassword,
  verifyEmail,
  resendVerification
} from "../controllers/auth.controller.js";
import { env } from "../config/environment.js";
import {
  forgotPasswordRateLimit,
  resetPasswordRateLimit,
  resendVerificationRateLimit
} from "../middleware/rateLimit.middleware.js";
import { protect } from "../middleware/auth.middleware.js";
import { allowRoles } from "../middleware/role.middleware.js";

const router = express.Router();

router.post("/login", login);
router.post("/register", register);
router.post("/forgot-password", forgotPasswordRateLimit, forgotPassword);
if (env.NODE_ENV !== "production") {
  router.post("/debug/forgot-password-link", forgotPasswordRateLimit, debugForgotPassword);
}
router.post("/reset-password", resetPasswordRateLimit, resetPassword);
router.post("/verify-email", verifyEmail);
router.post("/resend-verification", resendVerificationRateLimit, resendVerification);
router.post("/change-password", protect, changePassword);
router.post("/logout", protect, logout);
router.post("/update-fcm-token", protect, updateFCMToken);
router.delete("/delete-account", protect, deleteAccount);

export default router;