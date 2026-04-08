import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { prisma } from "../config/prisma.js";
import { env } from "../config/environment.js";

export const loginUser = async ({ email, password, cmsId }) => {
  if ((!email && !cmsId) || !password) {
    throw new Error("Email or CMS ID and password are required");
  }

  let user = null;

  if (email) {
    user = await prisma.user.findUnique({
      where: { email }
    });
  } else if (cmsId) {
    user = await prisma.user.findUnique({
      where: { cmsId }
    });
  }

  if (!user) {
    throw new Error("Invalid credentials");
  }

  if (user.status !== "ACTIVE") {
    throw new Error("User account is inactive");
  }

  const isPasswordMatched = await bcrypt.compare(password, user.passwordHash);

  if (!isPasswordMatched) {
    throw new Error("Invalid credentials");
  }

  if (!env.JWT_SECRET) {
    throw new Error("JWT_SECRET is not configured");
  }

  const token = jwt.sign(
    {
      id: user.id,
      role: user.role
    },
    env.JWT_SECRET,
    { expiresIn: "7d" }
  );

  return {
    user: {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      cmsId: user.cmsId,
      role: user.role,
      status: user.status
    },
    token
  };
};

export const changeUserPassword = async (userId, oldPassword, newPassword) => {
  if (!userId || !oldPassword || !newPassword) {
    throw new Error("User ID, old password, and new password are required");
  }

  const user = await prisma.user.findUnique({
    where: { id: userId }
  });

  if (!user) {
    throw new Error("User not found");
  }

  const isPasswordMatched = await bcrypt.compare(oldPassword, user.passwordHash);

  if (!isPasswordMatched) {
    throw new Error("Old password is incorrect");
  }

  if (oldPassword === newPassword) {
    throw new Error("New password must be different from the old password");
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);

  await prisma.user.update({
    where: { id: userId },
    data: {
      passwordHash: hashedPassword
    }
  });

  return true;
};