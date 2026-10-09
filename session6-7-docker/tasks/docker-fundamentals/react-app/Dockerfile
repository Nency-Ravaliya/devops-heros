# React is a build-time framework: the browser never runs the JSX, it runs the
# static files vite produces. So this is a multi-stage build - node compiles,
# nginx serves, and node never ships.

# ---- Stage 1: build ----
FROM node:24-alpine AS builder

WORKDIR /app

COPY package.json ./
RUN npm install

COPY vite.config.js index.html ./
COPY src ./src

RUN npm run build

# ---- Stage 2: serve ----
FROM nginx:latest

# Only the compiled output crosses over. node_modules and the toolchain stay
# behind in the builder stage and never reach the final image.
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
