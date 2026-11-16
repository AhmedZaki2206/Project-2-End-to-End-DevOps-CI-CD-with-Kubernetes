#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib.sh"
require_tool docker
require_tool kind
require_tool kubectl
require_tool helm
cd "$(repo_root)"

docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1 || ./scripts/build.sh
kind load docker-image "${IMAGE_NAME}:${IMAGE_TAG}" --name "${CLUSTER_NAME}"

helm upgrade --install "${RELEASE_NAME}" ./helm/cloud-native-api \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set "namespace.create=false" \
  --set "namespace.name=${NAMESPACE}" \
  --set "image.repository=${IMAGE_NAME}" \
  --set "image.tag=${IMAGE_TAG}" \
  --wait --timeout 120s

kubectl -n "${NAMESPACE}" rollout status "deployment/${RELEASE_NAME}-cloud-native-api" --timeout=120s

