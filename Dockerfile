FROM node:lts AS build
WORKDIR /app
COPY package*.json ./
RUN npm install --ignore-scripts puppeteer
RUN npm rebuild --platform=linux --arch=arm64v8 sharp

COPY . .

ARG PUBLIC_API_BASE_URL
ENV PUBLIC_API_BASE_URL=https://twapi1-358632560159.europe-west6.run.app

RUN npm run build

FROM nginx:alpine
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/dist /usr/share/nginx/html