# Apple Containers: cross + Quartus

A small, working extraction of the container patterns used by MiSTer MagiK:

- ARMv7 Rust cross-compilation with Apple `container` on Apple silicon.
- The same cross-compilation with Docker and `cross` on GitHub Actions.
- Quartus Prime Lite 17.0 in an amd64 Apple Container (Rosetta) or Docker.
- Two Linux GitHub Actions jobs: `cross` and `quartus`.

## Cross-compile on Apple silicon

Install [Apple container](https://github.com/apple/container), then:

```sh
container system start
scripts/cross-apple.sh
file target/armv7-unknown-linux-gnueabihf/release/apple-containers-example
```

The image uses Ubuntu 20.04 so the output stays compatible with the older
userspace on MiSTer. Cargo registry and Git caches are kept outside the
container in `~/.cache/apple-containers-example`.

## Quartus on Apple silicon

Download and use of Quartus is governed by Intel's license. After accepting
the Quartus Prime Lite terms, run:

```sh
container system start
QUARTUS_ACCEPT_EULA=1 scripts/quartus-apple.sh
scripts/quartus-build-apple.sh
```

Quartus itself runs as amd64 under Rosetta. Its old graphical installer does
not complete reliably there, so a small arm64 installer container creates an
amd64 Ubuntu 18.04 QEMU chroot for installation. The installed files remain in
the ignored `build/quartus` directory; no Intel software is redistributed.

## GitHub Actions (Linux, not Apple)

Run **Actions → Container examples → Run workflow**. The workflow has two
independent Ubuntu jobs:

- `cross` builds the ARMv7 Rust binary with Docker and `cross`.
- `quartus` downloads the official installers, builds the Docker runtime, and
  compiles the tiny Cyclone V example in `fpga/`.

The Quartus job is intentionally manual: the download and install are large
and require accepting Intel's terms. For a real project, cache the private
installed runtime in storage you control; do not publish it as a public image.

## Layout

```text
containers/cross/       ARMv7 compiler image used locally and in Actions
containers/quartus/     Quartus runtime and installer helper images
scripts/                Apple and Docker entrypoints
fpga/                   Minimal Cyclone V project
.github/workflows/      Two-job Linux example
```

The pins (Rust 1.98.0, Ubuntu 20.04, Quartus 17.0 Build 595, Cyclone V) mirror
the compatibility choices in MiSTer MagiK; update them deliberately.

Licensed under GPL-3.0-or-later. Quartus itself remains subject to Intel's
separate license and is not included in this repository.
