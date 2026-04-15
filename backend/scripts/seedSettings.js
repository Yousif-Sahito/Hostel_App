import { prisma } from "../src/config/prisma.js";

const seedSettings = async () => {
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
    const existingSettings = await prisma.hostelSetting.findFirst({
      where: { hostelId: hostel.id }
    });

    if (existingSettings) {
      console.log("Settings already exist");
      process.exit(0);
    }

    const settings = await prisma.hostelSetting.create({
      data: {
        hostelName: "Hostel Mess",
        hostelId: hostel.id,
        breakfastPrice: 150,
        lunchPrice: 200,
        dinnerPrice: 200,
        guestMealPrice: 250,
        messStatus: "ON"
      }
    });

    console.log("Settings created successfully:", settings);
    process.exit(0);
  } catch (error) {
    console.error("Error seeding settings:", error.message);
    process.exit(1);
  }
};

seedSettings();
