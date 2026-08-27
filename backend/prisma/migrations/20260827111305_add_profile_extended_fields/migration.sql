-- AlterTable
ALTER TABLE "user_profiles" ADD COLUMN     "certifications" JSONB NOT NULL DEFAULT '[]',
ADD COLUMN     "education" JSONB NOT NULL DEFAULT '[]',
ADD COLUMN     "projects" JSONB NOT NULL DEFAULT '[]',
ADD COLUMN     "skills" TEXT[] DEFAULT ARRAY[]::TEXT[];
