import { prisma } from "./src/config/prisma.js";

async function cleanup() {
  try {
    console.log("🧹 Cleaning up test accounts...");

    // Delete the test account
    const deletedUser = await prisma.user.deleteMany({
      where: {
        email: {
          in: ["raja@gmail.com", "test@gmail.com", "admin@test.com"]
        }
      }
    });

    console.log(`✅ Deleted ${deletedUser.count} test accounts`);

    // Delete any hostels that have no users
    const deletedHostels = await prisma.hostel.deleteMany({
      where: {
        users: {
          none: {}
        }
      }
    });

    console.log(`✅ Cleaned up ${deletedHostels.count} orphaned hostels`);
    console.log("✅ Cleanup complete!");
  } catch (error) {
    console.error("❌ Cleanup failed:", error.message);
  } finally {
    await prisma.$disconnect();
  }
}

cleanup();
