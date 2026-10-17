FROM node:24-alpine AS build
WORKDIR /app
COPY server.js .
RUN node --check server.js
FROM node:24-alpine
WORKDIR /app
COPY --from=build /app/server.js .
USER node
EXPOSE 3000
CMD ["node", "server.js"]
