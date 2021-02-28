.DEFAULT_GOAL := run
SHELL := /bin/bash
APP ?= $(shell basename $$(pwd) | tr '[:upper:]' '[:lower:]')
COMMIT_SHA = $(shell git rev-parse HEAD)

.PHONY: help
## help: prints this help message
help:
	@echo "Usage:"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

.PHONY: run
## run: runs backup script
run:
	source .env; source .env_*; ./backup.sh

.PHONY: minio
## minio: runs minio backend on docker
minio: minio-stop minio-start
	docker logs minio -f

.PHONY: minio-cleanup
## minio-cleanup: cleans up minio backend
minio-cleanup: minio-stop
.PHONY: minio-stop
minio-stop:
	docker rm -f minio || true

.PHONY: minio-start
minio-start:
	docker run -d -p 9000:9000 --name minio \
		-e "MINIO_ACCESS_KEY=6d611e2d-330b-4e52-a27c-59064d6e8a62" \
		-e "MINIO_SECRET_KEY=eW9sbywgeW91IGhhdmUganVzdCBiZWVuIHRyb2xsZWQh" \
		minio/minio server /data

.PHONY: minecraft
## minecraft: runs minecraft server on docker
minecraft: minecraft-start

.PHONY: minecraft-start
minecraft-start:
	java -Xmx1024M -Xms1024M -jar minecraft-server.jar nogui

.PHONY: minecraft-get
minecraft-get:
	wget https://launcher.mojang.com/v1/objects/1b557e7b033b583cd9f66746b7a9ab1ec1673ced/server.jar -O minecraft-server.jar

.PHONY: minecraft-client
## minecraft-client: connects to minecraft server with rcon CLI
minecraft-client:
	source .env; source .env_*; rcon-cli say hello

########################################################################################################################
####### docker/kubernetes related stuff ################################################################################
########################################################################################################################
.PHONY: image-login
## image-login: login to docker hub
image-login:
	@export PATH="$$HOME/bin:$$PATH"
	@echo $$DOCKER_PASS | docker login -u $$DOCKER_USER --password-stdin

.PHONY: image-build
## image-build: build docker image
image-build:
	@export PATH="$$HOME/bin:$$PATH"
	docker build -t jamesclonk/${APP}:${COMMIT_SHA} .

.PHONY: image-publish
## image-publish: build and publish docker image
image-publish:
	@export PATH="$$HOME/bin:$$PATH"
	docker push jamesclonk/${APP}:${COMMIT_SHA}
	docker tag jamesclonk/${APP}:${COMMIT_SHA} jamesclonk/${APP}:latest
	docker push jamesclonk/${APP}:latest

.PHONY: image-run
## image-run: run docker image
image-run:
	@export PATH="$$HOME/bin:$$PATH"
	docker run --rm --env-file .dockerenv jamesclonk/${APP}:${COMMIT_SHA}

.PHONY: cleanup
cleanup: docker-cleanup
.PHONY: docker-cleanup
## docker-cleanup: cleans up local docker images and volumes
docker-cleanup:
	docker system prune --volumes -a
