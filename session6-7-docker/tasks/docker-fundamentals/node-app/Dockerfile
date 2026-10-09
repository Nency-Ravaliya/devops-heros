FROM node:24-alpine

WORKDIR /app

# package.json is copied on its own first so this layer, and the npm install
# below it, are only rebuilt when dependencies change - not on every code edit.
COPY package.json ./
RUN npm install

COPY server.js ./

EXPOSE 8080

CMD ["npm", "start"]
