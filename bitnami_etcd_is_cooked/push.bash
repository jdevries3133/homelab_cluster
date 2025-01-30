#!/bin/bash

set -eux

docker buildx build \
    --platform linux/amd64 \
    --tag jdevries3133/bitnami_etcd:$TAG \
    .
docker push jdevries3133/bitnami_etcd:$TAG
