# FileSorter — Application Specification

## 1. PROJECT OVERVIEW

### Problem Statement
You have a large Downloads folder accumulating unsorted files. You need a keyboard-driven TUI tool that shows one file at a time with a content preview, and lets you route it to one of two destinations: a flat "to-read" folder, or a hierarchical Johnny Decimal folder structure across three domains (d1 Private, d5 Work, d6 Programming) — all within a `sorted/` staging area inside the Downloads folder.

### Core Requirements
- Single-file-at-a-time review loop with keyboard shortcuts for all actions
- File preview panel showing first 20 non-empty lines for text/markdown/PDF/DOCX/XLSX, or image filename + open-in-Windows key for images
- Routing destinations: `sorted/to-read/` and `sorted/filesystem/{domain}/{category-id} {category-name}/`
- Full undo support (one level minimum) for misrouted files
- Config-driven domain/category data loaded from swappable JSON files (your three provided files)
- Launchable via a `just sort` recipe

### Success Metrics
- Time to sort a file is under 5 key presses in the most common case
- All files in Downloads folder can be processed in a single session without opening another window
- Category JSON files can be swapped out without modifying application code
- Session survives detach/reattach when run inside tmux

### Stakeholder Analysis
Single user (Jelle). No multi-user concerns. The application must run inside WSL2 (Bash environment on Windows 11), with `explorer.exe`/`cmd.exe` available for opening images in Windows.

***

## 2. TECHNICAL ARCHITECTURE

### Technology Decision: Python TUI with `textual`
**Recommended stack:** Python 3.12+ managed by `uv`, `textual` as the TUI framework, `rich` for styled output, nbdev for development and packaging. This provides:
- Full color TUI with panes, borders, and keybindings — impossible to do cleanly in bash
- Testable modules via nbdev notebook cells
- Clean `just sort` entry point via a `uv run` call
- WSL2 compatibility with `subprocess` calls to `explorer.exe` for Windows image opening

### Module Structure
```
filesorter/
├── nbs/
│   ├── 00_config.ipynb      # Pydantic config models + JSON loader
│   ├── 01_domain.ipynb      # Domain/area/category data models
│   ├── 02_preview.ipynb     # File preview extraction logic
│   ├── 03_sorter.ipynb      # File move + undo logic
│   ├── 04_app.ipynb         # Textual TUI application
│   └── index.ipynb          # Project overview
├── config/
│   ├── d1-Prive.json
│   ├── d5-WDODelta.json
│   └── d6-Programming-Development.json
├── justfile
├── pyproject.toml
└── settings.ini             # nbdev config
```

### Data Models (Pydantic)
```python
class JDItem(BaseModel):
    id: str                  # e.g. "d6.13.01"
    name: str

class JDCategory(BaseModel):
    id: str                  # e.g. "13"
    name: str                # e.g. "Shell and terminals"
    description: str = ""
    tags: list[str] = []
    items: list[JDItem] = []

class JDArea(BaseModel):
    id: str                  # e.g. "10-19"
    name: str
    categories: list[JDCategory]

class JDDomain(BaseModel):
    name: str                # e.g. "d6 Programming-Development"
    domain_id: str           # e.g. "d6"
    areas: list[JDArea]

class AppConfig(BaseModel):
    source_dir: Path         # default: ~/Downloads
    sorted_dir: Path         # default: source_dir / "sorted"
    to_read_dir: Path        # sorted / "to-read"
    filesystem_dir: Path     # sorted / "filesystem"
    domain_config_dir: Path  # config/ directory
    preview_lines: int = 20
    domains: list[JDDomain] = []
```

The domain JSON files are loaded at startup from `config/` by scanning for `d*.json` files, parsing each via `JDDomain`. This means updating domain data = replace JSON file, no code changes.

