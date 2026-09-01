# -------------------------
# Stage 1: Build
# -------------------------

FROM node:24-alpine AS frontend-builder
WORKDIR app/frontend
COPY app/frontend/package*.json ./
RUN npm ci
COPY app/frontend .
RUN npm run build

# -------------------------
# Stage 2: Production
# -------------------------

FROM node:24-alpine
WORKDIR app/backend
COPY app/backend/package*.json ./
RUN npm ci --only=production
COPY app/backend/ ./
COPY --from=frontend-builder app/frontend/dist app/frontend/dist

ENV NODE_ENV=production
ENV PORT=5000
EXPOSE 5000

CMD ["node", "src/server.js"]
