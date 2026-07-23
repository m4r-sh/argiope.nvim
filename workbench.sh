#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEPS="$SCRIPT_DIR/.deps"
STATE="$SCRIPT_DIR/.workbench"
NVIM=${NVIM_BIN:-}

if [ -z "$NVIM" ]; then
  NVIM=$(command -v nvim12 2>/dev/null || command -v nvim 2>/dev/null || true)
fi
if [ -z "$NVIM" ] || [ ! -x "$NVIM" ]; then
  echo "argiope: set NVIM_BIN to an executable Neovim 0.12+ binary" >&2
  exit 1
fi

NEEDS_BOOTSTRAP=0
for LANGUAGE in javascript html css markdown markdown_inline; do
  if [ ! -f "$DEPS/runtime/parser/$LANGUAGE.so" ]; then
    NEEDS_BOOTSTRAP=1
  fi
done
if [ ! -d "$DEPS/nvim-treesitter" ]; then
  NEEDS_BOOTSTRAP=1
fi

if [ "$NEEDS_BOOTSTRAP" -eq 1 ]; then
  (
    cd "$SCRIPT_DIR"
    bun run deps
  )
fi
if [ ! -f "$SCRIPT_DIR/lua/argiope/generated/palette.lua" ]; then
  (
    cd "$SCRIPT_DIR"
    bun run palette
  )
fi

mkdir -p \
  "$STATE/data" \
  "$STATE/state" \
  "$STATE/cache"

exec env \
  ARGIOPE_ROOT="$SCRIPT_DIR" \
  XDG_CONFIG_HOME="$SCRIPT_DIR" \
  XDG_DATA_HOME="$STATE/data" \
  XDG_STATE_HOME="$STATE/state" \
  XDG_CACHE_HOME="$STATE/cache" \
  NVIM_APPNAME="workbench" \
  "$NVIM" -u "$SCRIPT_DIR/workbench/init.lua" "$@"
