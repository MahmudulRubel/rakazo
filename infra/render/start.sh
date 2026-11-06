#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-10000}"

echo "Starting database migrations..."
pnpm --filter @rakazo/api db:deploy

echo "Starting API and Worker..."
pnpm --filter @rakazo/api start &
pnpm --filter @rakazo/worker start &

echo "Waiting for API to become ready..."
node --input-type=module -e '
for (let attempt = 0; attempt < 60; attempt++) {
  const ready = await fetch("http://127.0.0.1:3100/internal/health", { signal: AbortSignal.timeout(2000) }).then(r => r.ok).catch(() => false);
  if (ready) process.exit(0);
  await new Promise(resolve => setTimeout(resolve, 1000));
}
throw new Error("API did not become ready in time");
'

echo "Starting Web UI on port $PORT..."
exec pnpm --filter @rakazo/web preview --host 0.0.0.0 --port "$PORT"
