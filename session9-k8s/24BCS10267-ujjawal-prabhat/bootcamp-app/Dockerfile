FROM node:22-alpine
RUN apk add --no-cache curl
WORKDIR /app
COPY server.js .
ARG APP_VERSION=1
ENV APP_VERSION=${APP_VERSION}
EXPOSE 8080
CMD ["node", "server.js"]
