FROM golang:1.25-alpine AS builder

ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -v \
    -ldflags='-w -s -extldflags "-static"' \
    -o blitz \
    ./cmd/blitz/main.go

RUN ldd /app/blitz && (echo "DYNAMIC! FAIL"; exit 1) || echo "STATIC ✓"

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/blitz .
CMD ["./blitz"]
