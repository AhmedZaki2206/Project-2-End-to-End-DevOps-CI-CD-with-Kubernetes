#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib.sh"
require_tool docker
cd "$(repo_root)"
docker build --build-arg "APP_VERSION=${IMAGE_TAG}" --tag "${IMAGE_NAME}:${IMAGE_TAG}" .

