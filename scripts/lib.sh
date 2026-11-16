#!/usr/bin/env bash
set -Eeuo pipefail

readonly CLUSTER_NAME="${CLUSTER_NAME:-cloud-native-dev}"
readonly NAMESPACE="${NAMESPACE:-cloud-native-demo}"
readonly IMAGE_NAME="${IMAGE_NAME:-cloud-native-cicd-kubernetes}"
readonly IMAGE_TAG="${IMAGE_TAG:-local}"
readonly RELEASE_NAME="${RELEASE_NAME:-cloud-native}"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: '$1' is required but was not found in PATH." >&2
    echo "See README prerequisites. Windows users should run these scripts from WSL2 or Git Bash." >&2
    exit 1
  fi
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