### Configuration Management
A `config.yaml` file handles runtime settings (paths, preview lines). Pydantic validates all config. The `AppConfig.domain_config_dir` points to the `config/` directory; at startup the loader iterates all JSON files there and extracts the `domain_id` from each file's `"name"` field (e.g. `"d6 Programming-Development"` → `d6`).

***

## 3. TUI LAYOUT DESIGN

The Textual app uses a two-panel layout:

```
┌─────────────────────────────────────────────────────────────┐
│  FileSorter  │  file 7 of 42  │  ~/Downloads                │
├──────────────────────────┬──────────────────────────────────┤
│                          │                                  │
│  CURRENT FILE            │  PREVIEW                         │
│  ─────────────           │  ─────────                       │
│  report_Q1.pdf           │  Quarterly financials report...  │
│  PDF  •  2.3 MB          │  Revenue: €1.2M                  │
│  Modified: 2026-03-20    │  Costs:   €0.8M                  │
│                          │  ...                             │
│                          │                                  │
├──────────────────────────┴──────────────────────────────────┤
│  [r] To Read  [f] FileSystem  [s] Skip  [u] Undo  [q] Quit  │
└─────────────────────────────────────────────────────────────┘
```

When `[f]` is pressed, the bottom panel transforms into a domain selector, then a category selector — all within the same TUI, no new windows:

```
┌─────────────────────────────────────────────────────────────┐
│  SELECT DOMAIN                                              │
│  ─────────────────────────────────────────────────────────  │
│  d1 - Privé                     d5 - WDODelta               │
│  d6 - Programming-Development   [ESC] Cancel                │
└─────────────────────────────────────────────────────────────┘
```

Then after choosing a domain, areas are shown with category numbers typed directly (e.g., press `3` then `4` to select category `34 Cloud platforms`).

***

## 4. DEVELOPMENT ROADMAP

### Phase 1 — Core Infrastructure (nbdev notebooks 00–03)
**Goal:** Working file move logic, testable in isolation

- `00_config.ipynb`: `AppConfig`, `config.yaml` loader, path resolution, create `sorted/` dirs on first run
- `01_domain.ipynb`: `JDDomain`/`JDArea`/`JDCategory` models, JSON loader scanning `config/` dir, unit tests with your three domain files
- `02_preview.ipynb`: Preview extractors per file type:
  - `.txt`, `.md`: read first 20 non-empty lines directly
  - `.pdf`: `pdfplumber` to extract text, filter empty lines, take first 20
  - `.docx`: `python-docx` paragraphs, filter empty, take first 20
  - `.xlsx`: `openpyxl`, first sheet, first N non-empty rows formatted as table
  - images (`.jpg/.png/.gif/.webp/.bmp`): return `(is_image=True, path)` — app calls `subprocess.run(["explorer.exe", path])` on `[o]` key
- `03_sorter.ipynb`: `Sorter` class with `move_file(file, destination)`, `undo()`, `get_files(directory)`, undo stack (deque), session stats

**Validation:** Run each notebook top-to-bottom; test with sample files from actual Downloads folder.

### Phase 2 — TUI Application (notebook 04)
**Goal:** Full interactive session

- `04_app.ipynb`: `textual` App with:
  - `FileInfoPanel` (left): filename, type, size, modified date
  - `PreviewPanel` (right): scrollable, syntax-highlighted with `rich`
  - `ActionBar` (bottom): always visible keybinding hints
  - `DomainSelector` modal: shows domain list dynamically from loaded config
  - `CategorySelector` modal: shows areas + categories from selected domain, search/filter by typing category number or fuzzy name
  - Status bar: file `n of total`, last action message (e.g. "Moved → d6/34 Cloud platforms ✓")

**Validation:** Manual walkthrough with 10 real files from Downloads folder covering all file types.

### Phase 3 — `just` Integration + Packaging
**Goal:** Single command launches everything

`justfile` entry:
```makefile
# Sort files in the downloads folder
sort folder="$HOME/Downloads":
    uv run python -m filesorter.app --source {{folder}}
```

