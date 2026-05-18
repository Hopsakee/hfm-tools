#!/usr/bin/env bash
# Launch FileSorter TUI in a tmux session that Amp can interact with.
# Usage: ./tmux_sort.sh [source_dir]

SESSION="filesorter"
SOURCE="${1:-$HOME/Downloads}"

# Kill existing session if any
tmux kill-session -t "$SESSION" 2>/dev/null

# Start new detached session running the TUI
tmux new-session -d -s "$SESSION" -x 120 -y 40 \
    "cd $(pwd) && uv run python -m filesorter --source '$SOURCE'; echo 'Press Enter to close'; read"

echo "FileSorter running in tmux session '$SESSION'"
echo "  Attach:  tmux attach -t $SESSION"
echo "  Send keys:  tmux send-keys -t $SESSION <key>"
