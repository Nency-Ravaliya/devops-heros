FROM node:24-alpine

WORKDIR /app

# copy manifests first so the dependency layer is cached
COPY package*.json ./
RUN npm ci --omit=dev

COPY server.js .

EXPOSE 3000

# run as the unprivileged user that ships with the node image
USER node

CMD ["npm", "start"]
