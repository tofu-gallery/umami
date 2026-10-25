-- Tofu: a copy of prisma/migrations/20_add_heatmap/migration.sql. It is applied once, in file-name order; TOFU.md
-- (*Schema*) says what applies it. Changes from upstream, if any, are marked "Tofu:" below.

ALTER TABLE "website" RENAME COLUMN "replay_enabled" TO "recorder_enabled";

UPDATE "website"
SET "replay_config" = COALESCE("replay_config", '{}'::jsonb) || '{"replayEnabled": true}'::jsonb
WHERE "recorder_enabled" = true;

-- CreateTable
CREATE TABLE "heatmap_event" (
    "heatmap_event_id" UUID NOT NULL,
    "website_id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "visit_id" UUID NOT NULL,
    "url_path" VARCHAR(500) NOT NULL,
    "event_type" INTEGER NOT NULL,
    "x" INTEGER,
    "y" INTEGER,
    "page_x" INTEGER,
    "page_y" INTEGER,
    "page_w" INTEGER,
    "viewport_w" INTEGER,
    "viewport_h" INTEGER,
    "page_h" INTEGER,
    "scroll_pct" INTEGER,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "heatmap_event_pkey" PRIMARY KEY ("heatmap_event_id")
);

-- CreateIndex
CREATE INDEX "heatmap_event_website_id_idx" ON "heatmap_event"("website_id");
CREATE INDEX "heatmap_event_visit_id_idx" ON "heatmap_event"("visit_id");
CREATE INDEX "heatmap_event_website_id_created_at_idx" ON "heatmap_event"("website_id", "created_at");
CREATE INDEX "heatmap_event_website_id_url_path_event_type_created_at_idx" ON "heatmap_event"("website_id", "url_path", "event_type", "created_at");

-- Tofu: row-level security on for every table this file creates. The app reads and writes them over its own
-- connection, which these rules do not limit. Tofu opens the tables of the migration files it applies to the
-- database's Data API, so these lines, with no policy, are what keep anyone holding the database's public key from
-- every row: keep them (TOFU.md, *Schema*).
ALTER TABLE "heatmap_event" ENABLE ROW LEVEL SECURITY;
