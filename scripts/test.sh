#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib.sh"
require_tool python
cd "$(repo_root)"
python -m pytest

