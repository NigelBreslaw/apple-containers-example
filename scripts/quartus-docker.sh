#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${QUARTUS_CACHE_DIR:-$ROOT/build/quartus}"
INSTALL_ROOT="$CACHE_DIR/intelFPGA_lite"
IMAGE=quartus17-runtime:docker-amd64
INSTALL_TIMEOUT="${QUARTUS_INSTALL_TIMEOUT:-20m}"
source "$ROOT/scripts/quartus-downloads.sh"

command -v docker >/dev/null 2>&1 || {
  echo "Docker is required" >&2
  exit 1
}
prepare_quartus_downloads

docker build --platform linux/amd64 \
  --file "$ROOT/containers/quartus/runtime.Containerfile" \
  --tag "$IMAGE" "$ROOT"

mkdir -p "$INSTALL_ROOT"
if [[ ! -x "$INSTALL_ROOT/17.0/quartus/bin/quartus_sh" ]]; then
  set +e
  docker run --platform linux/amd64 --rm \
    --volume "$CACHE_DIR:/quartus-cache" \
    --volume "$INSTALL_ROOT:/opt/intelFPGA_lite" \
    --workdir /quartus-cache "$IMAGE" \
    bash -lc "
      chmod +x '$QUARTUS_RUN'
      timeout '$INSTALL_TIMEOUT' ./'$QUARTUS_RUN' \
        --mode unattended --unattendedmodeui minimal \
        --installdir /opt/intelFPGA_lite/17.0
    "
  status=$?
  set -e
  if [[ "$status" -ne 0 && "$status" -ne 124 ]]; then
    exit "$status"
  fi
  if [[ "$status" -eq 124 ]]; then
    log="$INSTALL_ROOT/17.0/logs/quartus-17.0.0.595-linux-install.log"
    [[ -f "$log" ]] && tail -50 "$log" | grep -q 'Installation completed' || {
      echo "Quartus install timed out before completion" >&2
      exit 124
    }
  fi
fi

docker run --platform linux/amd64 --rm \
  --volume "$INSTALL_ROOT:/opt/intelFPGA_lite:ro" \
  "$IMAGE" quartus_sh --version
