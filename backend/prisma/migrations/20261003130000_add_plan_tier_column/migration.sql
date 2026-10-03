-- Migration: add_plan_tier_column
-- The `tier` column on the `plans` table exists in schema.prisma but was
-- not included in the original subscription migration SQL. This migration
-- adds it safely with a default so no existing row is broken.

ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "tier" TEXT NOT NULL DEFAULT 'PRO';
