FROM node:alpine3.13

WORKDIR /build
COPY app/ .

RUN npm install

EXPOSE 8081
ENTRYPOINT [ "npm", "start" ]