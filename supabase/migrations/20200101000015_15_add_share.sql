-- Tofu: a copy of prisma/migrations/15_add_share/migration.sql. It is applied once, in file-name order; TOFU.md
-- (*Schema*) says what applies it. Changes from upstream, if any, are marked "Tofu:" below.

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
-- connection, which these rules do not limit. Tofu opens the tables of the migration files it applies to the
-- database's Data API, so these lines, with no policy, are what keep anyone holding the database's public key from
-- every row: keep them (TOFU.md, *Schema*).
ALTER TABLE "share" ENABLE ROW LEVEL SECURITY;
