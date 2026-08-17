#!/usr/bin/env bash
# Braincave inbox sorter — the four-stage pipeline, one short command per stage.
# Companion to folder-sort.sh (which launches the Downloads FileSorter).
#
# Usage:
#   inbox                    triage the whole inbox, in priority order
#   inbox phone              triage one source folder
#   inbox phone 20           ... and stop after 20 notes
#   inbox pick               choose from the proposals the nightly wrote
#   inbox file               list what is ready to move (moves nothing)
#   inbox file yes           actually move it
#   inbox drain              list notes queued for deletion
#   inbox drain yes          actually delete them (to OS trash, recoverable)
#   inbox status             counts for all three queues
#
# Runs from anywhere: it cd's into the repo itself.

set -uo pipefail

REPO="$HOME/Code/hfm-tools"
RUN=(uv run --project "$REPO" python -m filesorter.inbox_app)

if [ ! -d "$REPO" ]; then
  echo "hfm-tools not found at $REPO" >&2
  exit 1
fi
cd "$REPO" || exit 1

cmd="${1:-triage}"

case "$cmd" in
  -h|--help|help)
    # Print the leading comment block, stopping at the first line of real code.
    awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "$0"
    ;;

  pick)
    "${RUN[@]}" --pick
    ;;

  file)
    # Dry by default. Only the literal word `yes` moves anything.
    if [ "${2:-}" = "yes" ]; then "${RUN[@]}" --file --yes; else "${RUN[@]}" --file; fi
    ;;

  drain)
    if [ "${2:-}" = "yes" ]; then "${RUN[@]}" --drain --yes; else "${RUN[@]}" --drain; fi
    ;;

  status)
    uv run --project "$REPO" python - <<'PY'
from collections import Counter
from filesorter.inbox import (INBOX, hd_structure_age_days, load_hd_folders, needs_proposal,
                              pending_candidates, plan_filing, ready_to_file)

pending, decided = pending_candidates()
awaiting, filable = needs_proposal(), ready_to_file()
plans = [plan_filing(n, h, load_hd_folders()) for n, h in filable]

print(f"{len(pending):>6}  awaiting triage")
print(f"{len(awaiting):>6}  awaiting a proposal")
print(f"{len(filable):>6}  carry a complete hd:")
for kind, n in sorted(Counter(p.kind for p in plans).items()):
    print(f"{n:>10}  {kind}")
print(f"{decided:>6}  already decided")
print(f"\nstructure cache is {hd_structure_age_days():.1f} days old")

counts = Counter(p.relative_to(INBOX).parts[0] for p in pending)
print("\nawaiting triage, by source folder:")
for folder, n in counts.most_common():
    print(f"  {n:>5}  {folder}")
PY
    ;;

  triage)
    "${RUN[@]}"
    ;;

  *)
    # Anything else is treated as a source folder name, with an optional limit.
    # `inbox phone 20` is the shape actually used day to day.
    if [ -n "${2:-}" ]; then "${RUN[@]}" --folder "$cmd" --limit "$2"
    else "${RUN[@]}" --folder "$cmd"; fi
    ;;
esac
