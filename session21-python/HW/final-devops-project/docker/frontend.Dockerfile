# Build context: application/frontend
#   docker build -f docker/frontend.Dockerfile -t taskboard-frontend:local application/frontend

# ---- build stage: Node builds the static React bundle ----
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY index.html vite.config.js ./
COPY src ./src
RUN npm run build

# ---- runtime stage: unprivileged nginx (runs as uid 101, listens on 8080) ----
FROM nginxinc/nginx-unprivileged:1.29-alpine
COPY --from=build /app/dist /usr/share/nginx/html
ENV BACKEND_URL=http://backend:8000
COPY nginx.conf /etc/nginx/templates/default.conf.template
EXPOSE 8080
