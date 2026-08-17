#!/usr/bin/env bash
# Launch FileSorter TUI in a tmux session that Amp/Hoggle can interact with.
# Companion to braincave-inbox-sort.sh (which launches the Braincave inbox triage).
# Usage: ./folder-sort.sh [source_dir]
#   ./folder-sort.sh                  sort ~/Downloads (default)
#   ./folder-sort.sh ~/some/folder    sort the given folder instead

SESSION="filesorter"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${1:-$HOME/Downloads}"

# Kill existing session if any
tmux kill-session -t "$SESSION" 2>/dev/null

# Start new detached session running the TUI
tmux new-session -d -s "$SESSION" -x 120 -y 40 \
    "cd '$REPO' && uv run python -m filesorter --source '$SOURCE'; echo 'Press Enter to close'; read"

echo "FileSorter running in tmux session '$SESSION'"
echo "  Attach:  tmux attach -t $SESSION"
echo "  Send keys:  tmux send-keys -t $SESSION <key>"