- `pyproject.toml` built by nbdev with `uv` as package manager
- `nbdev_build_lib` exports all notebooks to `filesorter/` Python package
- `nbdev_test` validates all notebook cells

**Validation:** `just sort` from any directory in WSL2 launches the TUI correctly.

### Phase 4 — Refinement
- Add fuzzy search inside category selector (type partial name)
- Session persistence: if you quit mid-folder, remember position on next launch
- `[i]` key: open file info / full metadata panel
- Stats summary on quit: "Sorted 23 files: 4 to-read, 12 d1, 5 d5, 2 d6, 0 skipped"

***

## 5. VALIDATION STRATEGY

### Technical Testing Points (per module)
| Module | Test | Method |
|--------|------|--------|
| `01_domain` | All 3 JSON files load without error | nbdev test cell |
| `01_domain` | Category `d6/34` resolves to "Cloud platforms" | assert in notebook |
| `02_preview` | PDF preview returns ≤20 non-empty lines | test with sample PDF |
| `02_preview` | Empty `.txt` file handled gracefully | edge case cell |
| `03_sorter` | Move + undo returns file to original location | notebook assert |
| `03_sorter` | `get_files()` excludes `sorted/` subdirectory | notebook assert |
| `04_app` | App starts without crash on empty folder | manual test |
| `04_app` | `[q]` quits cleanly, no orphaned processes | manual test |

### User Acceptance Criteria
- Sort 10 files in a single session with no keyboard misroutes
- Any file routed by mistake can be undone with one keypress
- Domain/category JSON update is reflected immediately on next launch without code changes
- `just sort` and `just sort ~/some/other/folder` both work from WSL2 terminal

***

## APPENDIX A — DEPLOYMENT CONSIDERATIONS

### Environment Setup
```bash
# Install uv (if not present)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Clone repo and install
git clone <repo>
cd filesorter
uv sync

# First run creates sorted/ structure automatically
just sort
```

### Dependencies Management (`pyproject.toml`)
```toml
[project]
name = "filesorter"
requires-python = ">=3.12"
dependencies = [
    "textual>=0.60",
    "rich>=13.0",
    "pydantic>=2.0",
    "pdfplumber>=0.10",
    "python-docx>=1.1",
    "openpyxl>=3.1",
    "pyyaml>=6.0",
]

[project.optional-dependencies]
dev = ["nbdev>=2.3", "pytest"]
```

### Monitoring & Maintenance
- Session log written to `~/.local/share/filesorter/session.log` (timestamp, file, destination)
- Log doubles as an audit trail if you need to find where a file went
- To update categories: replace JSON files in `config/`, no `uv sync` needed

***

## APPENDIX B — TECHNICAL STACK

| Layer | Tool | Purpose |
|-------|------|---------|
| Dev methodology | nbdev 2.x | Literate notebooks → exportable Python package |
| Package manager | uv | Fast dependency resolution, virtual env, scripts |
| TUI framework | textual | Full-screen terminal UI, keybindings, panels, modals |
| Styling | rich | Syntax highlighting in preview panel, colored output |
| Config validation | Pydantic v2 | Domain JSON models, AppConfig, type safety |
| Task runner | just | `just sort` entry point, path argument support |
| PDF preview | pdfplumber | Text extraction from PDFs |
| DOCX preview | python-docx | Paragraph extraction |
| XLSX preview | openpyxl | Sheet/row reading |
| Image opening | subprocess → explorer.exe | Opens images in Windows from WSL2 |
| Runtime | WSL2 / Bash on Windows 11 | Primary execution environment |
| Version control | Git + GitHub | nbdev-native workflow |

***

The most logical first step after reviewing this spec is to run `nbdev_new` to scaffold the project, then start with `00_config.ipynb` and `01_domain.ipynb` — those two notebooks are self-contained and can be validated immediately against your existing JSON files. Want me to generate the initial notebook content for those first two modules?
