# =========================================================
#  React app - MULTI-STAGE build
#  Stage 1 compiles the app, Stage 2 only serves the output
# =========================================================

# ---------- Stage 1: BUILD ----------
FROM node:20-alpine AS builder

WORKDIR /app

# Copy manifests first so this layer is cached
# unless the dependencies actually change
COPY package.json ./
RUN npm install

# Now copy the source and build the production bundle
COPY public ./public
COPY src ./src
RUN npm run build

# ---------- Stage 2: SERVE ----------
FROM nginx:alpine

# Copy ONLY the compiled static files from the builder stage.
# Node.js, npm and node_modules are all left behind.
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
