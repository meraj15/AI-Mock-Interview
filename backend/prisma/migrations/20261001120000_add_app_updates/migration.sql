-- CreateEnum
CREATE TYPE "AppPlatform" AS ENUM ('ANDROID', 'IOS', 'BOTH');

-- CreateEnum
CREATE TYPE "AppUpdateStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'DISABLED');

-- CreateTable
CREATE TABLE "app_updates" (
    "id" TEXT NOT NULL,
    "platform" "AppPlatform" NOT NULL,
    "latestVersion" TEXT NOT NULL,
    "minimumVersion" TEXT NOT NULL,
    "forceUpdate" BOOLEAN NOT NULL DEFAULT false,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "whatsNew" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "androidStoreUrl" TEXT,
    "iosStoreUrl" TEXT,
    "status" "AppUpdateStatus" NOT NULL DEFAULT 'DRAFT',
    "publishedAt" TIMESTAMP(3),
    "releaseDate" TIMESTAMP(3),
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "app_updates_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "app_updates_platform_idx" ON "app_updates"("platform");

-- CreateIndex
CREATE INDEX "app_updates_status_idx" ON "app_updates"("status");

-- CreateIndex
CREATE INDEX "app_updates_platform_status_idx" ON "app_updates"("platform", "status");

-- CreateIndex
CREATE INDEX "app_updates_createdAt_idx" ON "app_updates"("createdAt");
