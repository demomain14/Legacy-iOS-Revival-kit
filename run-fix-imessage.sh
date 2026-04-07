#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: Python 3 is required to run this tool."
  exit 1
fi

if [[ ! -f "fix_imessage.py" ]]; then
  echo "Error: fix_imessage.py not found in $SCRIPT_DIR"
  exit 1
fi

python3 "${SCRIPT_DIR}/fix_imessage.py" "$@"
