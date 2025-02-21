# Build stage
FROM node:20-slim AS builder

WORKDIR /app

# Set build environment
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=development

# Copy package files
COPY package.json ./

# Install all dependencies including devDependencies
RUN npm install

# Copy source files
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:20-slim AS runner

WORKDIR /app

# Set runtime environment
ENV NODE_ENV=development
ENV NEXT_TELEMETRY_DISABLED=1

# Copy necessary files from builder
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3001

# Start the application
CMD ["node", "server.js"]
