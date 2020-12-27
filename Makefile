LOCAL_CONTAINER=minio-amd64-local

shell-minio:
	if [ -z "$$(docker ps -q -f name=$(LOCAL_CONTAINER))" ]; then \
		$(MAKE) start-minio; \
		sleep 3; \
	fi
	docker exec -it  $(LOCAL_CONTAINER) /bin/bash

start-minio: clean-minio build-amd64-minio
	cd test && \
		docker run --rm -it -d \
			-v $$PWD/addons:/addons/ \
			-v $$PWD/data:/data/ \
			-p 9000:9000 \
			--name $(LOCAL_CONTAINER) \
			buhl/minio-amd64

stop-minio:
	@if [ -n "$$(docker ps -q -f name=$(LOCAL_CONTAINER))" ]; then \
		docker stop $(LOCAL_CONTAINER); \
	fi

build-amd64-minio:
	docker run --rm --privileged \
		-v ~/.docker:/root/.docker \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		-v $$PWD/minio:/data \
		homeassistant/amd64-builder \
		--addon --amd64 --target /data --test

build-minio:
	docker run --rm --privileged \
		-v ~/.docker:/root/.docker \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		-v $$PWD/minio:/data \
		homeassistant/amd64-builder \
		--all --target /data --test

push-minio:
	docker run --rm --privileged \
		-v ~/.docker:/root/.docker \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		-v $$PWD/minio:/data \
		homeassistant/amd64-builder \
		--all --target /data --docker-hub-check

clean-minio:
	if [ -n "$$(docker ps -q -f name=$(LOCAL_CONTAINER))" ]; then \
		echo "Container is already running. stopping it"; \
		$(MAKE) stop-minio; \
	fi
	if [ -n "$(docker ps -aq -f status=exited -f name=<name>)" ]; then \
		docker rm $(LOCAL_CONTAINER); \
	fi;
	sudo rm -fr test/addons/minio

build-help:
	@docker run --rm homeassistant/amd64-builder --help

.PHONY: build-help build-minio build-amd64-minio push-minio start-minio stop-minio shell-minio
