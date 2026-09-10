-- Add the new fullName column first so existing profile data can be preserved.
ALTER TABLE "user_profiles"
ADD COLUMN "fullName" TEXT;

-- Migrate existing firstName/lastName data into fullName.
UPDATE "user_profiles"
SET "fullName" = TRIM(
  COALESCE("firstName", '') ||
  CASE
    WHEN "firstName" IS NOT NULL AND "lastName" IS NOT NULL THEN ' '
    ELSE ''
  END ||
  COALESCE("lastName", '')
);

-- Remove the old columns after their data has been migrated.
ALTER TABLE "user_profiles"
DROP COLUMN "firstName",
DROP COLUMN "lastName";