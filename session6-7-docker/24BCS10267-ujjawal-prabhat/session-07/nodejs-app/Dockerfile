# Multi-stage build
# Stage 1: install dev dependencies (TypeScript) and compile to JavaScript
FROM node:24 AS build
WORKDIR /app
COPY package*.json tsconfig.json ./
RUN npm install
COPY src ./src
RUN npm run build

# Stage 2: runtime - only the compiled JS on a small Alpine image
# (the app has no runtime dependencies, so node_modules is not copied at all)
FROM node:24-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/dist ./dist
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
