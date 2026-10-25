-- Tofu: a copy of prisma/migrations/14_add_link_and_pixel/migration.sql. It is applied once, in file-name order; TOFU.md
-- (*Schema*) says what applies it. Changes from upstream, if any, are marked "Tofu:" below.

-- AlterTable
ALTER TABLE "report" ALTER COLUMN "type" SET DATA TYPE VARCHAR(50);

-- AlterTable
ALTER TABLE "revenue" ALTER COLUMN "currency" SET DATA TYPE VARCHAR(10);

-- AlterTable
ALTER TABLE "segment" ALTER COLUMN "type" SET DATA TYPE VARCHAR(50);

-- CreateTable
CREATE TABLE "link" (
    "link_id" UUID NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "url" VARCHAR(500) NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "user_id" UUID,
    "team_id" UUID,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "link_pkey" PRIMARY KEY ("link_id")
);

-- CreateTable
CREATE TABLE "pixel" (
    "pixel_id" UUID NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "user_id" UUID,
    "team_id" UUID,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "pixel_pkey" PRIMARY KEY ("pixel_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "link_link_id_key" ON "link"("link_id");

-- CreateIndex
CREATE UNIQUE INDEX "link_slug_key" ON "link"("slug");

-- CreateIndex
CREATE INDEX "link_slug_idx" ON "link"("slug");

-- CreateIndex
CREATE INDEX "link_user_id_idx" ON "link"("user_id");

-- CreateIndex
CREATE INDEX "link_team_id_idx" ON "link"("team_id");

-- CreateIndex
CREATE INDEX "link_created_at_idx" ON "link"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "pixel_pixel_id_key" ON "pixel"("pixel_id");

-- CreateIndex
CREATE UNIQUE INDEX "pixel_slug_key" ON "pixel"("slug");

-- CreateIndex
CREATE INDEX "pixel_slug_idx" ON "pixel"("slug");

-- CreateIndex
CREATE INDEX "pixel_user_id_idx" ON "pixel"("user_id");

-- CreateIndex
CREATE INDEX "pixel_team_id_idx" ON "pixel"("team_id");

-- CreateIndex
CREATE INDEX "pixel_created_at_idx" ON "pixel"("created_at");

-- DataMigration Funnel
DELETE FROM "report" WHERE type = 'funnel' and jsonb_array_length(parameters->'steps') = 1;
UPDATE "report" SET parameters = parameters - 'websiteId' - 'dateRange' - 'urls' WHERE type = 'funnel';

UPDATE "report"
SET parameters = jsonb_set(
    parameters,
    '{steps}',
    (
      SELECT jsonb_agg(
               CASE
                 WHEN step->>'type' = 'url'
                 THEN jsonb_set(step, '{type}', '"path"')
                 ELSE step
               END
             )
      FROM jsonb_array_elements(parameters->'steps') step
    )
)
WHERE type = 'funnel'
    and parameters @> '{"steps":[{"type":"url"}]}';

-- DataMigration Goals
UPDATE "report" SET type = 'goal' WHERE type = 'goals';

INSERT INTO "report" (report_id, user_id, website_id, type, name, description, parameters, created_at, updated_at)
SELECT gen_random_uuid(),
    user_id,
    website_id,
    'goal',
    concat(name, ' - ', elem ->> 'value'),
    description,
    jsonb_build_object(
           'type', CASE WHEN elem ->> 'type' = 'url' THEN 'path'
                        ELSE elem ->> 'type' END,
           'value', elem ->> 'value'
       ) AS parameters,
    created_at,
    updated_at
FROM "report"
CROSS JOIN LATERAL jsonb_array_elements(parameters -> 'goals') elem
WHERE type = 'goal'
    and elem ->> 'type' IN ('event', 'url');

DELETE FROM "report" WHERE type = 'goal' and parameters ? 'goals';

-- Tofu: row-level security on for every table this file creates. The app reads and writes them over its own
-- connection, which these rules do not limit. Tofu opens the tables of the migration files it applies to the
-- database's Data API, so these lines, with no policy, are what keep anyone holding the database's public key from
-- every row: keep them (TOFU.md, *Schema*).
ALTER TABLE "link" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "pixel" ENABLE ROW LEVEL SECURITY;
