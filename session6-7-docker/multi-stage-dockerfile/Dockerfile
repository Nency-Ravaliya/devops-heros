# ==============================================================================
# Multi-Stage Dockerfile
# Stage 1: Build & Dependency Stage
# ==============================================================================
FROM node:18-alpine AS builder

WORKDIR /build

# Copy application files
COPY server.js ./

# Perform build tasks / package verification if needed
RUN echo "Building lightweight production artifact..."

# ==============================================================================
# Stage 2: Final Production Runtime Stage
# ==============================================================================
FROM node:18-alpine AS runner

# Create non-root system user for security best practices
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy artifact from builder stage
COPY --from=builder /build/server.js ./

# Set environment variable and permissions
ENV PORT=8080
USER appuser

EXPOSE 8080

CMD ["node", "server.js"]
