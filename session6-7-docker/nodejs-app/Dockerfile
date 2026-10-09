FROM node:20-alpine

WORKDIR /app

# Copy manifests first so `npm install` is cached when only source changes
COPY package*.json ./
RUN npm install --omit=dev

COPY server.js ./

EXPOSE 3000

CMD ["npm", "start"]
