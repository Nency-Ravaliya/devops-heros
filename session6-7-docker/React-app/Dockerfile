FROM node:20

WORKDIR /app

COPY package.json .
COPY index.html .
COPY src ./src

RUN npm install
RUN npm run build

RUN npm install -g serve

EXPOSE 3000

CMD ["serve", "-s", "dist", "-l", "3000"]