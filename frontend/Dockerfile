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

# Ensure logs directory exists and is writable
RUN mkdir -p /app/logs && chmod 777 /app/logs

EXPOSE 3001

# Use tini as entrypoint with proper signal forwarding
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/sh", "-c", "exec npm run dev"]
CMD ["npm", "run", "dev"]
