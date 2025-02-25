FROM node:20-slim

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=development
ENV PORT=3001

COPY package*.json ./

# Install dependencies and required packages
RUN npm install && \
    npm install @next/swc-linux-x64-gnu && \
    npm install sharp

# Add tini for proper signal handling
RUN apt-get update && apt-get install -y tini

EXPOSE 3001

# Use tini as entrypoint
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["npm", "run", "dev"]
