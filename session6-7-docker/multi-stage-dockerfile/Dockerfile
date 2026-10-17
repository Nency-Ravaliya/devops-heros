FROM node:18-alpine AS builder

WORKDIR /build

# Copy application files
COPY server.js ./

# Perform build tasks / package verification if needed
RUN echo "Building lightweight production artifact..."

FROM node:18-alpine AS runner

# Create non-root system user for security best practices
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /build/server.js ./

ENV PORT=8080
USER appuser

EXPOSE 8080

CMD ["node", "server.js"]
