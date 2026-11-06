#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-10000}"
export API_PORT=3100
export API_HOST="127.0.0.1"

if [ -n "${DATABASE_URL:-}" ]; then
  # Strip -pooler from Neon connection string for direct migration & realtime compatibility
  export DATABASE_URL="$(node -e 'console.log((process.env.DATABASE_URL || "").replace(/-pooler\./g, "."))')"
fi

if [ -n "${RENDER_EXTERNAL_URL:-}" ]; then
  export WEB_ORIGIN="${WEB_ORIGIN:-$RENDER_EXTERNAL_URL}"
  export BETTER_AUTH_URL="${BETTER_AUTH_URL:-$RENDER_EXTERNAL_URL}"
fi

echo "Starting database migrations..."
pnpm --filter @rakazo/api db:deploy

echo "Starting API..."
pnpm --filter @rakazo/api start &

echo "Waiting for API to become ready on http://127.0.0.1:3100..."
node --input-type=module -e '
for (let attempt = 1; attempt <= 120; attempt++) {
  try {
    const res = await fetch("http://127.0.0.1:3100/internal/health", { signal: AbortSignal.timeout(2000) });
    if (res.ok) {
      console.log(`API is ready (attempt ${attempt})!`);
      process.exit(0);
    }
  } catch (err) {
    if (attempt % 5 === 0) {
      console.log(`[attempt ${attempt}/120] waiting for API: ${err.message}`);
    }
  }
  await new Promise(resolve => setTimeout(resolve, 1000));
}
throw new Error("API did not become ready after 120 seconds");
'

echo "Starting Worker in background..."
pnpm --filter @rakazo/worker start &

echo "Starting Web UI on port $PORT..."
exec pnpm --filter @rakazo/web preview --host 0.0.0.0 --port "$PORT"
