#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib.sh"
require_tool kind
kind delete cluster --name "${CLUSTER_NAME}"

