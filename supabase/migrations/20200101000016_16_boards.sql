-- Tofu: a copy of prisma/migrations/16_boards/migration.sql. It is applied once, in file-name order; TOFU.md
-- (*Schema*) says what applies it. Changes from upstream, if any, are marked "Tofu:" below.

-- CreateTable
CREATE TABLE "board" (
    "board_id" UUID NOT NULL,
    "type" VARCHAR(50) NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "description" VARCHAR(500) NOT NULL,
    "parameters" JSONB NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "user_id" UUID,
    "team_id" UUID,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "board_pkey" PRIMARY KEY ("board_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "board_slug_key" ON "board"("slug");

-- CreateIndex
CREATE INDEX "board_slug_idx" ON "board"("slug");

-- CreateIndex
CREATE INDEX "board_user_id_idx" ON "board"("user_id");

-- CreateIndex
CREATE INDEX "board_team_id_idx" ON "board"("team_id");

-- CreateIndex
CREATE INDEX "board_created_at_idx" ON "board"("created_at");

-- Tofu: row-level security on for every table this file creates. The app reads and writes them over its own
-- connection, which these rules do not limit. Tofu opens the tables of the migration files it applies to the
-- database's Data API, so these lines, with no policy, are what keep anyone holding the database's public key from
-- every row: keep them (TOFU.md, *Schema*).
ALTER TABLE "board" ENABLE ROW LEVEL SECURITY;
