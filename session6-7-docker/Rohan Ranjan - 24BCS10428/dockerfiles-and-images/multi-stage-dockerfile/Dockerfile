FROM node:24-alpine AS builder

WORKDIR /app

COPY package.json ./
RUN npm install

COPY server.js ./

FROM node:24-alpine AS production

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY --from=builder /app/server.js ./

EXPOSE 3000

CMD ["npm", "start"]
