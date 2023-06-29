#!/bin/bash
set -e

CACHE="$XDG_CACHE_HOME"
test -z "$CACHE" && CACHE="$HOME/.cache"
mkdir -p "$CACHE"
OUT="$CACHE/jfind_out"
[ -f "$OUT" ] && rm "$OUT"

SCRIPT="$1"
COMMAND="$2"
QUERY="$3"
PREVIEW="$4"
PREVIEW_LINE="$5"
HISTORY="$6"
FLAGS="$7"

shift
shift
shift
shift
shift
shift
shift

if [ -n "$COMMAND" ]; then
    jfind $FLAGS --query="$QUERY" --preview="$PREVIEW" --preview-line="$PREVIEW_LINE" --history="$HISTORY" --command="$COMMAND" > "$OUT" && exit 0
else
    "$SCRIPT" "$@" | jfind --query="$QUERY" --preview="$PREVIEW" --history="$HISTORY" --preview-line="$PREVIEW_LINE" $FLAGS > "$OUT" && exit 0
fi

echo "An error ocurred. Press Enter to continue"
read
exit 1
