# 项目信息
PROJECT_NAME := $(shell basename $$(pwd))
VERSION ?= $(shell git describe --tags --always --dirty="-dev")
BUILD_TIME := $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')
COMMIT := $(shell git rev-parse HEAD)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

# 环境变量
export GO111MODULE := on
export CGO_ENABLED := 0
export GOPROXY := https://goproxy.cn,direct

# 二进制文件输出目录
BIN_DIR := bin
BINARY := $(BIN_DIR)/$(PROJECT_NAME)

# 构建标志
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -X main.Commit=$(COMMIT) -X main.Branch=$(BRANCH)"

# 源文件和测试文件
SOURCE_FILES := $(shell find . -name '*.go' -type f)
TEST_FILES := $(shell find . -name '*_test.go' -type f)

# 默认目标
all: build

# 构建项目
build: $(BINARY)

$(BINARY): $(SOURCE_FILES)
	@mkdir -p $(BIN_DIR)
	go build $(LDFLAGS) -o $(BINARY) .

# 交叉编译
build-all: build-linux-amd64 build-linux-arm64 build-darwin-amd64 build-darwin-arm64 build-windows-amd64

build-linux-amd64:
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o $(BINARY)-linux-amd64 .

build-linux-arm64:
	GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o $(BINARY)-linux-arm64 .

build-darwin-amd64:
	GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o $(BINARY)-darwin-amd64 .

build-darwin-arm64:
	GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o $(BINARY)-darwin-arm64 .

build-windows-amd64:
	GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o $(BINARY)-windows-amd64.exe .

# 运行测试
test:
	go test -v -race -coverprofile=coverage.out ./...

# 运行基准测试
bench:
	go test -bench=. -benchmem ./...

# 代码格式化
fmt:
	go fmt ./...

# 代码静态分析
lint:
	@if ! command -v golangci-lint &> /dev/null; then \
		echo "Installing golangci-lint..."; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin v1.55.2; \
	fi
	golangci-lint run --fix

# 生成依赖图
deps:
	@if ! command -v go-mod-graph &> /dev/null; then \
		go install github.com/lufia/go-mod-graph@latest; \
	fi
	go-mod-graph -f png -o deps.png

# 清理构建产物
clean:
	rm -rf $(BIN_DIR)
	rm -f coverage.out deps.png

# 运行项目
run: build
	$(BINARY)

# 显示帮助信息
help:
	@echo "可用目标:"
	@echo "  build        - 构建项目"
	@echo "  build-all    - 交叉编译所有平台"
	@echo "  test         - 运行测试"
	@echo "  bench        - 运行基准测试"
	@echo "  fmt          - 格式化代码"
	@echo "  lint         - 代码静态分析并修复问题"
	@echo "  deps         - 生成依赖关系图"
	@echo "  clean        - 清理构建产物"
	@echo "  run          - 构建并运行项目"
	@echo "  help         - 显示此帮助信息"

.PHONY: all build build-all test bench fmt lint deps clean run help