#!/bin/bash
set -e

CACHE="$XDG_CACHE_HOME"
test -z "$CACHE" && CACHE="$HOME/.cache"
mkdir -p "$CACHE"
OUT="$CACHE/jfind_out"
[ -f "$OUT" ] && rm "$OUT"

SCRIPT="$1"
COMMAND="$2"
PREVIEW="$3"
PREVIEW_LINE="$4"
FLAGS="$5"

shift
shift
shift
shift
shift

if [ -n "$COMMAND" ]; then
    jfind $FLAGS --preview="$PREVIEW" --preview-line="$PREVIEW_LINE" --command="$COMMAND" > "$OUT" && exit 0
else
    "$SCRIPT" "$@" | jfind --preview="$PREVIEW" --preview-line="$PREVIEW_LINE" $FLAGS > "$OUT" && exit 0
fi

echo "An error ocurred. Press Enter to continue"
read
exit 1
