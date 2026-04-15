import nodemailer from "nodemailer";
import { env } from "./environment.js";

let transporter = null;

const canUseSmtp =
  Boolean(env.SMTP_HOST) &&
  Boolean(env.SMTP_PORT) &&
  Boolean(env.SMTP_USER) &&
  Boolean(env.SMTP_PASS);

if (canUseSmtp) {
  transporter = nodemailer.createTransport({
    host: env.SMTP_HOST,
    port: Number(env.SMTP_PORT),
    secure: Number(env.SMTP_PORT) === 465,
    auth: {
      user: env.SMTP_USER,
      pass: env.SMTP_PASS
    }
  });
}

export const sendMail = async ({ to, subject, text, html }) => {
  if (!to || !subject) {
    throw new Error("Email recipient and subject are required");
  }

  if (!transporter) {
    console.warn(
      `[MAILER] SMTP not configured. Email to ${to} not sent.\nSubject: ${subject}\n${text || ""}`
    );
    return;
  }

  await transporter.sendMail({
    from: env.SMTP_FROM || env.SMTP_USER,
    to,
    subject,
    text,
    html
  });
};

export const sendPasswordResetEmail = async ({ to, fullName, resetUrl, expiresMinutes }) => {
  const safeName = fullName || "User";
  const subject = "Reset your Hostel Mess password";
  const text = [
    `Hello ${safeName},`,
    "",
    "We received a request to reset your password.",
    `Use the link below to set a new password (valid for ${expiresMinutes} minutes):`,
    resetUrl,
    "",
    "If you did not request this, you can ignore this email."
  ].join("\n");

  const html = `
    <p>Hello ${safeName},</p>
    <p>We received a request to reset your password.</p>
    <p>
      Click here to set a new password (valid for ${expiresMinutes} minutes):<br />
      <a href="${resetUrl}">${resetUrl}</a>
    </p>
    <p>If you did not request this, you can ignore this email.</p>
  `;

  await sendMail({ to, subject, text, html });
};

export const sendEmailVerificationEmail = async ({ to, fullName, verifyUrl, expiresMinutes }) => {
  const safeName = fullName || "User";
  const subject = "Verify your Hostel Mess account email";
  const text = [
    `Hello ${safeName},`,
    "",
    "Please verify your email to activate your account.",
    `Use the link below (valid for ${expiresMinutes} minutes):`,
    verifyUrl,
    "",
    "If you did not create this account, you can ignore this email."
  ].join("\n");

  const html = `
    <p>Hello ${safeName},</p>
    <p>Please verify your email to activate your account.</p>
    <p>
      Click here to verify your email (valid for ${expiresMinutes} minutes):<br />
      <a href="${verifyUrl}">${verifyUrl}</a>
    </p>
    <p>If you did not create this account, you can ignore this email.</p>
  `;

  await sendMail({ to, subject, text, html });
};
