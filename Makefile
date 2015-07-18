.PHONY: \
	all \
	deps \
	update-deps \
	test-deps \
	update-test-deps \
	build \
	install \
	clean \
	shell \
	launch \
	lint \
	vet \
	errcheck \
	pretest \
	test-long \
	test \
	test-pfs \
	bench \
	proto

include etc/env/pfs.env

all: test

print-%:
	@echo $* = $($*)

deps:
	go get -d -v ./...

update-deps:
	go get -d -v -u -f ./...

test-deps:
	go get -d -v -t ./...

update-test-deps:
	go get -d -v -t -u -f ./...

build: deps
	go build ./...

install: deps
	go install ./...

clean:
	go clean -i ./...
	bin/clean
	bin/clean-btrfs

shell:
	PFS_DOCKER_OPTS="-it" bin/run /bin/bash

launch:
	PFS_DOCKER_OPTS="-d" bin/run /go/src/github.com/pachyderm/pachyderm/etc/bin/launch-wrapper /go/bin/shard

launch-pfsd:
	PFS_DOCKER_OPTS="-d" bin/run /go/src/github.com/pachyderm/pachyderm/etc/bin/launch-wrapper /go/bin/pfsd

lint:
	go get -v github.com/golang/lint/golint
	golint ./...

vet:
	go vet ./...

errcheck:
	errcheck ./...

pretest: lint vet errcheck

# TODO(pedge): add pretest when fixed
test:
	bin/go-test -test.short ./...

# TODO(pedge): add pretest when fixed
test-long:
	@ echo WARNING: this will not work as an OSS contributor for now, we are working on fixing this.
	@ echo This directive requires Pachyderm AWS credentials. Sleeping for 5 seconds so you can ctrl+c if you want...
	@ sleep 5
	bin/go-test ./...

test-pfs: test-deps
	go get -v github.com/golang/lint/golint
	for file in $(shell git ls-files 'src/pfs/*.go' | grep -v '\.pb\.go'); do \
		golint $$file; \
		done
	go vet ./src/pfs/...
	errcheck ./src/pfs/...
	bin/go-test -test.v ./src/pfs/pfstest/...

# TODO(pedge): add pretest when fixed
bench:
	@ echo WARNING: this will not work as an OSS contributor for now, we are working on fixing this.
	@ echo This directive requires Pachyderm AWS credentials. Sleeping for 5 seconds so you can ctrl+c if you want...
	@ sleep 5
	bin/go-test -bench . ./...

proto:
	@ if ! docker images | grep 'pedge/proto3grpc' > /dev/null; then \
		docker pull pedge/proto3grpc; \
		fi
	docker run \
		--volume $(shell pwd):/compile \
		--workdir /compile \
		pedge/proto3grpc \
		protoc \
		-I /usr/include \
		-I /compile/src/pfs \
		--go_out=plugins=grpc,Mgoogle/protobuf/empty.proto=github.com/peter-edge/go-google-protobuf,Mgoogle/protobuf/timestamp.proto=github.com/peter-edge/go-google-protobuf,Mgoogle/protobuf/wrappers.proto=github.com/peter-edge/go-google-protobuf:/compile/src/pfs \
		/compile/src/pfs/pfs.proto
