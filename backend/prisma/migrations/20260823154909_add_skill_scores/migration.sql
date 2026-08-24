-- Add skillScores JSON column to interview_sessions
ALTER TABLE "interview_sessions"
    ADD COLUMN IF NOT EXISTS "skillScores" JSONB NOT NULL DEFAULT '{}';
