FROM node:20

WORKDIR /app

COPY package*.json ./

RUN npm install

ADD <link> .

EXPOSE 3000

CMD ["npm", "start"]