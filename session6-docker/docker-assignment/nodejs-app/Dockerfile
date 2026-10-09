FROM node:20-alpine

WORKDIR /app

# Cache dependencies layer
COPY package.json ./
RUN npm install

# Copy application files
COPY index.html vite.config.js ./
COPY src/ ./src/

EXPOSE 3000

CMD ["npm", "start"]
