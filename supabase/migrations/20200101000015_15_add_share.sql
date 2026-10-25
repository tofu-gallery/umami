-- Tofu: a copy of prisma/migrations/15_add_share/migration.sql, applied by scripts/tofu-migrate.js during the build
-- (see TOFU.md). Changes from upstream, if any, are marked "Tofu:" below.

-- CreateTable
CREATE TABLE "share" (
    "share_id" UUID NOT NULL,
    "entity_id" UUID NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "share_type" INTEGER NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "parameters" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "share_pkey" PRIMARY KEY ("share_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "share_slug_key" ON "share"("slug");

-- CreateIndex
CREATE INDEX "share_entity_id_idx" ON "share"("entity_id");

-- MigrateData
INSERT INTO "share" (share_id, entity_id, name, share_type, slug, parameters, created_at)
SELECT gen_random_uuid(),
       website_id,
       name,
       1,
       share_id,
       '{"overview":true}'::jsonb,
       now()
FROM "website"
WHERE share_id IS NOT NULL;

-- DropIndex
DROP INDEX "website_share_id_idx";

-- DropIndex
DROP INDEX "website_share_id_key";

-- AlterTable
ALTER TABLE "website" DROP COLUMN "share_id";

-- Tofu: row-level security on for every table this file creates. The app reads and writes them over its own
-- connection, which these rules do not limit; the database's public Data API gets nothing from them.
ALTER TABLE "share" ENABLE ROW LEVEL SECURITY;
