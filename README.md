# hfm-tools

> Two keyboard-driven sorters. **FileSorter** empties your Downloads folder. **Inbox Triage** empties the Braincave inbox.

They share the preview code, the undo stack and the Johnny Decimal models, but they solve different problems and are used differently. Downloads is a pile of files you route in one pass. The vault inbox is 2600 notes you drain fifteen minutes at a time, with Hoggle doing the lookup work overnight in between.

---

# Inbox Triage — the Braincave pipeline

## Why it is shaped like this

The obvious design is "let Hoggle sort the inbox automatically". That ran nightly until July 2026 and was switched off deliberately. It had moved 38 notes out of 2657, and worse, Jelle had stopped trusting the result: **a misfiled note in `d1`/`d5`/`d6` is worse than an unsorted one, because it is silently wrong in a place you rely on.**

So the work is split by who is good at what. You make every judgement call. Hoggle does the lookup — reading 168 category descriptions and remembering which project folders already exist — which is the part that is slow by hand and easy for a model.

**Nothing moves until you have chosen a complete Hopsakee.Decimal number.**

## The loop

```
       you, 15 min            overnight              you, 2 min           deterministic
    ┌────────────────┐   ┌─────────────────┐   ┌──────────────────┐   ┌──────────────┐
    │ 1. triage      │──▶│ 2. propose      │──▶│ 3. pick          │──▶│ 4. file      │
    │ keep / delete  │   │ 1-3 candidate   │   │ press 1, 2 or 3  │   │ obsidian     │
    │ + domain/area  │   │ complete numbers│   │                  │   │ move         │
    └────────────────┘   └─────────────────┘   └──────────────────┘   └──────────────┘
```

Every step is resumable. Stop after six notes; the next run picks up at note seven.

## Daily use

```bash
cd ~/Code/hfm-tools

# 1. Triage — the only step that takes real time
uv run python -m filesorter.inbox_app --folder Phone --limit 20

# 2. Nothing. The nightly proposes at 02:10.

# 3. Pick from what it proposed
uv run python -m filesorter.inbox_app --pick

# 4. File everything that now has a complete number
uv run python -m filesorter.inbox_app --file          # look first
uv run python -m filesorter.inbox_app --file --yes    # then move

# Whenever: actually delete what you marked with `d`
uv run python -m filesorter.inbox_app --drain --yes
```

Leave off `--folder` to work the whole inbox in priority order: Phone, Hoggle, NewNotes, Notes, Readwise, Snipd, Atlas, Sources, Omnivore, zz_NoteStationDumb.

## Quick commands

`inbox` is on your PATH (a symlink to `inbox.sh` in this repo), so these work from anywhere:

```bash
inbox                 # triage the whole inbox, in priority order
inbox phone 20        # triage one source folder, stop after 20
inbox pick            # choose from the proposals the nightly wrote
inbox file            # list what is ready to move — moves nothing
inbox file yes        # actually move it
inbox drain           # list notes queued for deletion
inbox drain yes       # actually delete them (OS trash, recoverable)
inbox status          # counts for all three queues
inbox help
```

Anything that changes the vault needs the literal word `yes`. `tmux_sort.sh` is the
equivalent launcher for the Downloads FileSorter.

## Triage keys

| Key | What it does |
|-----|--------------|
| `h` | **Keep.** Then pick a `note-status` from your own vault list, a domain, and optionally an area. Writes `note-status:` and a partial `hd:`. Does not move the note. |
| `d` | **Delete.** Queued, not performed — nothing is removed until `--drain --yes`. |
| `t` | **Too hard right now.** Appends `- [ ] Organise this note [15m] ⏳ <tomorrow>` to the note, so it turns up in your daily plan. |
| `s` | Skip. Comes back next session — that is the difference between `s` and `t`. |
| `u` | Undo. Restores the note byte for byte. |
| `o` | Open in Obsidian. |
| `q` | Quit. Everything already decided is saved. |

