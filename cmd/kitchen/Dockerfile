# Stage 1: Builder (FORCE STATIC: musl-only, no glibc deps)
FROM golang:1.25-alpine AS builder

# Static build
ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

WORKDIR /app

# Cache deps
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build STATIC binary (ldflags: strip debug + static link) (Didn't understand this part tbh, but it works)
RUN go build -v \
    -ldflags='-w -s -extldflags "-static"' \
    -o kitchen \
    ./cmd/kitchen/main.go

# Verify static (fails build if dynamic — your new safety net) (neither this part)
RUN ldd /app/kitchen && (echo "DYNAMIC! FAIL"; exit 1) || echo "STATIC ✓ (musl)"

# Stage 2: Runtime (unchanged — now works!)
FROM alpine:3.20
RUN apk add --no-cache ca-certificates  # For gRPC/TLS (In theory this is not needed for this local project but it's a good practice)

WORKDIR /app
COPY --from=builder /app/kitchen .

EXPOSE 50051
CMD ["./kitchen"]
