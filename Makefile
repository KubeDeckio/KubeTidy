VERSION ?= dev
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS = -X github.com/KubeDeckio/KubeTidy/internal/cli.version=$(VERSION) -X github.com/KubeDeckio/KubeTidy/internal/cli.commit=$(COMMIT) -X github.com/KubeDeckio/KubeTidy/internal/cli.date=$(DATE)

.PHONY: build test tidy clean release-binaries

build:
	go build -ldflags "$(LDFLAGS)" ./cmd/kubetidy

test:
	go test ./...

tidy:
	go mod tidy

clean:
	find . -type d -name dist -prune -exec rm -rf {} +
	find . -type d -name bin -prune -exec rm -rf {} +
	rm -f kubetidy kubetidy.exe

release-binaries:
	mkdir -p dist
	GOOS=darwin GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/kubectl-KubeTidy-darwin-amd64 ./cmd/kubetidy
	GOOS=darwin GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o dist/kubectl-KubeTidy-darwin-arm64 ./cmd/kubetidy
	GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/kubectl-KubeTidy-linux-amd64 ./cmd/kubetidy
	GOOS=linux GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o dist/kubectl-KubeTidy-linux-arm64 ./cmd/kubetidy
	GOOS=windows GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/kubetidy-windows-amd64.exe ./cmd/kubetidy
