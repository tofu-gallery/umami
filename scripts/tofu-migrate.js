/* eslint-disable no-console */
// Tofu: this file is Tofu's addition (see TOFU.md). It applies supabase/migrations during the build, once each.
//
// Tofu gives a copy its database as DATABASE_URL (a transaction pooler, which Prisma Migrate cannot use) and the
// database server's root certificate as SUPABASE_CA_CERT. The build reads several programs Tofu does not read, so Tofu
// leaves the supabase/migrations folder to the build, and this script applies it: the files in file-name order, each in
// one transaction with its row in the Supabase CLI's own ledger (supabase_migrations.schema_migrations, created the way
// Tofu creates it), so neither this script, Tofu nor the Supabase CLI ever runs a file twice. Without DATABASE_URL it
// applies nothing.
import 'dotenv/config';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { rootCertificates } from 'node:tls';
import pg from 'pg';

const URL_TLS_PARAMETERS = ['ssl', 'sslmode', 'sslcert', 'sslkey', 'sslrootcert', 'uselibpqcompat'];

const databaseUrl = process.env.DATABASE_URL?.trim();

if (!databaseUrl) {
  console.log('[tofu-migrate] DATABASE_URL is not set; nothing to apply.');
  process.exit(0);
}

// node-postgres reads sslmode=require as full verification and lets the URL replace an ssl object passed beside it,
// so with SUPABASE_CA_CERT set the URL's TLS parameters come out and the server is verified against that root as well
// as Node's own. Verification is never turned off; without SUPABASE_CA_CERT the URL is used as it is.
function poolConfig() {
  const setting = process.env.SUPABASE_CA_CERT?.trim();

  if (!setting) {
    return { connectionString: databaseUrl };
  }

  const ca = setting.includes('-----BEGIN') ? setting : Buffer.from(setting, 'base64').toString('utf8');
  let url;

  try {
    url = new URL(databaseUrl);
  } catch {
    // Not the parser's own error, which would carry the URL and its password.
    throw new Error('DATABASE_URL must be a PostgreSQL URL.');
  }

  for (const name of URL_TLS_PARAMETERS) {
    url.searchParams.delete(name);
  }

  return {
    connectionString: url.toString(),
    ssl: { ca: [...rootCertificates, ca], rejectUnauthorized: true },
  };
}

const directory = join(process.cwd(), 'supabase', 'migrations');
const files = readdirSync(directory)
  .filter(name => /^[0-9]+_[^/]*\.sql$/.test(name))
  .sort();

const pool = new pg.Pool({ ...poolConfig(), max: 1 });
const client = await pool.connect();

try {
  await client.query('create schema if not exists supabase_migrations');
  await client.query(
    'create table if not exists supabase_migrations.schema_migrations (version text not null primary key)',
  );
  await client.query(
    'alter table supabase_migrations.schema_migrations add column if not exists statements text[], add column if not exists name text, add column if not exists created_by text',
  );

  const recorded = new Set(
    (await client.query('select version from supabase_migrations.schema_migrations')).rows.map(
      row => row.version,
    ),
  );
  let applied = 0;

  for (const file of files) {
    const [, version, name] = file.match(/^([0-9]+)_(.*)\.sql$/);

    if (recorded.has(version)) {
      continue;
    }

    const sql = readFileSync(join(directory, file), 'utf8');

    await client.query('begin');

    try {
      // The ledger row goes in first, so a run racing this one stops on its primary key instead of applying twice.
      await client.query(
        'insert into supabase_migrations.schema_migrations (version, name) values ($1, $2)',
        [version, name],
      );
      await client.query(sql);
      await client.query('commit');
    } catch (e) {
      await client.query('rollback');
      throw new Error(`${file}: ${e.message}`);
    }

    applied += 1;
    console.log(`[tofu-migrate] applied ${file}`);
  }

  console.log(
    `[tofu-migrate] ${applied} applied, ${files.length - applied} already recorded, ${files.length} files.`,
  );
} finally {
  client.release();
  await pool.end();
}
