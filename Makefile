ifeq ("$(GOPATH)","")
$(error GOPATH must be set)
endif

SHELL := /bin/bash
GOREPO := ${GOPATH}/src/github.com/lyft/ratelimit

TRAVIS_BUILD_NUMBER ?= 9999
NEXUS_CREDENTIALS ?= "anon:precioussecrets"
# if not set, then we're doing local development
# as this will be set by the travis matrix for realz
TARGET_PLATFORM ?= linux
TARGET_ARCH ?= amd64

RATELIMIT_FEATURE_VERSION=1.0
RATELIMIT_VERSION=${RATELIMIT_FEATURE_VERSION}.${TRAVIS_BUILD_NUMBER}
IMAGE_TAG=rossabaker/ratelimit-${RATELIMIT_FEATURE_VERSION}:${RATELIMIT_VERSION}

all: dockerize

.PHONY: bootstrap
bootstrap:
	script/install-glide
	glide install

.PHONY: bootstrap_tests
bootstrap_tests:
	cd ./vendor/github.com/golang/mock/mockgen && go install

.PHONY: docs_format
docs_format:
	script/docs_check_format

.PHONY: fix_format
fix_format:
	script/docs_fix_format
	go fmt $(shell glide nv)

.PHONY: check_format
check_format: docs_format
	@gofmt -l $(shell glide nv | sed 's/\.\.\.//g') | tee /dev/stderr | read && echo "Files failed gofmt" && exit 1 || true

.PHONY: compile
compile:
	mkdir -p ${GOREPO}/bin
	cd ${GOREPO}/src/service_cmd && GOOS=${TARGET_PLATFORM} GOARCH=${TARGET_ARCH} go build -o ratelimit ./ && mv ./ratelimit ${GOREPO}/bin
	cd ${GOREPO}/src/client_cmd && GOOS=${TARGET_PLATFORM} GOARCH=${TARGET_ARCH} go build -o ratelimit_client ./ && mv ./ratelimit_client ${GOREPO}/bin
	cd ${GOREPO}/src/config_check_cmd && GOOS=${TARGET_PLATFORM} GOARCH=${TARGET_ARCH} go build -o ratelimit_config_check ./ && mv ./ratelimit_config_check ${GOREPO}/bin

.PHONY: tests_unit
tests_unit: compile
	go test $(shell glide nv)

.PHONY: tests
tests: compile
	go test $(shell glide nv) -tags=integration

.PHONY: proto
proto:
	script/generate_proto

.PHONY: dockerize
dockerize: compile
	docker build -t ${IMAGE_TAG} .

.PHONY: run-local
run-local: dockerize
	env IMAGE_TAG=${IMAGE_TAG} docker-compose up

.PHONY: clean
clean:
	rm -rf bin && \
	rm -rf pkg

.PHONY: clean-all
clean-all: clean
	docker rmi -f ${IMAGE_TAG}

