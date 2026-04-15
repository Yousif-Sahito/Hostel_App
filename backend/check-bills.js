import 'dotenv/config';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkData() {
  try {
    // Check bills
    const bills = await prisma.bill.findMany({
      include: { user: { select: { id: true, fullName: true } } },
      orderBy: [{ year: 'desc' }, { month: 'desc' }, { id: 'desc' }],
      take: 10
    });
    
    console.log('\n=== BILLS ===');
    console.log(JSON.stringify(bills.map(b => ({
      id: b.id,
      userId: b.userId,
      userName: b.user?.fullName,
      month: b.month,
      year: b.year,
      breakfastUnits: b.breakfastUnits,
      lunchUnits: b.lunchUnits,
      dinnerUnits: b.dinnerUnits,
      guestUnits: b.guestUnits,
      helperCharge: b.helperCharge,
      extraCharges: b.extraCharges,
      totalAmount: b.totalAmount,
      paidAmount: b.paidAmount,
      dueAmount: b.dueAmount,
      paymentStatus: b.paymentStatus
    })), null, 2));

    // Check meal entries
    const meals = await prisma.mealEntry.findMany({
      orderBy: { mealDate: 'desc' },
      take: 20
    });

    console.log('\n=== MEAL ENTRIES ===');
    console.log(`Total meals: ${meals.length}`);
    console.log(JSON.stringify(meals.map(m => ({
      id: m.id,
      userId: m.userId,
      mealDate: m.mealDate.toISOString(),
      breakfastTaken: m.breakfastTaken,
      lunchTaken: m.lunchTaken,
      dinnerTaken: m.dinnerTaken,
      guestCount: m.guestCount
    })), null, 2));

    // Check settings
    const settings = await prisma.hostelSetting.findMany();
    console.log('\n=== SETTINGS ===');
    console.log(JSON.stringify(settings, null, 2));

    // Check users
    const users = await prisma.user.findMany({
      where: { role: 'MEMBER' },
      take: 5
    });
    console.log('\n=== MEMBERS ===');
    console.log(JSON.stringify(users.map(u => ({
      id: u.id,
      fullName: u.fullName,
      mealUnitEnabled: u.mealUnitEnabled,
      advanceBalance: u.advanceBalance
    })), null, 2));

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkData();
