import { env } from "../config/environment.js";

export const handleControllerError = (
  res,
  error,
  fallbackMessage = "Something went wrong.",
  statusCode = 500
) => {
  const isProduction = env.NODE_ENV === "production";
  const message = isProduction
    ? statusCode >= 500
      ? fallbackMessage
      : error?.message || fallbackMessage
    : error?.message || fallbackMessage;

  if (statusCode >= 500) {
    console.error("[ControllerError]", error);
  }

  return res.status(statusCode).json({
    success: false,
    message
  });
};
