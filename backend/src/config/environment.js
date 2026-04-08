import dotenv from "dotenv";

dotenv.config();

// Validate required environment variables
const requiredEnvVars = ["DATABASE_URL", "JWT_SECRET"];
const missingEnvVars = requiredEnvVars.filter((envVar) => !process.env[envVar]);

if (missingEnvVars.length > 0 && process.env.NODE_ENV === "production") {
  throw new Error(`Missing required environment variables: ${missingEnvVars.join(", ")}`);
}

export const env = {
  PORT: process.env.PORT || 5000,
  NODE_ENV: process.env.NODE_ENV || "development",
  JWT_SECRET: process.env.JWT_SECRET,
  ADMIN_EMAIL: process.env.ADMIN_EMAIL || "admin@hostel.com",
  ADMIN_PASSWORD: process.env.ADMIN_PASSWORD,
  DATABASE_URL: process.env.DATABASE_URL,
  FIREBASE_SERVICE_ACCOUNT_KEY: process.env.FIREBASE_SERVICE_ACCOUNT_KEY
};

// Warn about insecure defaults in development
if (process.env.NODE_ENV !== "production") {
  if (!process.env.JWT_SECRET) {
    console.warn(
      "⚠️  WARNING: JWT_SECRET is not set. Using insecure default. Set JWT_SECRET in .env for production."
    );
    env.JWT_SECRET = "super_secret_jwt_key_change_this";
  }
  if (!process.env.ADMIN_PASSWORD) {
    console.warn(
      "⚠️  WARNING: ADMIN_PASSWORD not set. Using default 'admin123'. Change it in .env"
    );
    env.ADMIN_PASSWORD = "admin123";
  }
}