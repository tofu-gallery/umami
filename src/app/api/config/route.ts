import { isRelationalOnly } from '@/lib/db';
import { parseRequest } from '@/lib/request';
import { json } from '@/lib/response';

export const dynamic = 'force-dynamic';

export async function GET(request: Request) {
  const { error } = await parseRequest(request, null, { skipAuth: true });

  if (error) {
    return error();
  }

  return json({
    cloudMode: !!process.env.CLOUD_MODE,
    faviconUrl: process.env.FAVICON_URL,
    linksUrl: process.env.LINKS_URL,
    pixelsUrl: process.env.PIXELS_URL,
    privateMode: !!process.env.PRIVATE_MODE,
    sessionDeletionEnabled: isRelationalOnly(),
    // Tofu: telemetry and the update check (api.umami.is) are off unless ENABLE_TELEMETRY or ENABLE_UPDATES is set;
    // upstream turns them on by default (see TOFU.md).
    telemetryDisabled: !process.env.ENABLE_TELEMETRY || !!process.env.DISABLE_TELEMETRY,
    trackerScriptName: process.env.TRACKER_SCRIPT_NAME,
    updatesDisabled: !process.env.ENABLE_UPDATES || !!process.env.DISABLE_UPDATES,
  });
}
