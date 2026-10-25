# ---- stage 1: build the React app with Node --------------------------------
FROM node:24-alpine AS build
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY index.html vite.config.js ./
COPY src ./src
RUN npm run build

# ---- stage 2: serve the static files with nginx (non-root) -----------------
FROM nginxinc/nginx-unprivileged:stable-alpine
ENV BACKEND_URL=http://backend:8000
# the official image runs envsubst on /etc/nginx/templates/*.template at start-up
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /src/dist /usr/share/nginx/html
EXPOSE 8080
USER 101
