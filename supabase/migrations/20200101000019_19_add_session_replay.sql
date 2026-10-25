-- Tofu: a copy of prisma/migrations/19_add_session_replay/migration.sql. It is applied once, in file-name order; TOFU.md
-- (*Schema*) says what applies it. Changes from upstream, if any, are marked "Tofu:" below.

-- AlterTable board: drop slug
DROP INDEX IF EXISTS "board_slug_key";
DROP INDEX IF EXISTS "board_slug_idx";
ALTER TABLE "board" DROP COLUMN IF EXISTS "slug";

-- AlterTable
ALTER TABLE "website" ADD COLUMN "replay_enabled" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "website" ADD COLUMN "replay_config" JSONB;

-- CreateTable
CREATE TABLE "session_replay" (
    "replay_id" UUID NOT NULL,
    "website_id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "visit_id" UUID NOT NULL,
    "chunk_index" INTEGER NOT NULL,
    "events" BYTEA NOT NULL,
    "event_count" INTEGER NOT NULL,
    "started_at" TIMESTAMPTZ(6) NOT NULL,
    "ended_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "session_replay_pkey" PRIMARY KEY ("replay_id")
);

-- CreateIndex
CREATE INDEX "session_replay_website_id_idx" ON "session_replay"("website_id");
CREATE INDEX "session_replay_session_id_idx" ON "session_replay"("session_id");
CREATE INDEX "session_replay_website_id_session_id_idx" ON "session_replay"("website_id", "session_id");
CREATE INDEX "session_replay_website_id_visit_id_idx" ON "session_replay"("website_id", "visit_id");
CREATE INDEX "session_replay_website_id_created_at_idx" ON "session_replay"("website_id", "created_at");
CREATE INDEX "session_replay_session_id_chunk_index_idx" ON "session_replay"("session_id", "chunk_index");

-- CreateTable
CREATE TABLE "session_replay_saved" (
    "saved_replay_id" UUID NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "website_id" UUID NOT NULL,
    "visit_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "session_replay_saved_pkey" PRIMARY KEY ("saved_replay_id"),
    CONSTRAINT "session_replay_saved_website_id_visit_id_key" UNIQUE ("website_id", "visit_id")
);

-- CreateIndex
CREATE INDEX "session_replay_saved_website_id_idx" ON "session_replay_saved"("website_id");
CREATE INDEX "session_replay_saved_visit_id_idx" ON "session_replay_saved"("visit_id");
CREATE INDEX "session_replay_saved_website_id_created_at_idx" ON "session_replay_saved"("website_id", "created_at");

-- Tofu: row-level security on for every table this file creates. The app reads and writes them over its own
-- connection, which these rules do not limit. Tofu opens the tables of the migration files it applies to the
-- database's Data API, so these lines, with no policy, are what keep anyone holding the database's public key from
-- every row: keep them (TOFU.md, *Schema*).
ALTER TABLE "session_replay" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "session_replay_saved" ENABLE ROW LEVEL SECURITY;
