-- Tofu: a copy of prisma/migrations/18_add_performance/migration.sql, applied by scripts/tofu-migrate.js during the build
-- (see TOFU.md). Changes from upstream, if any, are marked "Tofu:" below.

-- AlterTable
ALTER TABLE "website_event" ADD COLUMN     "cls" DECIMAL(10,4),
ADD COLUMN     "fcp" DECIMAL(10,1),
ADD COLUMN     "inp" DECIMAL(10,1),
ADD COLUMN     "lcp" DECIMAL(10,1),
ADD COLUMN     "ttfb" DECIMAL(10,1);
