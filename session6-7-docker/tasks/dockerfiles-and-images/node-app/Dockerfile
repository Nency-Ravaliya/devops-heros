# Multi-stage: the builder resolves the full dependency tree, the runtime
# installs production dependencies only.
FROM node:24-alpine AS builder

WORKDIR /app
COPY package.json ./
RUN npm install
COPY app.js ./

FROM node:24-alpine AS production

WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY --from=builder /app/app.js ./

EXPOSE 8080
CMD ["npm", "start"]
