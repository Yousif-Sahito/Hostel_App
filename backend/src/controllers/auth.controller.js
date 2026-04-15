import {
  loginUser,
  changeUserPassword,
  registerUser,
  requestPasswordReset,
  generatePasswordResetLinkForDev,
  resetPasswordWithToken,
  verifyEmailWithToken,
  resendVerificationEmail,
  revokeUserSessions
} from "../services/auth.service.js";
import { sendSuccess, sendError } from "../utils/response.js";
import { prisma } from "../config/prisma.js";
import { env } from "../config/environment.js";
import { handleControllerError } from "../utils/controllerError.js";

export const register = async (req, res) => {
  try {
    const { fullName, email, phone, password, hostelName } = req.body;

    if (!fullName || !email || !password || !hostelName) {
      return sendError(
        res,
        "Full name, email, password and hostel name are required",
        400
      );
    }

    const result = await registerUser({
      fullName,
      email,
      phone,
      password,
      hostelName,
      requestOrigin: req.headers.origin
    });

    return sendSuccess(res, "Registration successful", result, 201);
  } catch (error) {
    return handleControllerError(res, error, "Registration failed.", 400);
  }
};

export const login = async (req, res) => {
  try {
    const { email, password, cmsId } = req.body;

    if ((!email && !cmsId) || !password) {
      return sendError(
        res,
        "Email/password for admin or cmsId/password for member is required",
        400
      );
    }

    const result = await loginUser({ email, password, cmsId });

    return sendSuccess(res, "Login successful", result, 200);
  } catch (error) {
    return handleControllerError(res, error, "Login failed.", 401);
  }
};

export const changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return sendError(res, "Old password and new password are required", 400);
    }

    await changeUserPassword(req.user.id, oldPassword, newPassword);

    return sendSuccess(res, "Password changed successfully");
  } catch (error) {
    return handleControllerError(res, error, "Unable to change password.", 400);
  }
};

export const logout = async (req, res) => {
  try {
    if (!req.user?.id) {
      return sendError(res, "User authentication failed", 401);
    }

    await revokeUserSessions(req.user.id);
    return sendSuccess(res, "Logout successful");
  } catch (error) {
    return handleControllerError(res, error, "Logout failed. Please try again.", 500);
  }
};

export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return sendError(res, "Email is required", 400);
    }

    await requestPasswordReset(email);

    return sendSuccess(
      res,
      "If an account with this email exists, a reset link has been sent."
    );
  } catch (error) {
    return handleControllerError(res, error, "Unable to process forgot password request.", 400);
  }
};

export const debugForgotPassword = async (req, res) => {
  try {
    if (env.NODE_ENV === "production") {
      return sendError(res, "Debug endpoint is not available in production", 403);
    }

    const { email } = req.body;
    if (!email) {
      return sendError(res, "Email is required", 400);
    }

    const resetLink = await generatePasswordResetLinkForDev(email);
    return sendSuccess(res, "Debug reset link generated", { resetLink });
  } catch (error) {
    return handleControllerError(res, error, "Unable to generate debug link.", 400);
  }
};

export const resetPassword = async (req, res) => {
  try {
    const { token, newPassword, confirmPassword } = req.body;
    if (!token || !newPassword || !confirmPassword) {
      return sendError(res, "Token, newPassword and confirmPassword are required", 400);
    }

    if (newPassword !== confirmPassword) {
      return sendError(res, "Passwords do not match", 400);
    }

    await resetPasswordWithToken({ token, newPassword });

    return sendSuccess(res, "Password reset successful. You can now log in.");
  } catch (error) {
    return handleControllerError(res, error, "Unable to reset password.", 400);
  }
};

export const verifyEmail = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return sendError(res, "Verification token is required", 400);
    }

    await verifyEmailWithToken(token);
    return sendSuccess(res, "Email verified successfully. You can now log in.");
  } catch (error) {
    return handleControllerError(res, error, "Unable to verify email.", 400);
  }
};

export const resendVerification = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return sendError(res, "Email is required", 400);
    }

    await resendVerificationEmail(email);
    return sendSuccess(
      res,
      "If an unverified account with this email exists, a verification link has been sent."
    );
  } catch (error) {
    return handleControllerError(res, error, "Unable to resend verification email.", 400);
  }
};

export const updateFCMToken = async (req, res) => {
  try {
    const { fcmToken, platform } = req.body;

    if (!fcmToken || typeof fcmToken !== "string" || fcmToken.trim().length === 0) {
      return sendError(res, "Valid FCM token is required", 400);
    }

    if (!req.user || !req.user.id) {
      return sendError(res, "User authentication failed", 401);
    }

    const normalizedToken = fcmToken.trim();

    await prisma.deviceToken.upsert({
      where: { token: normalizedToken },
      update: {
        userId: req.user.id,
        hostelId: req.user.hostelId,
        platform: platform || null,
        isActive: true,
        lastSeenAt: new Date()
      },
      create: {
        userId: req.user.id,
        hostelId: req.user.hostelId,
        token: normalizedToken,
        platform: platform || null,
        isActive: true
      }
    });

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: { fcmToken: normalizedToken },
      select: { id: true, fullName: true, email: true, fcmToken: true },
    });

    return sendSuccess(res, "FCM token updated successfully", user, 200);
  } catch (error) {
    return handleControllerError(res, error, "Unable to update FCM token.", 400);
  }
};

export const deleteAccount = async (req, res) => {
  try {
    if (!req.user || !req.user.id) {
      return sendError(res, "User authentication failed", 401);
    }

    if (!req.user.hostelId) {
      return sendError(res, "Hostel context missing for user.", 403);
    }

    if (req.user.role !== "ADMIN") {
      return sendError(res, "Access denied.", 403);
    }

    const hostelId = req.user.hostelId;
    const hostel = await prisma.hostel.findFirst({
      where: { id: hostelId },
      select: { id: true }
    });

    if (!hostel) {
      return sendError(res, "Hostel not found", 404);
    }

    // Deleting hostel will cascade-delete all tenant data via FK onDelete: Cascade.
    await prisma.hostel.delete({
      where: { id: hostelId }
    });

    return sendSuccess(res, "Account deleted successfully");
  } catch (error) {
    return handleControllerError(res, error, "Unable to delete account.", 400);
  }
};