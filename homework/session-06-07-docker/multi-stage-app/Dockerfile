FROM node:22-alpine AS build
WORKDIR /src
COPY package.json server.js ./

FROM node:22-alpine
WORKDIR /app
COPY --from=build /src/package.json /src/server.js ./
EXPOSE 8080
USER node
CMD ["npm", "start"]
