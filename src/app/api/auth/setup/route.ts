// Tofu: this file is Tofu's addition (see TOFU.md).
//
// Upstream's first migration creates a fixed sign-in (username admin, password umami) that every installation shares
// until someone changes it. A copy on Tofu creates no account at all. While the app has no account, the login page asks
// whoever opens it to create one, and that first account is the app's administrator; once any account exists, this
// route creates nothing and the login page is the ordinary one. Further accounts are made by the administrator, under
// Settings > Users, as upstream.
import { z } from 'zod';
import { ROLES } from '@/lib/constants';
import { uuid } from '@/lib/crypto';
import { hashPassword } from '@/lib/password';
import prisma from '@/lib/prisma';
import { parseRequest } from '@/lib/request';
import { badRequest, json } from '@/lib/response';

export const dynamic = 'force-dynamic';

function setupOffered() {
  return !process.env.CLOUD_MODE && !process.env.DISABLE_LOGIN;
}

async function hasAccounts() {
  return (await prisma.client.user.count()) > 0;
}

export async function GET(request: Request) {
  const { error } = await parseRequest(request, null, { skipAuth: true });

  if (error) {
    return error();
  }

  return json({ needed: setupOffered() && !(await hasAccounts()) });
}

export async function POST(request: Request) {
  const schema = z.object({
    username: z.string().trim().min(1).max(255),
    password: z.string().min(8).max(255),
  });

  const { body, error } = await parseRequest(request, schema, { skipAuth: true });

  if (error) {
    return error();
  }

  if (!setupOffered()) {
    return badRequest({ message: 'This app does not create accounts here.' });
  }

  const username = body.username.toLowerCase();
  const password = hashPassword(body.password);

  // One transaction under a lock, so two first visitors cannot both make an administrator: the second one finds the
  // first one's account and creates nothing.
  const user = await prisma.client.$transaction(async tx => {
    await tx.$executeRaw`select pg_advisory_xact_lock(726310025)`;

    if ((await tx.user.count()) > 0) {
      return null;
    }

    return tx.user.create({
      data: { id: uuid(), username, password, role: ROLES.admin },
      select: { id: true, username: true },
    });
  });

  if (!user) {
    return badRequest({
      code: 'setup-done',
      message: 'This app already has an administrator. Sign in instead.',
    });
  }

  return json({ ok: true });
}
