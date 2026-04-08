import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function cleanup() {
  try {
    console.log('Fetching all user IDs...');
    const users = await prisma.user.findMany({ select: { id: true } });
    const userIds = users.map(u => u.id);

    console.log(`Found ${userIds.length} users.`);

    // Delete orphaned MealEntry
    const orphanedMeals = await prisma.mealEntry.deleteMany({
      where: {
        userId: { notIn: userIds }
      }
    });
    console.log(`Deleted ${orphanedMeals.count} orphaned meal entries.`);

    // Delete orphaned MessOffPeriod
    const orphanedMessOff = await prisma.messOffPeriod.deleteMany({
      where: {
        userId: { notIn: userIds }
      }
    });
    console.log(`Deleted ${orphanedMessOff.count} orphaned mess off periods.`);

    // Delete orphaned Bill
    const orphanedBills = await prisma.bill.deleteMany({
      where: {
        userId: { notIn: userIds }
      }
    });
    console.log(`Deleted ${orphanedBills.count} orphaned bills.`);

    // Delete orphaned Payment
    const orphanedPayments = await prisma.payment.deleteMany({
      where: {
        userId: { notIn: userIds }
      }
    });
    console.log(`Deleted ${orphanedPayments.count} orphaned payments.`);

    console.log('Cleanup complete!');
  } catch (error) {
    console.error('Error during cleanup:', error);
  } finally {
    await prisma.$disconnect();
  }
}

cleanup();
