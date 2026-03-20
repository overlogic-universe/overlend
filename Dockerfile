# ========================
# Build stage
# ========================
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git make gcc musl-dev

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN make build

# ========================
# Runtime stage
# ========================
FROM alpine:3.19

RUN apk add --no-cache ca-certificates

WORKDIR /root/

COPY --from=builder /app/build/overlendd /usr/bin/overlendd

EXPOSE 26656 26657 1317 9090

CMD ["overlendd"]