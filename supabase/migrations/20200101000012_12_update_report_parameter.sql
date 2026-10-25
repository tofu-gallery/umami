-- Tofu: a copy of prisma/migrations/12_update_report_parameter/migration.sql. It is applied once, in file-name order; TOFU.md
-- (*Schema*) says what applies it. Changes from upstream, if any, are marked "Tofu:" below.

-- AlterTable
ALTER TABLE "report"
ALTER COLUMN "parameters" SET DATA TYPE JSONB USING parameters::JSONB;
