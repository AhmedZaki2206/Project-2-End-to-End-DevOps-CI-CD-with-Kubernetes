.PHONY: help test build run cluster-up deploy smoke status logs rollback clean

IMAGE_NAME ?= cloud-native-cicd-kubernetes
IMAGE_TAG ?= local

help:
	@echo "Targets: test build run cluster-up deploy smoke status logs rollback clean"

test:
	./scripts/test.sh

build:
	IMAGE_NAME=$(IMAGE_NAME) IMAGE_TAG=$(IMAGE_TAG) ./scripts/build.sh

run:
	docker run --rm --name cloud-native-api -p 8000:8000 $(IMAGE_NAME):$(IMAGE_TAG)

cluster-up:
	./scripts/cluster-up.sh

deploy:
	IMAGE_NAME=$(IMAGE_NAME) IMAGE_TAG=$(IMAGE_TAG) ./scripts/deploy.sh

smoke:
	./scripts/smoke-test.sh

status:
	./scripts/status.sh

logs:
	./scripts/logs.sh

rollback:
	./scripts/rollback.sh $(REVISION)

clean:
	./scripts/clean.sh

