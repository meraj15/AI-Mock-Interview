-- AlterTable
ALTER TABLE "plans" ADD COLUMN     "tier" TEXT NOT NULL DEFAULT 'PRO';

-- CreateTable
CREATE TABLE "user_usage_quotas" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "periodKey" TEXT NOT NULL,
    "interviewsUsed" INTEGER NOT NULL DEFAULT 0,
    "resumeScansUsed" INTEGER NOT NULL DEFAULT 0,
    "voiceSecondsUsed" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_usage_quotas_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "user_usage_quotas_userId_idx" ON "user_usage_quotas"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "user_usage_quotas_userId_periodKey_key" ON "user_usage_quotas"("userId", "periodKey");

-- AddForeignKey
ALTER TABLE "user_usage_quotas" ADD CONSTRAINT "user_usage_quotas_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
