#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
moon version --all
moon fmt --check
for target in js wasm-gc native; do
  moon check --target "$target"
  moon test --target "$target"
  moon build --target "$target"
done
moon test --target js --release
moon build --target js --release
moon info
python3 scripts/test_cli.py
python3 scripts/test_examples.py
