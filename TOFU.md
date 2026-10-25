# Tofu gallery copy

This repository is Tofu's copy of **umami-software/umami** (licence: MIT), listed in Tofu's app gallery as **Cookie-free traffic stats** (slug `website-analytics`).

- `master` mirrors the upstream repository and is never committed to by Tofu.
- `tofu` carries Tofu's own changes; tags named `pin/<date>` mark the versions the gallery points to.
- A visitor who chooses this app gets a private snapshot of the pinned version in their own Tofu account. Their copy does not follow upstream updates.

## What the app is

Umami: website analytics without cookies. The owner adds one `<script>` tag to any website (on Tofu or anywhere else: WordPress, Shopify, Wix, a static page) and sees its visitors, pages, referrers, countries, devices and custom events, without collecting personal data or showing a cookie banner. Upstream: https://github.com/umami-software/umami, forked at commit `559e3c607c23d2c72d9bd4f6481bda428255323c` (2026-10-23, version 3.4.1).

## How Tofu runs it

| | |
|---|---|
| Preset | `nextjs` (Next.js 16), on Tofu's server hosting |
| Root folder | the repository root (the build also builds `packages/api-client` and `packages/mcp`, a pnpm workspace) |
| Install | `npx --yes pnpm@12.3.4 install --frozen-lockfile` (upstream's `vercel.json`) |
| Build | `npx --yes pnpm@12.3.4 run build` (`vercel.json`, Tofu's): `check:env`, `prisma generate`, `tofu:migrate`, the tracker and recorder scripts, the API client, the workspace packages, then `next build` |
| Output | `.next` (Next.js's own) |
| Database | Tofu's managed PostgreSQL, created with the first deploy. Tofu sets `DATABASE_URL` (its transaction pooler) and `SUPABASE_CA_CERT`; nothing is typed by hand |
| Schema | `supabase/migrations/` (26 files), applied at the start of each build by `scripts/tofu-migrate.js` |
| Public settings | none needed. The app reads its own address from each request, so it needs no address setting |
| Hidden values | none needed (see *Optional settings*) |
| Must stay reachable by anyone | `/script.js` (the tracker) and `/api/send` (where it reports visits) |

## Accounts: the first visitor creates the administrator

Upstream's first migration creates one shared sign-in, username `admin` with password `umami`, in every installation. A copy on Tofu creates no account. While a copy has no account, its login page shows **Create the administrator account**: the first person to finish that form becomes the app's administrator, and the form never appears again once any account exists. **Open your copy right after its first deploy and create your account.** Its address is not published anywhere until you share it. Umami has no public sign-up: further people are added by the administrator, under Settings > Users.

## What Tofu changes

- `supabase/migrations/*.sql` (new, 26 files): each `prisma/migrations/<NN>_<name>/migration.sql` copied to `supabase/migrations/202001010000<NN>_<NN>_<name>.sql` (a fixed date with upstream's folder number last, so the files sort as upstream's folders do), with a header naming its source and two changes marked `Tofu:`:
  - `20200101000001_01_init.sql` leaves out upstream's `INSERT` of the shared `admin`/`umami` sign-in (see *Accounts* above).
  - every file that creates a table turns on row-level security for it, in the same file. The app reads and writes over its own connection, which row-level security does not limit; the database's public Data API, reachable with the database's public key, gets nothing from these tables.
  
  `prisma/migrations/` is untouched, for Prisma's own tools and upstream's Docker image. When a later upstream version adds a migration, copy it here the same way, with the next number and its row-level security line.
- `scripts/tofu-migrate.js` (new): applies `supabase/migrations` at the start of the build, in file-name order, each file in one transaction with its row in the Supabase CLI's own ledger (`supabase_migrations.schema_migrations`, created the way Tofu creates it), so neither this script, Tofu nor the Supabase CLI runs a file twice. With `SUPABASE_CA_CERT` set it verifies the database server against that certificate and Node's own roots; verification is never turned off. Without `DATABASE_URL` it applies nothing. It replaces upstream's `check:db` step in the build, which runs `prisma migrate deploy`: Prisma Migrate needs a direct or session connection, and Tofu's `DATABASE_URL` is a transaction pooler. A database that upstream's own `prisma migrate deploy` already set up is not one this script can take over.
- `package.json` and `pnpm-lock.yaml`: the `build` script runs `tofu:migrate` (the new script above) where it ran `check:db`, and `pg` 8.22.0, already installed as `@prisma/adapter-pg`'s own dependency, is declared so the script can load it. `check:db`, `db:migrate`, `build:docker` and `start:docker` are unchanged.
- `vercel.json`: adds `buildCommand`, so the build runs with the same pnpm 12.3.4 that installs the dependencies (`engines.pnpm` asks for that version) instead of whichever pnpm the host picks.
- `src/lib/tofu-database.ts` (new) and `src/lib/prisma.ts`: Tofu's `DATABASE_URL` ends in `sslmode=require`, which node-postgres reads as full verification, and the database's certificate chains to a root Node does not ship, so the URL alone fails with `SELF_SIGNED_CERT_IN_CHAIN`. When `SUPABASE_CA_CERT` is set, the URL's TLS parameters are removed and the server is verified against that certificate as well as Node's roots. Without it, the URL is used exactly as upstream used it. Prisma's `@prisma/adapter-pg` sends unnamed statements, which the transaction pooler accepts.
- `src/app/api/auth/setup/route.ts` (new), `src/app/login/SetupForm.tsx` (new) and `src/app/login/LoginPage.tsx`: the first-run form (see *Accounts*). The route creates the administrator only while the `user` table is empty, under a transaction-scoped advisory lock, so two first visitors cannot both become administrators. It is not offered with `CLOUD_MODE` or `DISABLE_LOGIN`.
- `packages/api-client/src/generated/*`: regenerated by the build (`generate:api:client`) for the new route.
- `scripts/postbuild.js`, `src/app/api/scripts/telemetry/route.ts` and `src/app/api/config/route.ts`: upstream reports to Umami Software by default: after every build (`postbuild.js` posts the version, Node and operating system to `api.umami.is`), from the dashboard (`/telemetry.js` adds an invisible image from `i.umami.is`), and, for administrators, by asking `api.umami.is` for a newer version. All three are off unless `ENABLE_TELEMETRY` (the first two) or `ENABLE_UPDATES` (the update check) is set; upstream's `DISABLE_TELEMETRY` and `DISABLE_UPDATES` still turn them off. A copy does not follow upstream, so an update notice would only point at upstream's releases.
- `TOFU.md`: this file.

Nothing else changed: the tracker, the reports, the name and the logo are upstream's.

## Optional settings

| Name | What it does | Kind |
|---|---|---|
| `APP_SECRET` | Unset, the app uses a hash of `DATABASE_URL` (upstream's own fallback, `src/lib/crypto.ts`). It signs sign-in and share tokens and the tracker's cache tokens, and visitors' anonymous IDs are derived from it. Setting one later, or anything that changes `DATABASE_URL` (restoring the database into a new one, a new database password), signs everybody out once, and visitors already counted are counted as new from then on. | hidden value |
| `TWO_FACTOR_ENCRYPTION_KEY` | Turns on two-factor sign-in: 64 hexadecimal characters, e.g. from `openssl rand -hex 32`. Without it the app says two-factor sign-in is not available, and everything else works. It is not derived from `DATABASE_URL` on purpose: it encrypts each person's two-factor secret, and a key that changed with the database after a restore would lock out everyone who uses two-factor. | hidden value |
| `ENABLE_TELEMETRY`, `ENABLE_UPDATES` | Switch upstream's reporting and update check back on (see above). | public |
| `FAVICON_URL` | Where the dashboard loads each tracked site's icon. Upstream's default is DuckDuckGo's icon service (`https://icons.duckduckgo.com/ip3/{{domain}}.ico`), which therefore sees the domains a dashboard shows; Tofu leaves it as upstream. | public |
| `TRACKER_SCRIPT_NAME`, `COLLECT_API_ENDPOINT` | Upstream's settings for serving the tracker and its endpoint under other names, which some ad blockers do not block. | public |

Leave unset: `CLOUD_MODE` and `CLOUD_URL` (Umami Cloud's own), `SKIP_DB_CHECK` (it would let a build start without a database), `DATABASE_TYPE`, `CLICKHOUSE_URL`, `REDIS_URL` and `KAFKA_*` (not offered by Tofu).

## Good to know

- **Location** (country, region, city) comes from the hosting's own request headers: on Tofu's hosting the build skips upstream's GeoLite2 download (`scripts/build-geo.js`).
- **Long reports** run as one request each. On the Free plan a request may run for 60 seconds, so a heavy report over a long range on a busy site can stop before it answers; a shorter range answers.
- **Database size.** Page views are small rows. Session replays and heatmaps store much more, and only start when a site adds the separate `recorder.js` script; leave them off on a small database.
- **Making the copy private.** With an access code or a list of people on Tofu's sign-in page in front of the app, keep `/script.js` and `/api/send` as open paths, or no website can report a visit. Session replays also need `/recorder.js`, `/api/record` and `/api/websites/<id>/recorder`.
- **Docker.** The `Dockerfile` is upstream's and still runs `prisma migrate deploy` over `prisma/migrations`, which creates the shared `admin`/`umami` sign-in; anyone who runs this repository that way must change that password at once. Tofu does not run the image.

## Licence

MIT. `LICENSE` and its copyright line (Umami Software, Inc.) stay exactly as they are. The files Tofu changes carry a `Tofu:` note where they allow comments; `package.json`, `pnpm-lock.yaml`, `vercel.json` and the generated API client cannot, so this file lists them. The name **Umami** and its logo belong to Umami Software, Inc.; the copy shows them because it runs Umami, and implies no endorsement. The country, language and map data in `public/` and the browser, device and flag images ship with upstream as distributed. The Inter font is fetched by `next/font` at build time and served by the copy itself.

## Verification (2026-10-25)

On a Mac, against a throwaway local PostgreSQL 14 (`createdb website-analytics_r9`, dropped afterwards). No deployment and no Docker.

- `npx --yes pnpm@12.3.4 add -w pg@8.22.0` (the lockfile gains `pg` as a root dependency only), then `DATABASE_URL=postgresql://localhost:5432/website-analytics_r9 VERCEL=1 npx --yes pnpm@12.3.4 run build`: passed. `tofu:migrate` applied all 26 files; `build-geo` skipped on `VERCEL`; `next build` compiled; `postbuild` sent nothing.
- Database reset, then `pnpm run tofu:migrate` twice: `26 applied, 0 already recorded`, then `0 applied, 26 already recorded`. The database then held 26 tables in `public`, all 26 with row-level security, no row in `user`, and 26 ledger rows.
- `next start -H 127.0.0.1` on a free port: `/` and `/login` 200, `/api/heartbeat` 200, `/script.js` 200, `/api/auth/setup` answered `{"needed":true}`, `/api/config` answered `telemetryDisabled: true, updatesDisabled: true`, `/telemetry.js` answered `/* telemetry disabled */`.
- Headless Chromium (Playwright) against 127.0.0.1: `/` led to `/login` with the first-run form; creating `owner` signed in and opened the dashboard. Then over the API: a second setup was refused (400, `setup-done`) and `/api/auth/setup` answered `{"needed":false}`; signing in as `owner` gave role `admin`; a website `example.com` was created and read back; one page view sent to `/api/send` (with a browser user agent) showed in `/api/websites/<id>/stats` as 1 view, 1 visitor, 1 visit, with `/pricing` as the top path, and on the website's dashboard page. A new browser opening `/login` got the ordinary login form. No page errors; the console showed two 401s from the signed-out pages and one 404, which matches the broken icon beside the site's name: the page loads it from DuckDuckGo's icon service (see `FAVICON_URL`), which has none for `example.com`. The database held one account, `owner|admin`.
- Tofu's own GitHub import and checks, run from Tofu's code (`lane_check_r9.mts`) on the `tofu` branch: the import reads 2,050 files; Tofu's safety check passes (14 findings, none blocking); the app is not for the static lane (the detector answers `container` because of upstream's root `Dockerfile`, and the gallery sets the preset to `nextjs`).

Not checked here, only on a real Tofu deploy: the install and build on Tofu's hosting with pnpm 12.3.4, the connection to the managed database through its pooler with `SUPABASE_CA_CERT`, and location from the hosting's headers.
