FROM node:lts

WORKDIR /tmp

COPY package.json ./
RUN npm install

COPY index.js index.html ./

EXPOSE 7860

CMD ["node", "index.js"]