The left panel shows the **inbound link count**. A note other notes link to is connected, and deleting it breaks something — that number is the main reason not to delete on reflex.

## What the numbers mean

`d1.53.12` is four things in three parts: domain `d1`, area `5`, category `53`, item `12`. The area is the category's first digit, not a segment of its own, which is why `d1.5` is a valid halfway value — it is a truncated `d1.53`.

An **item id is a group, not a note.** `d6.75.04` is the folder `Hoggle_d6.75.04`, and every note about that project shares it. Most notes join a group that already exists; a new id is only for a genuinely new project, book or topic. New group folders are always `Label_dX.CC.II` with an underscore.

## Status

```bash
uv run python -m filesorter.inbox_app --file    # what is ready, what is blocked
```

Three queues, and a note is in exactly one:

- **awaiting triage** — you have not said keep or delete yet
- **awaiting a proposal** — kept, `hd:` still partial, the nightly will get to it
- **complete `hd:`** — ready to file, or blocked on a label for a new group

---

# FileSorter — the Downloads folder

```bash
uv run python -m filesorter                       # ~/Downloads
uv run python -m filesorter --source ~/somewhere
```

| Key | Action |
|-----|--------|
| `r` | move to `sorted/to-read/` |
| `f` | move to a Johnny Decimal category under `sorted/filesystem/` |
| `b` | move to `sorted/braincave/` |
| `d` | delete permanently |
| `s` / `u` / `q` | skip / undo / quit |

Files land in a `sorted/` staging area inside the source folder. Domain data comes from `config/d*.json` — swap the JSON, no code change.

> **FileSorter and Inbox Triage read different structure files on purpose.** FileSorter uses the static `config/*.json`; Inbox Triage uses `~/.claude/skills/_HD/hd-structure.json`, which is rebuilt from the live vault every night and is the only authoritative source for anything touching Braincave.

---

## Where the pieces live

| Piece | Where | Why there |
|-------|-------|-----------|
| Both TUIs, filing logic | this repo | personal CLI tools, and they need no LLM |
| The overnight proposer | `~/.claude/skills/_BRAINCAVE_INBOX_SORT/Tools/ProposeHd.py` | it calls `Inference.ts`, which is PAI's |
| Nightly trigger | `run-braincave-nightly.sh` step 6 | after step 2.5 refreshes the structure cache |
| Decision ledger | `~/.claude/PAI/MEMORY/LEARNING/hd-choices.jsonl` | one line per verdict |

The proposer imports `filesorter/inbox.py` directly — that module is stdlib-only, so it needs no virtualenv. The contract between the two repos is the vault's frontmatter and nothing else.

## The ledger, and what it is for

Every verdict appends one line: what was proposed, what you chose, and whether your choice was among the candidates.

That exists for one reason. When you keep overriding a category, the category is not the problem — **its description is.** The descriptions live in your vault MOCs (`! 44 Persoonlijke productiviteit.md`), `BuildCache` folds them into `hd-structure.json` every night, and the proposer reads them. So a bad description quietly produces bad proposals forever, and a fixed one improves every future proposal.

Reading the ledger to find those descriptions is the last unbuilt piece. It needs a few hundred picks before the pattern is real rather than noise, so it stays unbuilt on purpose.

## Development

nbdev. Source notebooks in `nbs/`; `filesorter/` is generated.

```bash
uv run nbdev-export     # notebooks → .py
uv run nbdev-test       # run all notebooks
uv run nbdev-prepare    # export + test + clean + readme
```

Note the **hyphens** — nbdev 3.x renamed these from the underscore forms. `nbdev-readme` currently fails on a quarto worker that cannot import the package; the rest pass.

**Never edit `.py` files in `filesorter/` directly** — edit the notebook in `nbs/`. Same for this README: its source is `nbs/index.ipynb`.
