import { prisma } from "./src/config/prisma.js";

async function cleanDatabase() {
  try {
    console.log("🗑️  Starting complete database cleanup...\n");

    // Define the order of deletion (respect foreign key constraints)
    const tables = [
      "deviceToken",
      "notification",
      "attendance",
      "messOffPeriod",
      "helperCharge",
      "bill",
      "weeklyMenuItem",
      "weeklyMenu",
      "room",
      "user",
      "hostelSetting",
      "hostel"
    ];

    let totalDeleted = 0;

    for (const table of tables) {
      try {
        const result = await prisma[table].deleteMany({});
        if (result.count > 0) {
          console.log(`✅ ${table}: Deleted ${result.count} records`);
          totalDeleted += result.count;
        }
      } catch (error) {
        // Table might not exist or might have different name, skip it
        console.log(`⏭️  ${table}: Skipped (${error.message.split("\n")[0]})`);
      }
    }

    console.log(`\n✅ Total records deleted: ${totalDeleted}`);
    console.log("✅ Database cleanup complete!");
  } catch (error) {
    console.error("❌ Cleanup failed:", error.message);
  } finally {
    await prisma.$disconnect();
  }
}

cleanDatabase();
