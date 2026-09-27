#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_ROOT="${QUARTUS_CACHE_DIR:-$ROOT/build/quartus}/intelFPGA_lite"
IMAGE=docker.io/library/quartus17-runtime:apple-amd64

[[ -x "$INSTALL_ROOT/17.0/quartus/bin/quartus_sh" ]] || {
  echo "Run QUARTUS_ACCEPT_EULA=1 scripts/quartus-apple.sh first" >&2
  exit 1
}

container run --arch amd64 --rm --cpus 4 --memory 12g \
  --mount "type=bind,source=$INSTALL_ROOT,target=/opt/intelFPGA_lite,readonly" \
  --mount "type=bind,source=$ROOT/fpga,target=/work" \
  --workdir /work "$IMAGE" quartus_sh --flow compile example
