# Build stage
FROM node:20-slim AS builder

WORKDIR /app

# Set build environment
ENV NODE_ENV=development
ENV NEXT_TELEMETRY_DISABLED=1

# Copy package files
COPY package.json package-lock*.json ./

# Install all dependencies for development
RUN npm install

# Copy source files
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:20-slim AS runner

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy necessary files from builder
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/package.json ./

# Install production dependencies
RUN npm install --omit=dev

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3001

# Start the application
CMD ["node", "server.js"]
