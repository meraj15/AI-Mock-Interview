// Creates a test user with known credentials for development.
// Run: node create_test_user.js
// Then login with: vishwas@test.com / Test1234!

const { PrismaClient } = require('@prisma/client');
const argon2 = require('argon2');

const prisma = new PrismaClient();

const TEST_EMAIL    = 'vishwas@test.com';
const TEST_PASSWORD = 'Test1234!';

async function main() {
  const existing = await prisma.user.findUnique({ where: { email: TEST_EMAIL } });
  if (existing) {
    console.log(`User already exists: ${TEST_EMAIL}`);
    console.log(`Password: ${TEST_PASSWORD}`);
    return;
  }

  const hash = await argon2.hash(TEST_PASSWORD);
  const user = await prisma.user.create({
    data: {
      email: TEST_EMAIL,
      passwordHash: hash,
      isVerified: true,
      isActive: true,
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
