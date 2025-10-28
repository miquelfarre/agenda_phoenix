#!/usr/bin/env bash
set -euo pipefail

# Format all Dart sources with line length 300
# Usage: ./scripts/format_dart.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

if ! command -v dart >/dev/null 2>&1; then
  echo "Error: dart CLI not found in PATH. Install Dart/Flutter SDK." >&2
  exit 1
fi

# Prefer formatting only the app_flutter workspace to avoid build and generated folders
if [ -d "app_flutter" ]; then
  echo "Formatting Dart files in app_flutter with line length 300..."
  dart format app_flutter --line-length 300
else
  echo "Formatting Dart files in repository with line length 300..."
  dart format . --line-length 300
fi

echo "Done."
