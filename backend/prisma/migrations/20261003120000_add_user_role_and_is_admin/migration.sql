-- Migration: add_user_role_and_is_admin
-- Adds the `role` and `isAdmin` columns to the `users` table.
-- These fields exist in schema.prisma but were never added via a migration,
-- causing PrismaClientKnownRequestError P2022 on every query touching the users table.

-- AddColumn: isAdmin (default false — no existing user is an admin)
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "isAdmin" BOOLEAN NOT NULL DEFAULT false;

-- AddColumn: role (default 'USER' — safe for all existing users)
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "role" TEXT NOT NULL DEFAULT 'USER';

-- AddColumn: emailVerifiedAt (nullable — only set when a user verifies their email)
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "emailVerifiedAt" TIMESTAMP(3);

-- CreateIndex for role (used for admin queries)
CREATE INDEX IF NOT EXISTS "users_role_idx" ON "users"("role");

-- CreateIndex for createdAt
CREATE INDEX IF NOT EXISTS "users_createdAt_idx" ON "users"("createdAt");
