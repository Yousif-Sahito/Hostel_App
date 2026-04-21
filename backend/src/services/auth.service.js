import bcrypt from "bcrypt";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import { prisma } from "../config/prisma.js";
import { env } from "../config/environment.js";
import { sendPasswordResetEmail, sendEmailVerificationEmail } from "../config/mailer.js";

const PASSWORD_RESET_EXPIRES_MINUTES = 15;
const EMAIL_VERIFY_EXPIRES_MINUTES = 30;

const signAccessToken = (user) => {
  if (!env.JWT_SECRET) {
    throw new Error("JWT_SECRET is not configured");
  }

  return jwt.sign(
    {
      id: user.id,
      role: user.role,
      hostelId: user.hostelId,
      tokenVersion: user.tokenVersion
    },
    env.JWT_SECRET,
    { expiresIn: "7d" }
  );
};

const validatePasswordStrength = (password) => {
  if (!password || password.length < 8) {
    throw new Error("Password must be at least 8 characters long");
  }
};

const validateEmail = (email) => {
  const normalizedEmail = email.trim().toLowerCase();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(normalizedEmail)) {
    throw new Error("Please enter a valid email address");
  }
  return normalizedEmail;
};

const createEmailVerificationToken = () => {
  const plainToken = crypto.randomBytes(32).toString("hex");
  const tokenHash = crypto.createHash("sha256").update(plainToken).digest("hex");
  const expiresAt = new Date(Date.now() + EMAIL_VERIFY_EXPIRES_MINUTES * 60 * 1000);
  return { plainToken, tokenHash, expiresAt };
};

export const loginUser = async ({ email, password, cmsId }) => {
  if ((!email && !cmsId) || !password) {
    throw new Error("Email or CMS ID and password are required");
  }

  let user = null;

  if (email) {
    const normalizedEmail = email.trim().toLowerCase();
    user = await prisma.user.findFirst({
      where: { email: normalizedEmail }
    });
  } else if (cmsId) {
    user = await prisma.user.findFirst({
      where: { cmsId }
    });
  }

  if (!user) {
    throw new Error("Invalid credentials");
  }

  if (user.status !== "ACTIVE") {
    throw new Error("Account is not active. Please verify your email first.");
  }

  const isPasswordMatched = await bcrypt.compare(password, user.passwordHash);

  if (!isPasswordMatched) {
    throw new Error("Invalid credentials");
  }

  const token = signAccessToken(user);

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
  validatePasswordStrength(newPassword);

  const hashedPassword = await bcrypt.hash(newPassword, 10);

  await prisma.user.update({
    where: { id: userId },
    data: {
      passwordHash: hashedPassword,
      tokenVersion: {
        increment: 1
      }
    }
  });

  return true;
};

export const requestPasswordReset = async (email) => {
  if (!email) {
    throw new Error("Email is required");
  }

  const normalizedEmail = email.trim().toLowerCase();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(normalizedEmail)) {
    throw new Error("Please enter a valid email address");
  }

  const user = await prisma.user.findFirst({
    where: {
      email: normalizedEmail,
      status: "ACTIVE"
    },
    select: {
      id: true,
      fullName: true,
      email: true
    }
  });

  // Do not reveal whether the email exists
  if (!user) {
    return true;
  }

  const plainToken = crypto.randomBytes(32).toString("hex");
  const tokenHash = crypto.createHash("sha256").update(plainToken).digest("hex");
  const expiresAt = new Date(Date.now() + PASSWORD_RESET_EXPIRES_MINUTES * 60 * 1000);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      passwordResetTokenHash: tokenHash,
      passwordResetExpiresAt: expiresAt,
      passwordResetUsedAt: null
    }
  });

  const resetUrl = `${env.FRONTEND_URL}/reset-password?token=${plainToken}`;
  await sendPasswordResetEmail({
    to: user.email,
    fullName: user.fullName,
    resetUrl,
    expiresMinutes: PASSWORD_RESET_EXPIRES_MINUTES
  });

  return true;
};

