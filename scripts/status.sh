#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib.sh"
require_tool kubectl
kubectl -n "${NAMESPACE}" get deployment,pods,service -o wide
kubectl -n "${NAMESPACE}" get events --sort-by=.metadata.creationTimestamp | tail -n 20

