#!/usr/bin/make -f

APP_NAME=overlendd
BUILD_DIR=build

# Auto-detect GOPATH
GOPATH := $(shell go env GOPATH)

# Proto dependency paths
GOGO_PROTO_PATH := $(shell go list -f '{{ .Dir }}' -m github.com/gogo/protobuf 2>/dev/null)
COSMOS_PROTO_PATH := $(shell go list -f '{{ .Dir }}' -m github.com/cosmos/cosmos-proto 2>/dev/null)
COSMOS_SDK_PROTO_PATH := $(shell go list -f '{{ .Dir }}' -m github.com/cosmos/cosmos-sdk 2>/dev/null)

########################################
### PROTO
########################################

proto-deps:
	@echo "Ensuring proto dependencies..."
	@go mod download

proto-gen: proto-deps
	@echo "Generating protobuf (gogo)..."
	@cd proto && buf generate --template buf.gen.gogo.yaml

	@echo "Generating protobuf (pulsar)..."
	@cd proto && buf generate --template buf.gen.pulsar.yaml

proto-lint:
	@echo "Linting proto..."
	@cd proto && buf lint

proto-format:
	@echo "Formatting proto..."
	@cd proto && buf format -w

proto-all: proto-format proto-lint proto-gen

########################################
### BUILD
########################################

build:
	@echo "Building binary..."
	@mkdir -p $(BUILD_DIR)
	@go build -o $(BUILD_DIR)/$(APP_NAME) ./cmd/$(APP_NAME)

run:
	@go run ./cmd/$(APP_NAME)

clean:
	@rm -rf $(BUILD_DIR)

########################################
### LOCALNET
########################################

localnet-start:
	docker compose up -d

localnet-stop:
	docker compose down

########################################
.PHONY: proto-deps proto-gen proto-lint proto-format proto-all build run clean localnet-start localnet-stop