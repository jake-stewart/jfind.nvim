#!/bin/bash
set -e

OUTPUT="$HOME/.cache/jfind_out"
[ -f "$OUTPUT" ] && rm "$OUTPUT"

command_exists() {
    type "$1" &> /dev/null
}

list_files() {
    command_exists fd && fd_command="fd"
    command_exists fdfind && fd_command="fdfind"

    if [ -n "$fd_command" ]; then
        exclude=$(cat "$HOME/.cache/jfind_excludes" \
            | sed "s/'/'\"'\"'/g" | awk "{printf \" -E '%s'\", "'$0}')
        (cd "$1" && eval "$fd_command -a --type f $exclude")
    else
        find "$1" -type f
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

jfind_command() {
    jfind --hints --select-hint
}

[ -n "$root" ] && root="$1" || root=$(pwd)

root=${root//\~/$HOME}
root=${root//\$HOME/$HOME}

list_files "$root" | format_files | jfind_command "$root" | tee "$OUTPUT"
