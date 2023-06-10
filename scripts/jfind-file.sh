#!/bin/bash
set -e

CACHE="$XDG_CACHE_HOME"
test -z "$CACHE" && CACHE="$HOME/.cache"
EXCLUDES="$CACHE/jfind_excludes"

command_exists() {
    type "$1" &> /dev/null
}

list_files() {
    command_exists fd && fd_command="fd"
    command_exists fdfind && fd_command="fdfind"

    if [ -n "$fd_command" ]; then
        exclude=$(cat "$EXCLUDES" 2>/dev/null \
            | sed "s/'/'\"'\"'/g" | awk "{printf \" -E '%s'\", "'$0}')
        eval "$fd_command --type f $exclude"
    else
        exclude=$(cat "$EXCLUDES" 2>/dev/null \
            | sed "s/'/'\"'\"'/g" \
            | awk "{printf \" ! -path '*/%s/*' ! -iname '%s'\", "'$0, $0}')
        eval "find '.' -type f $exclude"
    fi
}

format_files() {
    awk '{
        split($0, path_parts, "/");
        num_parts = length(path_parts);
        first = num_parts == 1 ? "" : path_parts[num_parts - 1] "/";
        second = path_parts[length(path_parts)];
        print first second;
        print $0;
    }'
}

if [ "$1" = "true" ]; then
    list_files | format_files
else
    list_files
fi

