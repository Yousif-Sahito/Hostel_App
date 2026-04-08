import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import dotenv from "dotenv";

import authRoutes from "./src/routes/auth.routes.js";
import memberRoutes from "./src/routes/member.routes.js";
import roomRoutes from "./src/routes/room.routes.js";
import menuRoutes from "./src/routes/menu.routes.js";
import mealRoutes from "./src/routes/meal.routes.js";
import billRoutes from "./src/routes/bill.routes.js";
import paymentRoutes from "./src/routes/payment.routes.js";
import messOffRoutes from "./src/routes/messoff.routes.js";
import helperChargeRoutes from "./src/routes/helpercharge.routes.js";
import attendanceRoutes from "./src/routes/attendance.routes.js";
import settingsRoutes from "./src/routes/settings.routes.js";
import dashboardRoutes from "./src/routes/dashboard.routes.js";
import { notFoundHandler, errorHandler } from "./src/middleware/error.middleware.js";
import { connectDatabase } from "./src/config/database.js";
import scheduleUnpaidBillNotifications from "./src/config/scheduler.js";

dotenv.config();

const app = express(); // ✅ FIRST create app

// Security middleware
app.use(helmet());

// Logging middleware
app.use(morgan("combined"));

// CORS and body parsing
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Hostel Mess Backend is running",
  });
});

app.use("/api/auth", authRoutes);
app.use("/api/members", memberRoutes);
app.use("/api/rooms", roomRoutes);
app.use("/api/menu", menuRoutes);
app.use("/api/meals", mealRoutes);
app.use("/api/bills", billRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/messoff", messOffRoutes);
app.use("/api/helpercharges", helperChargeRoutes);
app.use("/api/attendance", attendanceRoutes);
app.use("/api/settings", settingsRoutes);
app.use("/api/dashboard", dashboardRoutes); // ✅ AFTER app is created

// Error handling middleware (must be after all routes)
app.use(notFoundHandler);
app.use(errorHandler);

// Initialize database and start server
const startServer = async () => {
  try {
    // Connect to database
    await connectDatabase();

    // Initialize scheduled jobs
    scheduleUnpaidBillNotifications();

    const PORT = process.env.PORT || 5000;

    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error("Failed to start server:", error.message);
    process.exit(1);
  }
};

startServer();