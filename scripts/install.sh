#!/usr/bin/env bash
# scripts/install.sh
# Install r2j from a GitHub Release tarball.
# Usage:
#   ./scripts/install.sh                # install latest
#   ./scripts/install.sh 0.1.0          # install v0.1.0
#   INSTALL_DIR=~/.local/bin ./scripts/install.sh
#   REPO=yonigofman/r2j ./scripts/install.sh
#   ./scripts/install.sh --no-verify    # skip checksum verification

set -euo pipefail

# -------- Config --------
REPO="${REPO:-yonigofman/r2j}"   # <-- change default to your actual repo
NAME="${NAME:-r2j}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
VERIFY=1

# -------- Args --------
VER="${1:-latest}"
if [[ "${VER}" == "--no-verify" ]]; then
  VERIFY=0
  VER="latest"
elif [[ "${VER:-}" == -* ]]; then
  case "$VER" in
    --no-verify) VERIFY=0; VER="latest" ;;
    -h|--help)
      sed -n '1,40p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown flag: $VER" >&2
      exit 1
      ;;
  esac
fi

# -------- Helpers --------
have() { command -v "$1" >/dev/null 2>&1; }

fetch() {
  # fetch URL -> stdout (prefers curl)
  if have curl; then
    curl -fsSL "$1"
  elif have wget; then
    wget -qO- "$1"
  else
    echo "Error: need curl or wget" >&2
    exit 1
  fi
}

download() {
  # download URL to file
  local url="$1" out="$2"
  if have curl; then
    curl -fsSL -o "$out" "$url"
  else
    wget -qO "$out" "$url"
  fi
}

is_writable_dir() {
  local dir="$1"
  [[ -d "$dir" && -w "$dir" ]]
}

sha256_check() {
  local file="$1" sumfile="$2"
  if have sha256sum; then
    (cd "$(dirname "$sumfile")" && sha256sum --check "$(basename "$sumfile")")
  elif have shasum; then
    # Expect sumfile contains "HASH  filename"
    local calc
    calc="$(shasum -a 256 "$file" | awk '{print $1}')"
    local ref
    ref="$(awk '{print $1}' "$sumfile")"
    if [[ "$calc" != "$ref" ]]; then
      echo "Checksum mismatch: $file" >&2
      echo " expected: $ref" >&2
      echo "   actual: $calc" >&2
      return 1
    fi
  else
    echo "Warning: no sha256 tool found; skipping verification." >&2
    return 0
  fi
}

resolve_latest_version() {
  # returns X.Y.Z (no leading v)
  local tag
  tag="$(fetch "https://api.github.com/repos/${REPO}/releases/latest" | \
    sed -n 's/.*"tag_name":[[:space:]]*"\(v\)\?\([0-9]\+\.[0-9]\+\.[0-9]\+\)".*/\2/p' | head -n1)"
  if [[ -z "$tag" ]]; then
    echo "Error: could not resolve latest version from GitHub API for $REPO" >&2
    exit 1
  fi
  echo "$tag"
}

# -------- Decide version --------
if [[ "$VER" == "latest" ]]; then
  VER="$(resolve_latest_version)"
else
  VER="${VER#v}" # strip leading v if provided
fi

TAG="v${VER}"
TARBALL="${NAME}-${VER}.tar.gz"
SUMFILE="${NAME}-${VER}.sha256"

ASSET_URL_BASE="https://github.com/${REPO}/releases/download/${TAG}"
TAR_URL="${ASSET_URL_BASE}/${TARBALL}"
SUM_URL="${ASSET_URL_BASE}/${SUMFILE}"

# -------- Download & verify --------
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "→ Downloading ${NAME} ${TAG} from ${REPO} …"
download "$TAR_URL" "$tmpdir/$TARBALL"

if [[ "$VERIFY" -eq 1 ]]; then
  echo "→ Downloading checksum …"
  if download "$SUM_URL" "$tmpdir/$SUMFILE"; then
    echo "→ Verifying checksum …"
    sha256_check "$tmpdir/$TARBALL" "$tmpdir/$SUMFILE"
  else
    echo "Warning: checksum file not found for ${TAG}; proceeding without verification." >&2
  fi
else
  echo "⚠️  Skipping checksum verification by user request."
fi

# -------- Extract --------
echo "→ Extracting …"
tar -xzf "$tmpdir/$TARBALL" -C "$tmpdir"

# Expected layout: r2j-VERSION/bin/r2j
SRC_BIN="$tmpdir/${NAME}-${VER}/bin/${NAME}"
if [[ ! -f "$SRC_BIN" ]]; then
  echo "Error: extracted binary not found at $SRC_BIN" >&2
  exit 1
fi
chmod +x "$SRC_BIN"

# -------- Install --------
# If INSTALL_DIR not writable, fallback to ~/.local/bin
if ! is_writable_dir "$INSTALL_DIR"; then
  if [[ -d "$INSTALL_DIR" ]]; then
    echo "ℹ️  $INSTALL_DIR not writable. Will attempt sudo install."
    USE_SUDO=1
  else
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    USE_SUDO=0
    echo "ℹ️  Using user install: $INSTALL_DIR"
  fi
else
  USE_SUDO=0
fi

echo "→ Installing to $INSTALL_DIR/${NAME} …"
if [[ "$USE_SUDO" -eq 1 ]]; then
  if have sudo; then
    sudo install -m 0755 "$SRC_BIN" "$INSTALL_DIR/${NAME}"
  else
    echo "Error: need write access to $INSTALL_DIR or 'sudo' available" >&2
    exit 1
  fi
else
  install -m 0755 "$SRC_BIN" "$INSTALL_DIR/${NAME}"
fi

# -------- Post-install message --------
echo "✅ Installed: ${INSTALL_DIR}/${NAME}"
if ! command -v "${NAME}" >/dev/null 2>&1; then
  echo
  echo "⚠️  '${NAME}' is not on your PATH yet."
  echo "   Add this to your shell rc (e.g. ~/.bashrc or ~/.zshrc):"
  echo "     export PATH=\"$INSTALL_DIR:\$PATH\""
  echo
fi

echo "Run: ${NAME} --help"
