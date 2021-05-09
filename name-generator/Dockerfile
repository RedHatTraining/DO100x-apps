FROM node:10

WORKDIR /build
COPY app/ .

RUN npm install
EXPOSE 80
ENTRYPOINT [ "npm", "start" ]