import { prisma } from "../src/config/prisma.js";

const columns = [
  ["passwordResetTokenHash", "VARCHAR(191) NULL"],
  ["passwordResetExpiresAt", "DATETIME(3) NULL"],
  ["passwordResetUsedAt", "DATETIME(3) NULL"],
  ["emailVerificationTokenHash", "VARCHAR(191) NULL"],
  ["emailVerificationExpiresAt", "DATETIME(3) NULL"],
  ["emailVerifiedAt", "DATETIME(3) NULL"],
  ["tokenVersion", "INT NOT NULL DEFAULT 0"]
];

const run = async () => {
  try {
    for (const [name, type] of columns) {
      try {
        await prisma.$executeRawUnsafe(
          `ALTER TABLE \`User\` ADD COLUMN \`${name}\` ${type}`
        );
        console.log(`Added ${name}`);
      } catch (error) {
        const message = String(error?.message || "");
        if (message.includes("Duplicate column name")) {
          console.log(`Exists ${name}`);
          continue;
        }
        throw error;
      }
    }
  } finally {
    await prisma.$disconnect();
  }
};

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
