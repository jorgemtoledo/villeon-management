FROM node:20-slim

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .

EXPOSE 3001

CMD ["npx", "next", "dev", "-p", "3001", "-H", "0.0.0.0"]
