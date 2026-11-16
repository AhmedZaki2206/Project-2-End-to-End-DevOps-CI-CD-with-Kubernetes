#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib.sh"
require_tool kubectl
require_tool curl

PORT="${PORT:-18080}"
kubectl -n "${NAMESPACE}" port-forward "service/${RELEASE_NAME}-cloud-native-api" "${PORT}:80" >/tmp/cloud-native-port-forward.log 2>&1 &
PF_PID=$!
trap 'kill "${PF_PID}" 2>/dev/null || true' EXIT

for _ in {1..20}; do
  if curl --fail --silent "http://127.0.0.1:${PORT}/health/ready" >/dev/null; then
    break
  fi
  sleep 1
done

curl --fail --silent --show-error "http://127.0.0.1:${PORT}/"
curl --fail --silent --show-error "http://127.0.0.1:${PORT}/health/live"
curl --fail --silent --show-error "http://127.0.0.1:${PORT}/health/ready"
curl --fail --silent --show-error "http://127.0.0.1:${PORT}/version"
echo
echo "Smoke tests passed."

