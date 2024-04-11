#!/bin/bash -ex

for branch in v2.8.2; do
	BUILD_FORMAT=docker podman build --platform linux/amd64,linux/arm64,linux/arm/v5,linux/arm/v6,linux/arm/v7 --manifest docker-nut --build-arg branch=${branch} .
	BUILD_FORMAT=docker podman manifest push docker-nut docker://quay.io/pqatsi/docker-nut:${branch}
	BUILD_FORMAT=docker podman manifest push docker-nut docker://quay.io/pqatsi/docker-nut:latest
	podman manifest rm docker-nut
done
