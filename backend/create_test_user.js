// Development utility: Creates or updates a local test admin user.
// Strictly forbidden in production environments.
// Run locally: node create_test_user.js

// Strict production guard — abort immediately if run in production
if (process.env.NODE_ENV === 'production' || process.env.RAILWAY_ENVIRONMENT === 'production') {
  console.error('❌ FATAL: create_test_user.js is strictly for local development and cannot run in production.');
  process.exit(1);
}

const { PrismaClient } = require('@prisma/client');
const argon2 = require('argon2');

const prisma = new PrismaClient();

const TEST_EMAIL    = process.env.DEV_TEST_USER_EMAIL || 'vishwas@test.com';
const TEST_PASSWORD = process.env.DEV_TEST_USER_PASSWORD || 'Test1234!';

async function main() {
  const existing = await prisma.user.findUnique({ where: { email: TEST_EMAIL } });
  if (existing) {
    await prisma.user.update({
      where: { id: existing.id },
      data: { role: 'ADMIN', isAdmin: true },
    });
    console.log(`User already exists: ${TEST_EMAIL}`);
    console.log(`Password: ${TEST_PASSWORD}`);
    console.log(`Updated user role to ADMIN`);
    return;
  }

  const hash = await argon2.hash(TEST_PASSWORD);
  const user = await prisma.user.create({
    data: {
      email: TEST_EMAIL,
      passwordHash: hash,
      isVerified: true,
      isActive: true,
      role: 'ADMIN',
      isAdmin: true,
    },
  });

  console.log('✅ Test user created!');
  console.log(`   Email:    ${user.email}`);
  console.log(`   Password: ${TEST_PASSWORD}`);
  console.log(`   ID:       ${user.id}`);
}

main()
  .catch(e => console.error('Error:', e.message))
  .finally(() => prisma.$disconnect());
