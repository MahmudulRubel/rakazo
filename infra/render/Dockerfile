FROM node:24-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends tini ca-certificates curl && rm -rf /var/lib/apt/lists/*
RUN corepack enable

WORKDIR /app

COPY . .

RUN pnpm install --frozen-lockfile --engine-strict=false
RUN pnpm --filter @rakazo/db generate
RUN pnpm --filter @rakazo/api --filter @rakazo/worker build
RUN RAKAZO_ALLOW_DEV_SECRETS=1 pnpm --filter @rakazo/web build

ENV NODE_ENV=production
ENV PORT=10000
EXPOSE 10000

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["bash", "infra/render/start.sh"]
