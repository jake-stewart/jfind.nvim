SCRIPT_DIR=$(dirname "$0")

disable_cursor='echo "\x1b[?25l"'
"$SCRIPT_DIR/tmux-popup.sh" \
    "$disable_cursor; $SCRIPT_DIR/jfind-file.sh; $disable_cursor"
