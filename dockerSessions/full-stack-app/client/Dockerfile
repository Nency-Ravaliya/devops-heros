# -------------------------
# Stage 1: Build
# -------------------------

FROM node:20-alpine AS builder
WORKDIR /app
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
COPY package*.json .
RUN npm install
COPY . .
RUN npm run build

# -------------------------
# Stage 2: Runtime
# -------------------------

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD [ "nginx", "-g", "daemon off;" ]