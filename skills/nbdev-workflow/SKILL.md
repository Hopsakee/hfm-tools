---
name: nbdev-workflow
description: Use for all library code creation and modification in nbdev notebook-driven development projects.
---

# nbdev Notebook-Driven Development

## The golden rule

**Source of truth = Jupyter notebooks in `nbs/`.** The `.py` files in the package directory are auto-generated. NEVER edit them directly.

## Notebook structure

### New notebook setup

```python
# Cell 1 (code):
#| default_exp module_name

# Cell 2 (markdown):
# Module Title
# > Brief description of what this module does.

# Cell 3 (code, exported):
#| export
from __future__ import annotations
import json
from fastlite import *
from fastcore.test import *
# ... other imports

# Cell 4+ (code, exported):
#| export
class MyClass:
    ...

# Cell 5 (test, NOT exported):
test_eq(MyClass(...).field, expected)

# Cell 6 (markdown):
# Explanation of the next section...
```

### Cell directives reference

| Directive | Purpose |
|---|---|
| `#\| default_exp module` | Declares target module (first cell only) |
| `#\| export` | Export cell to module + add to `__all__` |
| `#\| exporti` | Export but don't add to `__all__` (internal) |
| `#\| hide` | Hide from documentation |
| `#\| eval: false` | Don't execute during `nbdev_test` |

### Naming convention

- `00_first_module.ipynb` — numbered prefix for ordering
- `01_second_module.ipynb`
- `index.ipynb` — generates README.md

## Commands

```bash
uv run nbdev_export     # Notebooks → .py modules
uv run nbdev_test       # Run all notebook tests in parallel
uv run nbdev_clean      # Clean notebook metadata for git
uv run nbdev_prepare    # All of the above + nbdev_readme
```

### Troubleshooting export

- **`nbdev_export` not found / "No such file or directory"**: The `nbdev_export` script may not be on PATH even when nbdev is installed. Use `uv run python -m nbdev.export` as a fallback.
- **`settings.ini` is required**: nbdev reads project settings from `settings.ini` in the project root, NOT from `[tool.nbdev]` in `pyproject.toml`. If `settings.ini` is missing, export runs without error but **silently produces no output**. Always ensure `settings.ini` exists with at minimum:
  ```ini
  [DEFAULT]
  lib_name = your_package
  lib_path = your_package
  nbs_path = nbs
  ```
- **Export runs but `.py` files don't update**: This almost always means `settings.ini` is missing or has wrong paths. Check that `lib_path` matches the package directory and `nbs_path` matches the notebooks directory.
- **When export doesn't work, update both files**: Edit the notebook (source of truth) AND the generated `.py` file to keep them in sync. Fix the export issue separately so future exports work correctly.

## Git commit workflow

1. `uv run nbdev_prepare`
2. `git add` the relevant files
3. `git commit` — if hooks modify notebooks, re-stage and retry
4. Never bypass or disable nbdev hooks
5. Never manually clean notebook metadata

## Testing with fastcore.test

```python
from fastcore.test import *

test_eq(result, expected)           # Assert equality
test_ne(a, b)                       # Assert not equal
test_close(a, b, eps=1e-5)          # Assert close (floats)
test_fail(lambda: bad_func())       # Assert raises exception
test_is(a, b)                       # Assert identity (is)
```

Tests go in regular notebook cells WITHOUT the `#| export` directive. They:
- Run during `nbdev_test`
- Appear in documentation
- Do NOT get exported to the `.py` module

## Documentation style

Use `docments` — comments right after parameters:

```python
#| export
def process_items(
    items: list,           # List of items to process
    max_count: int = 10,   # Maximum items to return
    verbose: bool = False, # Print progress information
) -> list:
    """Process `items` up to `max_count`, optionally with `verbose` output."""
    ...
```

## What code goes in notebooks vs. `main.py`

| In notebooks (`nbs/`) | In `main.py` |
|---|---|
| Data model classes (Pydantic) | App setup (`fast_app`, theme) |
| Database utilities | Route handlers (`@rt`) |
| Business logic & algorithms | UI helpers used only in routes |
| Visualization code | Form builders & form save logic |
| Shared utility functions | Navigation components |
| All tests | `serve()` call |

## Pre-commit hooks

The `.pre-commit-config.yaml` should include:

```yaml
repos:
- repo: https://github.com/fastai/nbdev
  rev: 2.2.10
  hooks:
  - id: nbdev_clean
  - id: nbdev_export
```

## Documentation to consult

Read `aicontext/nbdev.md` for overview and follow links for:
- Getting started guide
- Best practices tutorial
- Pre-commit hooks setup
- Modular nbdev usage
