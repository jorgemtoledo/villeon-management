FROM node:20-slim

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .

EXPOSE 3011

CMD ["npx", "next", "dev", "-p", "3011", "-H", "0.0.0.0"]
