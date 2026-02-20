#!/usr/bin/env bash
set -euo pipefail

REPO="RogueOneEcho/caesura"
INSTALL_DIR="$HOME/.local/bin"

log_error() { printf '\033[0;31m%s\033[0m\n' "$1"; }
log_success() { printf '\033[0;32m%s\033[0m\n' "$1"; }
log_warning() { printf '\033[0;33m%s\033[0m\n' "$1"; }
log_info() { printf '\033[0;36m%s\033[0m\n' "$1"; }
log_debug() { printf '\033[0;90m%s\033[0m\n' "$1"; }

log_info "Checking dependencies"
missing=0
for cmd in flac lame; do
  if command -v "$cmd" > /dev/null 2>&1; then
    log_debug "Found $cmd"
  else
    log_error "Missing $cmd"
    missing=1
  fi
done
if command -v sox_ng > /dev/null 2>&1; then
  log_debug "Found sox_ng"
elif command -v sox > /dev/null 2>&1; then
  log_debug "Found sox (sox_ng is recommended)"
else
  log_error "Missing sox_ng (or sox)"
  missing=1
fi
if [ "$missing" -eq 1 ]; then
  echo
  log_warning "Install the missing dependencies before continuing."
  echo "https://github.com/RogueOneEcho/caesura/blob/main/docs/DEPENDENCIES.md"
  exit 1
fi

log_info "Detecting platform"
arch=$(uname -m)
os=$(uname -s)
case "$os" in
  Linux)
    if ldd --version 2>&1 | grep -qi musl; then
      log_debug "musl libc detected"
      target="${arch}-unknown-linux-musl"
    else
      ldd_output=$(ldd --version 2>&1 || true)
      glibc_version=$(echo "$ldd_output" | head -1 | grep -oE '[0-9]+\.[0-9]+$' || echo "0.0")
      glibc_required="2.39"
      log_debug "glibc version: $glibc_version"
      if printf '%s\n%s\n' "$glibc_required" "$glibc_version" | sort -V -C; then
        log_debug "Using gnu"
        target="${arch}-unknown-linux-gnu"
      else
        log_debug "Using musl as glibc version is less than $glibc_required"
        target="${arch}-unknown-linux-musl"
      fi
    fi
    ;;
  Darwin)
    case "$arch" in
      arm64) arch="aarch64" ;;
    esac
    target="${arch}-apple-darwin"
    ;;
  *)
    log_error "Unsupported platform: $os"
    exit 1
    ;;
esac
log_debug "Target: $target"

log_info "Identifying latest release"
tag=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep '"tag_name"' | head -1 | cut -d'"' -f4)
version="${tag#v}"
log_debug "Version: $version"

log_info "Downloading release"
asset="caesura-${version}-${target}.tar.xz"
url="https://github.com/$REPO/releases/download/$tag/$asset"
log_debug "$url"
tmpdir=$(mktemp -d)
curl -fSL --progress-bar -o "$tmpdir/$asset" "$url"

log_info "Installing to $INSTALL_DIR"
tar -xJf "$tmpdir/$asset" -C "$tmpdir"
mkdir -p "$INSTALL_DIR"
chmod +x "$tmpdir/caesura"
mv "$tmpdir/caesura" "$INSTALL_DIR/caesura"
log_debug "Installed to $INSTALL_DIR/caesura"
log_debug "To clean up temporary files: rm -rf $tmpdir"

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
  echo
  log_warning "$INSTALL_DIR is not on your PATH"
  log_warning "Add the following to your shell profile:"
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

log_info "Verifying installation"
log_debug "---"
if "$INSTALL_DIR/caesura" --version; then
  log_debug "---"
  log_success "Installation successful!"
else
  log_debug "---"
  log_error "Installation may have failed. Try running: $INSTALL_DIR/caesura --version"
  exit 1
fi
