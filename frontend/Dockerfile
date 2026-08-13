FROM node:20-slim

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# NEXT_PUBLIC_* vars must be present at build time to end up in the client
# bundle — passed in via docker-compose.yml's build.args.
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

RUN npm run build

EXPOSE 3011

CMD ["npx", "next", "start", "-p", "3011", "-H", "0.0.0.0"]
