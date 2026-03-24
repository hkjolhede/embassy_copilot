#!/usr/bin/env bash
set -euo pipefail

# Keep setup lightweight and deterministic.
# Pre-fetch deps so the first `cargo check` is faster.

cd "$(dirname "$0")/.."

cargo fetch

