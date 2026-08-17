# AI Interview Coach — Backend API

Express + TypeScript + PostgreSQL + Prisma REST API powering the AI Mock Interview platform.

---

## Requirements

| Tool | Version |
|------|---------|
| Node.js | ≥ 20.x (LTS) |
| npm | ≥ 10.x |
| PostgreSQL | ≥ 15.x |

---

## Environment Setup

```bash
# 1. Copy the example env file
cp .env.example .env

# 2. Edit .env and fill in your values:
#    DATABASE_URL  — PostgreSQL connection string
#    PORT          — API port (default: 3000)
#    NODE_ENV      — development | production
#    JWT_ACCESS_SECRET  — min 32 chars
#    JWT_REFRESH_SECRET — min 32 chars
```

### DATABASE_URL format
```
postgresql://USER:PASSWORD@HOST:PORT/DATABASE?schema=public
```

Example for local development:
```
postgresql://postgres:password@localhost:5432/interview_coach?schema=public
```

---

## Installing Dependencies

```bash
npm install
```

---

## Running Migrations

```bash
# Apply all migrations to your PostgreSQL database
npm run prisma:migrate

# (Optional) Generate Prisma Client manually
npm run prisma:generate
```

---

## Starting the Development Server

```bash
npm run dev
```

The server will hot-reload on file changes via `ts-node-dev`.

---

## Building for Production

```bash
npm run build   # Compiles TypeScript → dist/
npm run start   # Runs compiled dist/server.js
```

---

## Running Tests

```bash
npm run test
```

---

## Testing the Health Endpoint

Once the server is running, verify it is healthy:

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "success": true,
  "message": "API is running",
  "timestamp": "2026-08-17T07:00:00.000Z"
}
```

---

## Project Structure

```
backend/
├── src/
│   ├── config/          # Environment config loader
│   ├── controllers/     # Route handler functions (Phase 10+)
│   ├── middleware/      # Express middleware (error handler, auth, etc.)
│   ├── routes/          # Express routers
│   ├── services/        # Business logic layer (Phase 10+)
│   ├── repositories/    # Database access via Prisma (Phase 10+)
│   ├── validators/      # Zod validation schemas (Phase 10+)
│   ├── utils/           # Logger and helpers
│   ├── types/           # Shared TypeScript interfaces
│   ├── errors/          # Custom error classes
│   ├── app.ts           # Express app factory
│   └── server.ts        # HTTP server entry point
├── prisma/
│   └── schema.prisma    # Prisma ORM schema
├── tests/               # Jest test suites (Phase 10+)
├── .env                 # Local secrets (git-ignored)
├── .env.example         # Template for env setup
├── package.json
└── tsconfig.json
```

---

## Available npm Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start dev server with hot reload |
| `npm run build` | Compile TypeScript to `dist/` |
| `npm run start` | Run compiled production server |
| `npm run test` | Run Jest test suite |
| `npm run prisma:generate` | Regenerate Prisma Client |
| `npm run prisma:migrate` | Run pending database migrations |
| `npm run prisma:studio` | Open Prisma Studio UI |
