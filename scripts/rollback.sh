#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib.sh"
require_tool helm
require_tool kubectl
REVISION="${1:-}"
if [[ -z "${REVISION}" ]]; then
  echo "Usage: ./scripts/rollback.sh <helm-revision>" >&2
  helm history "${RELEASE_NAME}" --namespace "${NAMESPACE}" || true
  exit 1
fi
helm rollback "${RELEASE_NAME}" "${REVISION}" --namespace "${NAMESPACE}" --wait --timeout 120s
kubectl -n "${NAMESPACE}" rollout status "deployment/${RELEASE_NAME}-cloud-native-api" --timeout=120s

