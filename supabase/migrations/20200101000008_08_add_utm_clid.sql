-- Tofu: a copy of prisma/migrations/08_add_utm_clid/migration.sql. It is applied once, in file-name order; TOFU.md
-- (*Schema*) says what applies it. Changes from upstream, if any, are marked "Tofu:" below.

-- AlterTable
ALTER TABLE "website_event" 
ADD COLUMN     "fbclid" VARCHAR(255),
ADD COLUMN     "gclid" VARCHAR(255),
ADD COLUMN     "li_fat_id" VARCHAR(255),
ADD COLUMN     "msclkid" VARCHAR(255),
ADD COLUMN     "ttclid" VARCHAR(255),
ADD COLUMN     "twclid" VARCHAR(255),
ADD COLUMN     "utm_campaign" VARCHAR(255),
ADD COLUMN     "utm_content" VARCHAR(255),
ADD COLUMN     "utm_medium" VARCHAR(255),
ADD COLUMN     "utm_source" VARCHAR(255),
ADD COLUMN     "utm_term" VARCHAR(255);
