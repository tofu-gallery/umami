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
| Database | Tofu's managed PostgreSQL, created with the first deploy. Tofu sets `DATABASE_URL` (its transaction pooler) and `SUPABASE_CA_CERT`, which the app uses, and saves the database's Data API address and public key (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`), which it does not; nothing is typed by hand |
| Schema | `supabase/migrations/` (26 files). Tofu applies them itself before the build, then opens their tables to the database's Data API, where row-level security keeps every row closed; `tofu:migrate` in the build applies only a file Tofu's ledger lacks (see *Schema* below) |
| Public settings | none needed. The app reads its own address from each request, so it needs no address setting |
| Hidden values | none needed (see *Optional settings*) |
| Must stay reachable by anyone | `/script.js` (the tracker) and `/api/send` (where it reports visits) |

## Accounts: the first visitor creates the administrator

Upstream's first migration creates one shared sign-in, username `admin` with password `umami`, in every installation. A copy on Tofu creates no account. While a copy has no account, its login page shows **Create the administrator account**: the first person to finish that form becomes the app's administrator, and the form never appears again once any account exists. **Open your copy right after its first deploy and create your account.** Its address is not published anywhere until you share it. Umami has no public sign-up: further people are added by the administrator, under Settings > Users.

## Schema: what applies `supabase/migrations`

On Tofu, Tofu itself applies the 26 files, before the build:

1. Tofu reads the build to decide whether the build applies the folder. It reads `vercel.json`'s `buildCommand`, `npx --yes pnpm@12.3.4 run build`, as one whole command that runs no migration step: it does not follow a version-pinned `pnpm@12.3.4 run build` into `package.json`'s `build` script, so it never sees `tofu:migrate`. On the `nextjs` preset, a build read whole with no migration step is one whose folder Tofu applies itself.
2. Before the build, Tofu applies each file its ledger (the Supabase CLI's `supabase_migrations.schema_migrations`) does not record, in file-name order, each in one transaction with its ledger row (`created_by` `tofu`, with the file's text). A file that fails stops the deploy before anything is built.
3. Then Tofu gives the roles the Data API uses (`anon`, `authenticated`, `service_role`) `select, insert, update, delete` on every table those files created, and `usage, select` on their sequences: Supabase's old default. What keeps anyone holding the database's public key from every row (the `user` table's password hashes included) is row-level security, which each file turns on for every table it creates, with no policy. **Never remove those lines, and give any table a new file creates the same line.**
4. The build then runs `tofu:migrate`, which finds all 26 files in the ledger and applies nothing.

`scripts/tofu-migrate.js` applies a file only when the ledger lacks it: when Tofu's own step did not run for a deploy (for example, Tofu-applied migrations turned off for this app on its Database page, or an account Tofu applies no migration files for), or where the repository runs somewhere else. It applies the missing files the same way, one transaction each with its ledger row, and Tofu then grants nothing on the tables it made; whatever the database's own defaults give the Data API's roles, row-level security keeps every row closed to the public key. The same holds if Tofu one day reads the build through to `tofu:migrate`: it then leaves the folder to the build. Either way each file runs once and the tables come out the same.

## What Tofu changes

- `supabase/migrations/*.sql` (new, 26 files): each `prisma/migrations/<NN>_<name>/migration.sql` copied to `supabase/migrations/202001010000<NN>_<NN>_<name>.sql` (a fixed date with upstream's folder number last, so the files sort as upstream's folders do), with a header naming its source and two changes marked `Tofu:`:
  - `20200101000001_01_init.sql` leaves out upstream's `INSERT` of the shared `admin`/`umami` sign-in (see *Accounts* above).
  - every file that creates a table turns on row-level security for it, in the same file. The app reads and writes over its own connection, which row-level security does not limit. Tofu opens these tables to the database's Data API after applying the files (see *Schema*), so these lines, with no policy, are what keep anyone holding the database's public key from every row.
  
  `prisma/migrations/` is untouched, for Prisma's own tools and upstream's Docker image. When a later upstream version adds a migration, copy it here the same way, with the next number and its row-level security line.
- `scripts/tofu-migrate.js` (new): the build's own step for `supabase/migrations`, run before `next build`. It applies each file the Supabase CLI's own ledger (`supabase_migrations.schema_migrations`, created the way Tofu creates it) does not record, in file-name order, each in one transaction with its ledger row, so neither this script, Tofu nor the Supabase CLI runs a file twice. On Tofu it normally applies nothing, because Tofu applied all 26 files before the build (see *Schema*); it covers a deploy Tofu's own step did not run for, and the repository run elsewhere. With `SUPABASE_CA_CERT` set it verifies the database server against that certificate and Node's own roots; verification is never turned off. Without `DATABASE_URL` it applies nothing. It replaces upstream's `check:db` step in the build, which runs `prisma migrate deploy`: Prisma Migrate needs a direct or session connection, and Tofu's `DATABASE_URL` is a transaction pooler. A database that upstream's own `prisma migrate deploy` already set up is not one this script can take over.
- `package.json` and `pnpm-lock.yaml`: the `build` script runs `tofu:migrate` (the new script above) where it ran `check:db`, and `pg` 8.22.0, already installed as `@prisma/adapter-pg`'s own dependency, is declared so the script can load it. `check:db`, `db:migrate`, `build:docker` and `start:docker` are unchanged.
- `vercel.json`: adds `buildCommand`, so the build runs with the same pnpm 12.3.4 that installs the dependencies (`engines.pnpm` asks for that version) instead of whichever pnpm the host picks. Tofu reads this command whole and finds no migration step in it, which is why Tofu applies `supabase/migrations` itself (see *Schema*).
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
- **Docker.** The `Dockerfile` is upstream's and still runs `prisma migrate deploy` over `prisma/migrations`, which creates the shared `admin`/`umami` sign-in; anyone who runs this repository that way must change that password at once. Its last stage also runs as the non-root user `nextjs` on port 3000, so it is not set up for Tofu's container hosting either. Tofu does not run the image: the gallery sets the preset to `nextjs`.

## Licence

MIT. `LICENSE` and its copyright line (Umami Software, Inc.) stay exactly as they are. The files Tofu changes carry a `Tofu:` note where they allow comments; `package.json`, `pnpm-lock.yaml`, `vercel.json` and the generated API client cannot, so this file lists them. The name **Umami** and its logo belong to Umami Software, Inc.; the copy shows them because it runs Umami, and implies no endorsement. The country, language and map data in `public/` and the browser, device and flag images ship with upstream as distributed. The Inter font is fetched by `next/font` at build time and served by the copy itself.

## Verification (2026-10-25)

On a Mac, against a throwaway local PostgreSQL 14 (`createdb website-analytics_r9`, dropped afterwards). No deployment and no Docker.

- `npx --yes pnpm@12.3.4 add -w pg@8.22.0` (the lockfile gains `pg` as a root dependency only), then `DATABASE_URL=postgresql://localhost:5432/website-analytics_r9 VERCEL=1 npx --yes pnpm@12.3.4 run build`: passed. `tofu:migrate` applied all 26 files; `build-geo` skipped on `VERCEL`; `next build` compiled; `postbuild` sent nothing.
- Database reset, then `pnpm run tofu:migrate` twice: `26 applied, 0 already recorded`, then `0 applied, 26 already recorded`. The database then held 26 tables in `public`, all 26 with row-level security, no row in `user`, and 26 ledger rows.
- `next start -H 127.0.0.1` on a free port: `/` and `/login` 200, `/api/heartbeat` 200, `/script.js` 200, `/api/auth/setup` answered `{"needed":true}`, `/api/config` answered `telemetryDisabled: true, updatesDisabled: true`, `/telemetry.js` answered `/* telemetry disabled */`.
- Headless Chromium (Playwright) against 127.0.0.1: `/` led to `/login` with the first-run form; creating `owner` signed in and opened the dashboard. Then over the API: a second setup was refused (400, `setup-done`) and `/api/auth/setup` answered `{"needed":false}`; signing in as `owner` gave role `admin`; a website `example.com` was created and read back; one page view sent to `/api/send` (with a browser user agent) showed in `/api/websites/<id>/stats` as 1 view, 1 visitor, 1 visit, with `/pricing` as the top path, and on the website's dashboard page. A new browser opening `/login` got the ordinary login form. No page errors; the console showed two 401s from the signed-out pages and one 404, which matches the broken icon beside the site's name: the page loads it from DuckDuckGo's icon service (see `FAVICON_URL`), which has none for `example.com`. The database held one account, `owner|admin`.
- Tofu's own GitHub import and checks, run from Tofu's code (`lane_check_r9.mts`) on the `tofu` branch: the import reads 2,050 files; Tofu's safety check passes (14 findings, none blocking); the app is not for the static lane (the detector answers `container` because of upstream's root `Dockerfile`, and the gallery sets the preset to `nextjs`).

Not checked here, only on a real Tofu deploy: Tofu's own migration step and grants on the managed database (replayed locally in the second pass below), the install and build on Tofu's hosting with pnpm 12.3.4, the connection to the managed database through its pooler with `SUPABASE_CA_CERT`, and location from the hosting's headers.

### Second pass (2026-10-25, after the first review)

The first review found that Tofu, not the build, applies `supabase/migrations` (see *Schema*). This pass changed TOFU.md and comments only, then checked the code again the way Tofu would run it. No deployment and no Docker.

- Tofu's reading of the build, replayed with a copy of `readTheBuild` and `migrationStepOf` from Tofu's `migration-step.ts` over `package.json` and `vercel.json`: `absent`, read whole, no script followed. The same files without `buildCommand` read `present`, read only in part (18 scripts followed), which is when Tofu would leave the folder to the build.
- A tree with no executable file: `git archive` of the commit, then `chmod a-x` on all 2,057 files. Everything below ran from that tree.
- A throwaway local PostgreSQL 14 database, with the 26 files applied the way Tofu's step applies them (each as one query, in one transaction with its ledger row first: `created_by` `tofu` and the file's text), then Tofu's grants pass (`select, insert, update, delete` on every table to `anon`, `authenticated` and `service_role`): 26 tables, all 26 with row-level security and all 26 granted to `anon`; 26 ledger rows.
- `npx --yes pnpm@12.3.4 install --frozen-lockfile`, then `DATABASE_URL=<that database> VERCEL=1 npx --yes pnpm@12.3.4 run build`: passed. `tofu:migrate` printed `0 applied, 26 already recorded, 26 files.`; `next build` compiled; `postbuild` sent nothing.
- `next start` on a free 127.0.0.1 port: `/`, `/login`, `/api/heartbeat`, `/script.js`, `/api/auth/setup` (`{"needed":true}`), `/api/config` (`telemetryDisabled` and `updatesDisabled` true) and `/telemetry.js` (`/* telemetry disabled */`) answered 200.
- Headless Chromium (Playwright) loading 127.0.0.1 only, every other host refused (the page asked for one, `icons.duckduckgo.com`): `/` led to the first-run form, and creating `owner` opened the dashboard. Over the API, a second setup was refused (400, `setup-done`); `owner` signed in as `admin`; a website was created and read back; one page view sent to `/api/send` showed as 1 view, 1 visitor and 1 visit with `/pricing` as the top path, on the website's page too; a new browser got the ordinary login form. No page errors; the console had the signed-out pages' two 401s and the two refused icon requests.
- Then, as `anon` and as `authenticated`, each holding all four privileges on every table: 0 rows in `user`, `website`, `website_event` and `session`, where the app's own connection saw 1 account (`owner|admin`), 1 website and 1 event; an insert into `website` was refused by row-level security; an update of `user` changed 0 rows. The ledger still held Tofu's 26 rows and no other.
- Tofu's step left out: a second throwaway database and `npx --yes pnpm@12.3.4 run tofu:migrate` twice printed `26 applied, 0 already recorded`, then `0 applied, 26 already recorded`; 26 tables, all 26 with row-level security, no account.
- Both databases dropped, the server stopped, the tree deleted.
