-- Tofu: a copy of prisma/migrations/04_team_redesign/migration.sql. It is applied once, in file-name order; TOFU.md
-- (*Schema*) says what applies it. Changes from upstream, if any, are marked "Tofu:" below.

/*
  Warnings:

  - You are about to drop the `team_website` table. If the table is not empty, all the data it contains will be lost.

*/
-- AlterTable
ALTER TABLE "team" ADD COLUMN     "deleted_at" TIMESTAMPTZ(6),
ADD COLUMN     "logo_url" VARCHAR(2183);

-- AlterTable
ALTER TABLE "user" ADD COLUMN     "display_name" VARCHAR(255),
ADD COLUMN     "logo_url" VARCHAR(2183);

-- AlterTable
ALTER TABLE "website" ADD COLUMN     "created_by" UUID,
ADD COLUMN     "team_id" UUID;

-- MigrateData
UPDATE "website" SET created_by = user_id WHERE team_id IS NULL;

-- DropTable
DROP TABLE "team_website";

-- CreateIndex
CREATE INDEX "website_team_id_idx" ON "website"("team_id");

-- CreateIndex
CREATE INDEX "website_created_by_idx" ON "website"("created_by");
