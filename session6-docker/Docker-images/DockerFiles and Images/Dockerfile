# ---- Stage 1: Build ----
# Use the Go image to compile the application into a single binary
FROM golang:1.23-alpine AS build

WORKDIR /app

# Copy the source code
COPY main.go ./

# Build a statically linked binary named "server"
RUN CGO_ENABLED=0 go build -o server main.go

# ---- Stage 2: Run ----
# Start from a minimal base image - only the compiled binary is copied in,
# not the Go toolchain. This keeps the final image very small.
FROM alpine:3.20

WORKDIR /app

# Copy ONLY the built binary from the build stage
COPY --from=build /app/server ./

# The app listens on port 8080
EXPOSE 8080

# Run the binary
CMD ["./server"]
