#!/bin/bash -ex

for branch in master v2.8.0-signed; do
	BUILD_FORMAT=docker podman build --platform linux/amd64,linux/arm64 --manifest docker-nut --build-arg branch=${branch} .
	BUILD_FORMAT=docker podman manifest push docker-nut docker://quay.io/pqatsi/docker-nut:${branch}
	podman manifest rm docker-nut
done
