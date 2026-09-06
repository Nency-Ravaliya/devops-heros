FROM node:22-alpine AS verification
WORKDIR /build
COPY server.js ./server.js
RUN node --check server.js

FROM node:22-alpine AS runtime
WORKDIR /app
COPY --from=verification /build/server.js ./server.js
RUN addgroup -S app && adduser -S app -G app
USER app
EXPOSE 8081
CMD ["node", "server.js"]
