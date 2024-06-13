#!/bin/bash -ex

#export BUILD_FORMAT=docker 

for branch in v2.8.2; do
	buildah build --annotation "org.opencontainers.image.description=Container with NUT for UPS support" --cache-from ghcr.io/leleobhz/docker-nut --cache-to ghcr.io/leleobhz/docker-nut --jobs=$(nproc --ignore=2) --platform linux/amd64,linux/arm64,linux/arm/v5,linux/arm/v6,linux/arm/v7 --manifest docker-nut --build-arg branch=${branch} .
	buildah manifest push --all docker-nut docker://quay.io/pqatsi/docker-nut:${branch}
	buildah manifest push --all docker-nut docker://quay.io/pqatsi/docker-nut:latest
	buildah manifest rm docker-nut
done
