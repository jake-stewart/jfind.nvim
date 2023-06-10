#!/bin/bash
set -e

MAX_WIDTH="$1"
MAX_HEIGHT="$2"
DISABLE_CURSOR='echo "\x1b[?25l"'

client_width=$(tmux display -p "#{client_width}")
client_height=$(tmux display -p "#{client_height}")

fullscreen() {
    width="$client_width"
    height="$client_height"
    border="-B"
}

if ((client_width > MAX_WIDTH)); then
    width=$((client_width % 2 ? MAX_WIDTH - 1 : MAX_WIDTH))
    if ((client_height > MAX_HEIGHT)); then
        height=$(((client_height % 2) ? MAX_HEIGHT - 1 : MAX_HEIGHT))
    else
        fullscreen
    fi
else
    fullscreen
fi

shift
shift

tmux display-popup \
    -w "$width" \
    -h $((height - 1)) \
    -x $(((client_width - width) / 2)) \
    -E \
    -d "$(pwd)" \
    $border \
    "$@"

