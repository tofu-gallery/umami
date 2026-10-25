-- Tofu: a copy of prisma/migrations/10_add_distinct_id/migration.sql, applied by scripts/tofu-migrate.js during the build
-- (see TOFU.md). Changes from upstream, if any, are marked "Tofu:" below.

-- AlterTable
ALTER TABLE "session" ADD COLUMN     "distinct_id" VARCHAR(50);

-- AlterTable
ALTER TABLE "session_data" ADD COLUMN     "distinct_id" VARCHAR(50);
