# syntax=docker/dockerfile:1.7
# StockPilot frontend. Build: docker build -t stockpilot-frontend ./frontend

# ---------- stage 1: Node build -> static dist/ ----------------------------
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY index.html vite.config.js ./
COPY src ./src
RUN npm run build

# ---------- stage 2: Nginx runtime (non-root, listens on 8080) -------------
FROM nginxinc/nginx-unprivileged:1.29-alpine
# pick up Alpine security fixes newer than the base image (Trivy found fixable HIGHs)
USER root
RUN apk upgrade --no-cache
ENV BACKEND_URL=http://backend:8000 \
    NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html
USER 101
EXPOSE 8080
