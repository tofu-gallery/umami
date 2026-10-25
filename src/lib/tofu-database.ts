// Tofu: this file is Tofu's addition, used by src/lib/prisma.ts (see TOFU.md).
import { rootCertificates } from 'node:tls';

// The connection-string parameters node-postgres takes its TLS settings from.
// Any of them in the URL replaces an `ssl` object passed beside it.
const URL_TLS_PARAMETERS = ['ssl', 'sslmode', 'sslcert', 'sslkey', 'sslrootcert', 'uselibpqcompat'];

export interface DatabasePoolConfig {
  connectionString: string;
  ssl?: { ca: string[]; rejectUnauthorized: true };
}

/**
 * The pool configuration for a database URL. A database Tofu manages arrives as
 * DATABASE_URL with `sslmode=require`, which node-postgres reads as full
 * verification, and its certificate chains to a root Node does not ship (Tofu
 * supplies it as SUPABASE_CA_CERT, PEM text or base64), so the URL on its own
 * fails with SELF_SIGNED_CERT_IN_CHAIN. When SUPABASE_CA_CERT is set, the URL's
 * own TLS parameters are removed and the server is verified against that root
 * as well as Node's own. Verification is never turned off; without
 * SUPABASE_CA_CERT the URL is used exactly as upstream used it.
 */
export function databasePoolConfig(databaseUrl: string): DatabasePoolConfig {
  const setting = process.env.SUPABASE_CA_CERT?.trim();

  if (!setting) {
    return { connectionString: databaseUrl };
  }

  const ca = setting.includes('-----BEGIN')
    ? setting
    : Buffer.from(setting, 'base64').toString('utf8');

  let url: URL;

  try {
    url = new URL(databaseUrl.trim());
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
