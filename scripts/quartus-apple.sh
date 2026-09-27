#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${QUARTUS_CACHE_DIR:-$ROOT/build/quartus}"
INSTALL_ROOT="$CACHE_DIR/intelFPGA_lite"
RUNTIME_IMAGE="docker.io/library/quartus17-runtime:apple-amd64"
INSTALLER_IMAGE="docker.io/library/quartus17-installer:apple-arm64"
INSTALLER_VOLUME=quartus17-installer-root-v1
source "$ROOT/scripts/quartus-downloads.sh"

command -v container >/dev/null 2>&1 || {
  echo "Apple container is required: https://github.com/apple/container" >&2
  exit 1
}
prepare_quartus_downloads

container build --arch amd64 \
  --file "$ROOT/containers/quartus/runtime.Containerfile" \
  --tag "$RUNTIME_IMAGE" "$ROOT"
container build --arch arm64 \
  --file "$ROOT/containers/quartus/installer.Containerfile" \
  --tag "$INSTALLER_IMAGE" "$ROOT"

container volume inspect "$INSTALLER_VOLUME" >/dev/null 2>&1 || \
  container volume create "$INSTALLER_VOLUME"

# The official installer hangs under Rosetta. Install in an amd64 QEMU chroot;
# the installed command-line tools run normally in the Rosetta runtime image.
container run --rm --cap-add CAP_SYS_ADMIN --read-only-path NONE \
  --mount "type=volume,source=$INSTALLER_VOLUME,target=/qemu-root" \
  "$INSTALLER_IMAGE" sh -lc '
    set -eu
    update-binfmts --enable qemu-x86_64
    if [ ! -f /qemu-root/.bootstrap-complete ]; then
      debootstrap --arch=amd64 --foreign bionic /qemu-root http://archive.ubuntu.com/ubuntu
      cp /usr/bin/qemu-x86_64-static /qemu-root/usr/bin/
      chroot /qemu-root /usr/bin/qemu-x86_64-static /bin/sh /debootstrap/debootstrap --second-stage
      touch /qemu-root/.bootstrap-complete
    fi
  '

mkdir -p "$INSTALL_ROOT"
if [[ ! -x "$INSTALL_ROOT/17.0/quartus/bin/quartus_sh" ]]; then
  container run --rm --cap-add CAP_SYS_ADMIN --read-only-path NONE \
    --mount "type=volume,source=$INSTALLER_VOLUME,target=/qemu-root" \
    --mount "type=bind,source=$CACHE_DIR,target=/qemu-root/quartus-cache" \
    --mount "type=bind,source=$INSTALL_ROOT,target=/qemu-root/opt/intelFPGA_lite" \
    "$INSTALLER_IMAGE" sh -lc "
      set -eu
      update-binfmts --enable qemu-x86_64
      chmod +x /qemu-root/quartus-cache/$QUARTUS_RUN
      chroot /qemu-root /usr/bin/qemu-x86_64-static /bin/bash -lc \
        '/quartus-cache/$QUARTUS_RUN --mode unattended --unattendedmodeui minimal --installdir /opt/intelFPGA_lite/17.0'
    "
fi

container run --arch amd64 --rm \
  --mount "type=bind,source=$INSTALL_ROOT,target=/opt/intelFPGA_lite,readonly" \
  "$RUNTIME_IMAGE" quartus_sh --version
