export const notFoundHandler = (req, res, next) => {
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.originalUrl}`,
    errors: null
  });
};

export const errorHandler = (err, req, res, next) => {
  console.error("Error:", err);

  const statusCode = err.status || err.statusCode || 500;
  const message = err.message || "Internal server error";

  res.status(statusCode).json({
    success: false,
    message,
    errors: process.env.NODE_ENV === "development" ? err.stack : null
  });
};