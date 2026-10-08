FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
# nginx:1.27-alpine (Alpine 3.21.3) had 44 fixable HIGH/CRITICAL CVEs -> use the current stable image and patch OS packages
FROM nginx:stable-alpine
RUN apk upgrade --no-cache
COPY --from=build /app/dist /usr/share/nginx/html
# Rendered to /etc/nginx/conf.d/default.conf at startup with ${BACKEND_HOST} filled in
COPY nginx.conf /etc/nginx/templates/default.conf.template
ENV BACKEND_HOST=backend:8000
EXPOSE 80
