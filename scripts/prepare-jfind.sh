#!/bin/bash
set -e

CACHE="$XDG_CACHE_HOME"
test -z "$CACHE" && CACHE="$HOME/.cache"
mkdir -p "$CACHE"
OUT="$CACHE/jfind_out"
[ -f "$OUT" ] && rm "$OUT"

"$1" > "$OUT"
