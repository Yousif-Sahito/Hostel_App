import { loginUser, changeUserPassword } from "../services/auth.service.js";
import { sendSuccess, sendError } from "../utils/response.js";
import { prisma } from "../config/prisma.js";

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
    return sendError(res, error.message, 401);
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
    return sendError(res, error.message, 400);
  }
};

export const logout = async (req, res) => {
  return sendSuccess(res, "Logout successful");
};

export const updateFCMToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;

    if (!fcmToken || typeof fcmToken !== "string" || fcmToken.trim().length === 0) {
      return sendError(res, "Valid FCM token is required", 400);
    }

    if (!req.user || !req.user.id) {
      return sendError(res, "User authentication failed", 401);
    }

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: { fcmToken: fcmToken.trim() },
      select: { id: true, fullName: true, email: true, fcmToken: true },
    });

    return sendSuccess(res, "FCM token updated successfully", user, 200);
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};