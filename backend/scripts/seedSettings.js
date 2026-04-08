import { prisma } from "../src/config/prisma.js";

const seedSettings = async () => {
  try {
    const existingSettings = await prisma.hostelSetting.findFirst();

    if (existingSettings) {
      console.log("Settings already exist");
      process.exit(0);
    }

    const settings = await prisma.hostelSetting.create({
      data: {
        hostelName: "Hostel Mess",
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