export const generatePasswordResetLinkForDev = async (email) => {
  if (!email) {
    throw new Error("Email is required");
  }

  const normalizedEmail = validateEmail(email);
  const user = await prisma.user.findFirst({
    where: {
      email: normalizedEmail,
      status: "ACTIVE"
    },
    select: {
      id: true
    }
  });

  if (!user) {
    return null;
  }

  const plainToken = crypto.randomBytes(32).toString("hex");
  const tokenHash = crypto.createHash("sha256").update(plainToken).digest("hex");
  const expiresAt = new Date(Date.now() + PASSWORD_RESET_EXPIRES_MINUTES * 60 * 1000);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      passwordResetTokenHash: tokenHash,
      passwordResetExpiresAt: expiresAt,
      passwordResetUsedAt: null
    }
  });

  return `${env.FRONTEND_URL}/reset-password?token=${plainToken}`;
};

export const resetPasswordWithToken = async ({ token, newPassword }) => {
  if (!token) {
    throw new Error("Reset token is required");
  }

  validatePasswordStrength(newPassword);

  const tokenHash = crypto.createHash("sha256").update(token.trim()).digest("hex");

  const user = await prisma.user.findFirst({
    where: {
      passwordResetTokenHash: tokenHash,
      passwordResetExpiresAt: {
        gt: new Date()
      },
      passwordResetUsedAt: null
    },
    select: {
      id: true
    }
  });

  if (!user) {
    throw new Error("Reset link is invalid or has expired");
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      passwordHash: hashedPassword,
      passwordResetUsedAt: new Date(),
      passwordResetTokenHash: null,
      passwordResetExpiresAt: null,
      tokenVersion: {
        increment: 1
      }
    }
  });

  return true;
};

export const registerUser = async ({ fullName, email, phone, password, hostelName, requestOrigin }) => {
  if (!fullName || !email || !password || !hostelName) {
    throw new Error("Full name, email, password and hostel name are required");
  }

  const userRole = "ADMIN";

  validatePasswordStrength(password);

  const normalizedEmail = validateEmail(email);

  const normalizedHostelName = hostelName.trim().toLowerCase().replace(/\s+/g, " ");

  const existingHostel = await prisma.hostel.findUnique({
    where: { normalizedName: normalizedHostelName }
  });

  if (existingHostel) {
    throw new Error("Hostel already exists");
  }

  const existingUser = await prisma.user.findFirst({
    where: { email: normalizedEmail }
  });

  if (existingUser) {
    throw new Error("User with this email already exists");
  }

  const hashedPassword = await bcrypt.hash(password, 10);
  const { plainToken: plainVerifyToken, tokenHash: verifyTokenHash, expiresAt: verifyExpiresAt } =
    createEmailVerificationToken();

  const user = await prisma.$transaction(async (tx) => {
    const hostel = await tx.hostel.create({
      data: {
        name: hostelName.trim(),
        normalizedName: normalizedHostelName
      }
    });

    await tx.hostelSetting.create({
      data: {
        hostelId: hostel.id,
        hostelName: hostel.name,
        breakfastPrice: 150,
        lunchPrice: 200,
        dinnerPrice: 200,
        guestMealPrice: 250,
        messStatus: "ON"
      }
    });

    return tx.user.create({
      data: {
        fullName,
        email: normalizedEmail,
        phone: phone || null,
        passwordHash: hashedPassword,
        role: userRole,
        status: "ACTIVE",
        hostelId: hostel.id,
        joiningDate: new Date(),
        emailVerifiedAt: new Date(),
        emailVerificationTokenHash: null,
        emailVerificationExpiresAt: null
      }
    });
  });

  const determineFrontendUrl = (originHeader) => {
    if (originHeader && (originHeader.includes("localhost") || originHeader.includes("127.0.0.1"))) {
      return originHeader;
    }
    return env.FRONTEND_URL || "http://localhost:56725/#";
  };

  // In development mode, skip email verification. In production, send verification email.
  if (env.NODE_ENV === "production") {
    const baseUrl = determineFrontendUrl(requestOrigin);
    const verifyUrl = `${baseUrl}/verify-email?token=${plainVerifyToken}`;
    await sendEmailVerificationEmail({
      to: normalizedEmail,
      fullName,
      verifyUrl,
      expiresMinutes: EMAIL_VERIFY_EXPIRES_MINUTES
    });
  }

  // Generate JWT token for the new user
  const token = signAccessToken(user);

  return {
    token,
    user: {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      hostelId: user.hostelId,
      status: user.status
    },
    message: "Account created successfully. You can now login."
  };
};

