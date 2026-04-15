import 'dotenv/config';
import { generateMonthlyBillsService } from './src/services/billing.service.js';

async function regenerateBills() {
  try {
    // Regenerate bills for April 2026 (month 4)
    const result = await generateMonthlyBillsService(
      4,      // April
      2026,   // 2026
      null,   // all members
      1       // hostelId 1
    );

    console.log('\n✓ Bills regenerated for April 2026');
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('Error regenerating bills:', error.message);
    process.exit(1);
  }
}

regenerateBills();
