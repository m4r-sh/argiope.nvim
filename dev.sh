#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEPS="$SCRIPT_DIR/.deps"
NVIM=${NVIM_BIN:-}

if [ -z "$NVIM" ]; then
  NVIM=$(command -v nvim12 2>/dev/null || command -v nvim 2>/dev/null || true)
fi
if [ -z "$NVIM" ] || [ ! -x "$NVIM" ]; then
  echo "argiope: set NVIM_BIN to an executable Neovim 0.12+ binary" >&2
  exit 1
fi

(
  cd "$SCRIPT_DIR"
  bun run deps
  bun run palette
)

mkdir -p \
  "$DEPS/dev-xdg/config" \
  "$DEPS/dev-xdg/data" \
  "$DEPS/dev-xdg/state" \
  "$DEPS/dev-xdg/cache"

if [ "$#" -eq 0 ]; then
  set -- "$SCRIPT_DIR/tests/fixtures/integration/zilk-ui.js"
fi

exec env \
  ARGIOPE_ROOT="$SCRIPT_DIR" \
  XDG_CONFIG_HOME="$DEPS/dev-xdg/config" \
  XDG_DATA_HOME="$DEPS/dev-xdg/data" \
  XDG_STATE_HOME="$DEPS/dev-xdg/state" \
  XDG_CACHE_HOME="$DEPS/dev-xdg/cache" \
  NVIM_APPNAME="argiope-dev" \
  "$NVIM" -n -i NONE -u "$SCRIPT_DIR/dev/init.lua" "$@"
