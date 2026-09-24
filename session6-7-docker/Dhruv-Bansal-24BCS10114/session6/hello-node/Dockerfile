FROM node:22-alpine
WORKDIR /app
COPY server.js ./server.js
RUN addgroup -S app && adduser -S app -G app
USER app
EXPOSE 3000
CMD ["node", "server.js"]
