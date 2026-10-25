-- Tofu: a copy of prisma/migrations/25_add_annotation/migration.sql, applied by scripts/tofu-migrate.js during the build
-- (see TOFU.md). Changes from upstream, if any, are marked "Tofu:" below.

-- CreateTable
CREATE TABLE "annotation" (
    "annotation_id" UUID NOT NULL,
    "website_id" UUID NOT NULL,
    "user_id" UUID,
    "date" TIMESTAMPTZ(6) NOT NULL,
    "all_day" BOOLEAN NOT NULL DEFAULT true,
    "note" VARCHAR(500) NOT NULL,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "annotation_pkey" PRIMARY KEY ("annotation_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "annotation_annotation_id_key" ON "annotation"("annotation_id");

-- CreateIndex
CREATE INDEX "annotation_website_id_date_idx" ON "annotation"("website_id", "date");

-- Tofu: row-level security on for every table this file creates. The app reads and writes them over its own
-- connection, which these rules do not limit; the database's public Data API gets nothing from them.
ALTER TABLE "annotation" ENABLE ROW LEVEL SECURITY;
