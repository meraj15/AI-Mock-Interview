-- CreateTable: user_profiles
CREATE TABLE "user_profiles" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "firstName" TEXT,
    "lastName" TEXT,
    "phone" TEXT,
    "targetRole" TEXT,
    "experienceYears" DOUBLE PRECISION,
    "bio" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable: interview_sessions
CREATE TABLE "interview_sessions" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "difficulty" TEXT NOT NULL,
    "questionCount" INTEGER NOT NULL,
    "score" INTEGER NOT NULL,
    "hiringBand" TEXT NOT NULL,
    "summary" TEXT NOT NULL,
    "strengths" TEXT[],
    "areasToImprove" TEXT[],
    "durationSecs" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "interview_sessions_pkey" PRIMARY KEY ("id")
);

-- Unique index on user_profiles.userId (one profile per user)
CREATE UNIQUE INDEX "user_profiles_userId_key" ON "user_profiles"("userId");

-- Indexes on interview_sessions
CREATE INDEX "interview_sessions_userId_idx" ON "interview_sessions"("userId");
CREATE INDEX "interview_sessions_userId_createdAt_idx" ON "interview_sessions"("userId", "createdAt");

-- FK: user_profiles → users
ALTER TABLE "user_profiles"
    ADD CONSTRAINT "user_profiles_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- FK: interview_sessions → users
ALTER TABLE "interview_sessions"
    ADD CONSTRAINT "interview_sessions_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
