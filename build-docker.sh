#!/bin/bash -ex

for branch in v2.8.2; do
	docker buildx build --push --platform linux/amd64,linux/arm64,linux/arm/v5,linux/arm/v6,linux/arm/v7 --tag quay.io/pqatsi/docker-nut:${branch} --tag quay.io/pqatsi/docker-nut:latest --build-arg branch=${branch} .
done
