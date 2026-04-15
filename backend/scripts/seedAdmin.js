import bcrypt from "bcrypt";
import { prisma } from "../src/config/prisma.js";
import { env } from "../src/config/environment.js";

const seedAdmin = async () => {
  try {
    const defaultHostelName = process.env.DEFAULT_HOSTEL_NAME || "Default Hostel";
    const normalizedName = defaultHostelName.trim().toLowerCase().replace(/\s+/g, " ");
    let hostel = await prisma.hostel.findUnique({
      where: { normalizedName }
    });
    if (!hostel) {
      hostel = await prisma.hostel.create({
        data: {
          name: defaultHostelName,
          normalizedName
        }
      });
    }

    const existingAdmin = await prisma.user.findFirst({
      where: {
        role: "ADMIN",
        hostelId: hostel.id
      }
    });

    if (existingAdmin) {
      console.log("Admin already exists");
      process.exit(0);
    }

    const hashedPassword = await bcrypt.hash(env.ADMIN_PASSWORD, 10);

    const admin = await prisma.user.create({
      data: {
        fullName: "System Admin",
        email: env.ADMIN_EMAIL,
        passwordHash: hashedPassword,
        role: "ADMIN",
        status: "ACTIVE",
        hostelId: hostel.id
      }
    });

    console.log("Admin created successfully:", admin.email);
    process.exit(0);
  } catch (error) {
    console.error("Error seeding admin:", error.message);
    process.exit(1);
  }
};

seedAdmin();