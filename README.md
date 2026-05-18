# FileSorter

Keyboard-driven TUI file sorter with Johnny Decimal support. Review files one at a time with a content preview, then route them to a flat "to-read" folder or a hierarchical Johnny Decimal folder structure — all within a `sorted/` staging area.

## Installation

```bash
uv sync
```

## Usage

Sort your Downloads folder (default):

```bash
uv run python -m filesorter
```

Sort a different directory:

```bash
uv run python -m filesorter --source ~/Documents/unsorted
```

Use a custom config file:

```bash
uv run python -m filesorter --config path/to/config.yaml
```

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `r` | Move file to `sorted/to-read/` |
| `f` | Move file to a Johnny Decimal category in `sorted/filesystem/` |
| `d` | Permanently delete file |
| `s` | Skip file |
| `u` | Undo last action |
| `q` | Quit |

## How it works

1. FileSorter scans the source directory for unsorted files
2. Each file is shown one at a time with metadata (name, type, size, date) and a content preview
3. Press a key to route the file to the right destination
4. When pressing `f`, select a domain and then a category from the Johnny Decimal structure
5. Files are moved into `sorted/` inside the source directory

## Johnny Decimal configuration

Domain/category data is loaded from JSON files in the `config/` directory. To update the folder structure, replace or edit the JSON files — no code changes needed.

## Development

This project uses **nbdev** for notebook-driven development. Source notebooks live in `nbs/`; the `filesorter/` package is auto-generated.

```bash
uv run nbdev_export     # Export notebooks → .py modules
uv run nbdev_test       # Run all tests
uv run nbdev_prepare    # Export + test + clean + readme
```

**Never edit `.py` files in `filesorter/` directly** — edit the corresponding notebook in `nbs/` instead.
