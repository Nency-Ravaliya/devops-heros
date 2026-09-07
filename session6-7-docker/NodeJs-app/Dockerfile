# Use official lightweight Node.js image
FROM node:18-alpine

# Set working directory inside container
WORKDIR /app

# Copy dependency manifests
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy application source code
COPY server.js ./

# Expose container port
EXPOSE 3000

# Set environment variable
ENV PORT=3000

# Command to run application
CMD ["npm", "start"]
