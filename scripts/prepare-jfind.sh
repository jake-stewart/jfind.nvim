#!/bin/bash
set -e

CACHE="$XDG_CACHE_HOME"
test -z "$CACHE" && CACHE="$HOME/.cache"
mkdir -p "$CACHE"
OUT="$CACHE/jfind_out"
[ -f "$OUT" ] && rm "$OUT"

SCRIPT="$1"
FLAGS="$2"
shift
shift
"$SCRIPT" "$@" | jfind $FLAGS > "$OUT" && exit 0

echo "An error ocurred. Press Enter to continue"
read
exit 1
