FROM node:lts

WORKDIR /tmp

COPY package.json ./
RUN npm install

COPY index.js index.html ./

EXPOSE 8000

CMD ["node", "index.js"]
