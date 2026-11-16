#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib.sh"
require_tool kubectl
kubectl -n "${NAMESPACE}" logs deployment/"${RELEASE_NAME}-cloud-native-api" --all-pods=true --tail=100 --follow

