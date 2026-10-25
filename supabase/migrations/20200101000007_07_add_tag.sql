-- Tofu: a copy of prisma/migrations/07_add_tag/migration.sql. It is applied once, in file-name order; TOFU.md
-- (*Schema*) says what applies it. Changes from upstream, if any, are marked "Tofu:" below.

-- AlterTable
ALTER TABLE "website_event" ADD COLUMN     "tag" VARCHAR(50);

-- CreateIndex
CREATE INDEX "website_event_website_id_created_at_tag_idx" ON "website_event"("website_id", "created_at", "tag");
