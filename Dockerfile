ARG REPO_URL

# Stage 1: Build the Go application
FROM ${REPO_URL}/golang:1.23.3-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy the Go modules manifests if they exist
COPY /go.mod /go.sum ./

# Download the Go modules if the manifests were copied
RUN if [ -f go.mod ]; then go mod download; fi

# Copy the source code
COPY . .

# Build the Go application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -o go-server .

# Stage 2: Create the final image
FROM ${REPO_URL}/alpine:latest

# Set the working directory
WORKDIR /app

# Copy the built binary from the builder stage
COPY --from=builder /app/go-server .

# Expose the port the application runs on
EXPOSE 9001

# Command to run the application
CMD ["./go-server"]