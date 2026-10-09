# ---- Build stage: install deps and produce the static bundle ----
FROM node:20-alpine AS build

WORKDIR /app

# Copy manifests first so the install layer is cached when only source changes
COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# ---- Runtime stage: serve the built assets with Nginx ----
FROM nginx:1.27-alpine

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
