#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="docker.io/library/apple-containers-example-cross:local"
CACHE="${APPLE_CONTAINERS_EXAMPLE_CACHE:-$HOME/.cache/apple-containers-example}"

command -v container >/dev/null 2>&1 || {
  echo "Apple container is required: https://github.com/apple/container" >&2
  exit 1
}

mkdir -p "$CACHE/registry" "$CACHE/git"
container build --arch arm64 \
  --file "$ROOT/containers/cross/Containerfile" \
  --tag "$IMAGE" "$ROOT"

container run --arch arm64 --rm --cpus 4 --memory 4g \
  --volume "$ROOT:/workspace" \
  --volume "$CACHE/registry:/root/.cargo/registry" \
  --volume "$CACHE/git:/root/.cargo/git" \
  --workdir /workspace \
  "$IMAGE" \
  cargo build --locked --release --target armv7-unknown-linux-gnueabihf
