# syntax=docker/dockerfile:1
# TaskBoard UI — multi-stage build
#   stage 1 (build):   reproducible `npm ci` + `vite build`
#   stage 2 (runtime): static files served by the *unprivileged* nginx image
#                      (runs as uid 101, listens on 8080 — no root, no port < 1024)

FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY index.html vite.config.js ./
COPY src ./src
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.30-alpine AS runtime
ARG GIT_SHA=dev
LABEL org.opencontainers.image.title="taskboard-frontend" \
      org.opencontainers.image.description="TaskBoard React UI served by nginx" \
      org.opencontainers.image.revision="${GIT_SHA}"
# Pick up Alpine security fixes released after the base image was built (trivy: zlib).
USER 0
RUN apk upgrade --no-cache
USER 101
COPY --chown=101:101 nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build --chown=101:101 /app/dist /usr/share/nginx/html
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:8080/healthz"]
