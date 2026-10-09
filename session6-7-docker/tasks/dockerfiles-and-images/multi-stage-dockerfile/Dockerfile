# -------------------------------------------------------------------
# Stage 1: builder - installs the full dependency tree, including
# anything only needed at build time.
# -------------------------------------------------------------------
FROM node:24-alpine AS builder

WORKDIR /app

COPY package.json ./
RUN npm install

COPY server.js ./

# -------------------------------------------------------------------
# Stage 2: production - a clean base. Only runtime dependencies are
# installed here, and only the file the app actually needs is copied
# across from the builder. Nothing else from stage 1 survives.
# -------------------------------------------------------------------
FROM node:24-alpine AS production

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY --from=builder /app/server.js ./

EXPOSE 3000

CMD ["npm", "start"]
