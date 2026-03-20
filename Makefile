#!/usr/bin/make -f

APP_NAME=overlendd
BUILD_DIR=build

########################################
### PROTO
########################################

proto-gen:
	@echo "Generating protobuf (gogo)..."
	@cd proto && buf generate --template buf.gen.gogo.yaml

	@echo "Generating protobuf (pulsar)..."
	@cd proto && buf generate --template buf.gen.pulsar.yaml

proto-lint:
	@cd proto && buf lint

proto-format:
	@cd proto && buf format -w

proto-all: proto-format proto-lint proto-gen

########################################
### BUILD
########################################

build:
	@echo "Building binary..."
	@mkdir -p $(BUILD_DIR)
	@go build -o $(BUILD_DIR)/$(APP_NAME) ./cmd/...

run:
	@go run ./cmd/...

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
.PHONY: proto-gen proto-lint proto-format proto-all build run clean localnet-start localnet-stop