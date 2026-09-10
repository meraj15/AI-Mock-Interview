-- AlterTable
ALTER TABLE "email_verification_otps" ADD COLUMN     "fullName" TEXT,
ADD COLUMN     "passwordHash" TEXT,
ALTER COLUMN "userId" DROP NOT NULL;
