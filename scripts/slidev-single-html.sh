#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(cd "${SCRIPT_DIRECTORY}/.." && pwd)"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: ./scripts/slidev-single-html.sh <deck-directory|slides.md> [output.html]" >&2
  exit 1
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "bun is required." >&2
  exit 1
fi

cd "${REPOSITORY_ROOT}"
bun "${REPOSITORY_ROOT}/tools/slidev-single-html.ts" "$@"
