ARG NODE_IMAGE=node:24-alpine
FROM ${NODE_IMAGE} AS build
WORKDIR /app
COPY server.js .
RUN node --check server.js
FROM ${NODE_IMAGE}
WORKDIR /app
COPY --from=build /app/server.js .
USER node
EXPOSE 3000
CMD ["node", "server.js"]
