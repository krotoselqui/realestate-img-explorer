FROM node:20-slim

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=development
ENV PORT=3001

COPY package.json ./

RUN npm install && \
    npm install @next/swc-linux-x64-gnu

COPY . .

EXPOSE 3001

CMD ["npm", "run", "dev"]
