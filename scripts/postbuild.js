import 'dotenv/config';
import { sendTelemetry } from './telemetry.js';

async function run() {
  // Tofu: upstream reports each build to api.umami.is unless DISABLE_TELEMETRY is set. Here it reports nothing unless
  // ENABLE_TELEMETRY is set (see TOFU.md).
  if (process.env.ENABLE_TELEMETRY && !process.env.DISABLE_TELEMETRY) {
    await sendTelemetry('build');
  }
}

run();