export const verifyEmailWithToken = async (token) => {
  if (!token) {
    throw new Error("Verification token is required");
  }

  const tokenHash = crypto.createHash("sha256").update(token.trim()).digest("hex");
  const user = await prisma.user.findFirst({
    where: {
      emailVerificationTokenHash: tokenHash,
      emailVerificationExpiresAt: { gt: new Date() },
      emailVerifiedAt: null
    },
    select: { id: true }
  });

  if (!user) {
    throw new Error("Verification link is invalid or expired");
  }

  await prisma.user.update({
    where: { id: user.id },
    data: {
      status: "ACTIVE",
      emailVerifiedAt: new Date(),
      emailVerificationTokenHash: null,
      emailVerificationExpiresAt: null
    }
  });
};

export const resendVerificationEmail = async (email) => {
  if (!email) {
    throw new Error("Email is required");
  }

  const normalizedEmail = validateEmail(email);
  const user = await prisma.user.findFirst({
    where: { email: normalizedEmail },
    select: {
      id: true,
      fullName: true,
      email: true,
      status: true,
      emailVerifiedAt: true
    }
  });

  // Prevent account enumeration
  if (!user) {
    return true;
  }

  // Already active/verified users do not need verification.
  if (user.status === "ACTIVE" || user.emailVerifiedAt) {
    return true;
  }

  const { plainToken, tokenHash, expiresAt } = createEmailVerificationToken();

  await prisma.user.update({
    where: { id: user.id },
    data: {
      emailVerificationTokenHash: tokenHash,
      emailVerificationExpiresAt: expiresAt
    }
  });

  const verifyUrl = `${env.FRONTEND_URL}/verify-email?token=${plainToken}`;
  await sendEmailVerificationEmail({
    to: user.email,
    fullName: user.fullName,
    verifyUrl,
    expiresMinutes: EMAIL_VERIFY_EXPIRES_MINUTES
  });

  return true;
};

export const revokeUserSessions = async (userId) => {
  if (!userId) {
    throw new Error("User ID is required");
  }

  await prisma.user.update({
    where: { id: userId },
    data: {
      tokenVersion: {
        increment: 1
      }
    }
  });

  return true;
};

export const deleteUserAccount = async (userId) => {
  if (!userId) {
    throw new Error("User ID is required");
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, email: true, hostelId: true }
  });

  if (!user) {
    throw new Error("User not found");
  }

  // Use transaction to ensure data integrity
  await prisma.$transaction(async (tx) => {
    // Delete all user-related data in proper order (respecting foreign keys)
    
    // Delete notifications for this user
    await tx.notification.deleteMany({
      where: { userId: userId }
    });

    // Delete attendance records for this user
    await tx.attendance.deleteMany({
      where: { userId: userId }
    });

    // Delete bills for this user
    await tx.bill.deleteMany({
      where: { userId: userId }
    });

    // Delete meal requests for this user
    await tx.mealRequest.deleteMany({
      where: { userId: userId }
    });

    // Delete mess off periods for this user
    await tx.messOffPeriod.deleteMany({
      where: { userId: userId }
    });

    // Delete the user itself
    await tx.user.delete({
      where: { id: userId }
    });
  });

  return {
    message: "Account deleted successfully",
    email: user.email
  };
};