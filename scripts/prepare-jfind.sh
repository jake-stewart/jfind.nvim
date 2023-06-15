#!/bin/bash
set -e

CACHE="$XDG_CACHE_HOME"
test -z "$CACHE" && CACHE="$HOME/.cache"
mkdir -p "$CACHE"
OUT="$CACHE/jfind_out"
[ -f "$OUT" ] && rm "$OUT"

SCRIPT="$1"
COMMAND="$2"
FLAGS="$3"
shift
shift
shift

if [ -n "$COMMAND" ]; then
    # echo "[[$COMMAND]]" > ~/jfind-command
    jfind $FLAGS --command="$COMMAND" > "$OUT" && exit 0
else
    "$SCRIPT" "$@" | jfind $FLAGS > "$OUT" && exit 0
fi

echo "An error ocurred. Press Enter to continue"
read
exit 1
