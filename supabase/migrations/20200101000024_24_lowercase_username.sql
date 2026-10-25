-- Tofu: a copy of prisma/migrations/24_lowercase_username/migration.sql. It is applied once, in file-name order; TOFU.md
-- (*Schema*) says what applies it. Changes from upstream, if any, are marked "Tofu:" below.

-- Rename only soft-deleted rows that block lowercasing a live username.
UPDATE "user" AS d
SET "username" = CONCAT(LEFT(d."username", 246), '-', SUBSTRING(MD5(d."user_id"::text) FROM 1 FOR 8))
WHERE d."deleted_at" IS NOT NULL
  AND EXISTS (
    SELECT 1
    FROM "user" AS a
    WHERE a."deleted_at" IS NULL
      AND a."user_id" <> d."user_id"
      AND a."username" <> LOWER(a."username")
      AND LOWER(a."username") = LOWER(d."username")
  );

-- Lowercase live usernames unless another live row would still collide.
UPDATE "user" AS u
SET "username" = LOWER(u."username")
WHERE u."deleted_at" IS NULL
  AND u."username" <> LOWER(u."username")
  AND NOT EXISTS (
    SELECT 1
    FROM "user" AS c
    WHERE c."user_id" <> u."user_id"
      AND LOWER(c."username") = LOWER(u."username")
  );
