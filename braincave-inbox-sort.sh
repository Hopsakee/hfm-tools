#!/usr/bin/env bash
# Launch Inbox Triage TUI in a tmux session that Amp/Hoggle can interact with.
# Companion to folder-sort.sh (which launches the Downloads FileSorter) — same pattern, for the
# Braincave inbox instead. Unlike `inbox.sh` (foreground, blocks the calling shell), this starts
# a detached session an agent can attach to and send keys into.
# Usage: ./braincave-inbox-sort.sh [folder] [limit]
#   ./braincave-inbox-sort.sh              whole inbox, priority order
#   ./braincave-inbox-sort.sh Phone        one source folder
#   ./braincave-inbox-sort.sh Phone 20     ... and stop after 20 notes

SESSION="inbox_triage"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOLDER="${1:-}"
LIMIT="${2:-}"

# Kill existing session if any
tmux kill-session -t "$SESSION" 2>/dev/null

CMD="cd '$REPO' && uv run python -m filesorter.inbox_app"
[ -n "$FOLDER" ] && CMD="$CMD --folder '$FOLDER'"
[ -n "$LIMIT" ] && CMD="$CMD --limit '$LIMIT'"
CMD="$CMD; echo 'Press Enter to close'; read"

# Start new detached session running the TUI
tmux new-session -d -s "$SESSION" -x 120 -y 40 "$CMD"

echo "Inbox Triage running in tmux session '$SESSION'"
echo "  Attach:  tmux attach -t $SESSION"
echo "  Send keys:  tmux send-keys -t $SESSION <key>"
