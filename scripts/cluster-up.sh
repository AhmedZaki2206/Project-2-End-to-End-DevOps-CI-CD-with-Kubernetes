#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib.sh"
require_tool kind
require_tool kubectl
cd "$(repo_root)"
if kind get clusters | grep -Fxq "${CLUSTER_NAME}"; then
  echo "Kind cluster '${CLUSTER_NAME}' already exists."
else
  kind create cluster --name "${CLUSTER_NAME}" --config kind-config.yaml
fi
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

