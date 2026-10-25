-- Tofu: a copy of prisma/migrations/17_remove_duplicate_key/migration.sql, applied by scripts/tofu-migrate.js during the build
-- (see TOFU.md). Changes from upstream, if any, are marked "Tofu:" below.

-- DropIndex
DROP INDEX "link_link_id_key";

-- DropIndex
DROP INDEX "pixel_pixel_id_key";

-- DropIndex
DROP INDEX "report_report_id_key";

-- DropIndex
DROP INDEX "revenue_revenue_id_key";

-- DropIndex
DROP INDEX "segment_segment_id_key";

-- DropIndex
DROP INDEX "session_session_id_key";

-- DropIndex
DROP INDEX "team_team_id_key";

-- DropIndex
DROP INDEX "team_user_team_user_id_key";

-- DropIndex
DROP INDEX "user_user_id_key";

-- DropIndex
DROP INDEX "website_website_id_key";
