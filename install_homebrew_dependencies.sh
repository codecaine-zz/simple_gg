#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"
OPTIONAL_BREWFILE="$SCRIPT_DIR/Brewfile.optional"
INCLUDE_OPTIONAL=0

usage() {
  echo "Usage: ./install_homebrew_dependencies.sh [--optional|--help]"
  echo
  echo "Installs the required Homebrew dependencies for simple_gg."
  echo "Use --optional to also install cross-compilation toolchains such as zig and mingw-w64."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --optional|--all)
      INCLUDE_OPTIONAL=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed or not on PATH."
  echo "Install it from: https://brew.sh/"
  exit 1
fi

if [[ ! -f "$BREWFILE" ]]; then
  echo "Brewfile not found at: $BREWFILE"
  exit 1
fi

if [[ "$INCLUDE_OPTIONAL" -eq 1 && ! -f "$OPTIONAL_BREWFILE" ]]; then
  echo "Optional Brewfile not found at: $OPTIONAL_BREWFILE"
  exit 1
fi

if [[ "$INCLUDE_OPTIONAL" -eq 1 ]]; then
  echo "Installing required simple_gg dependencies plus optional cross-compilation toolchains..."
else
  echo "Installing required simple_gg dependencies with Homebrew..."
fi

echo "Homebrew may prompt for system security approval or Xcode/CLT confirmation."
echo "This installer will auto-confirm those prompts to avoid hanging."

export CI=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

brew update

BUNDLE_ARGS=("bundle")
BUNDLE_ARGS+=("--file" "$BREWFILE")
if [[ "$INCLUDE_OPTIONAL" -eq 1 ]]; then
  BUNDLE_ARGS+=("--file" "$OPTIONAL_BREWFILE")
fi

# Auto-confirm common Homebrew security prompts such as "Proceed with installation?".
if ! yes | brew "${BUNDLE_ARGS[@]}"; then
  echo "Homebrew installation failed." >&2
  exit 1
fi

echo "Homebrew installation completed successfully."
if [[ "$INCLUDE_OPTIONAL" -eq 0 ]]; then
  echo "Optional cross-compilers were skipped. To include them, run:"
  echo "  ./install_homebrew_dependencies.sh --optional"
fi
