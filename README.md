# Install `caesura`

This repository contains install scripts and prebuilt dependency binaries for [caesura](https://github.com/RogueOneEcho/caesura).

## Documentation

Refer to the [install guide](https://github.com/RogueOneEcho/caesura/blob/main/docs/INSTALL.md) for all installation methods.

## Install Script

The install script downloads the latest `caesura` binary from GitHub Releases, detects your platform, and installs it to `~/.local/bin`.

## Prebuilt sox_ng Binaries

A CI workflow builds statically-linked [sox_ng](https://codeberg.org/sox_ng/sox_ng) and [FLAC](https://github.com/xiph/flac) binaries for platforms where package managers don't provide sox_ng.

Archives are published to [GitHub Releases](https://github.com/RogueOneEcho/install/releases).

See the [dependencies guide](https://github.com/RogueOneEcho/caesura/blob/main/docs/DEPENDENCIES.md) for download and usage instructions.
