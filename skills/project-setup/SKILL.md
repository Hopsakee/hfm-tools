---
name: project-setup
description: Use when bootstrapping a new Python web application project with FastHTML, nbdev, and uv from scratch.
---

# New Project Setup

## Step-by-step setup

### 1. Create project with uv

```bash
mkdir my-project && cd my-project
uv init --python 3.12
```

### 2. Set up Python version

```bash
uv python pin 3.12
```

### 3. Add core dependencies

```bash
uv add python-fasthtml monsterui pydantic fastcore
uv add --group dev pre-commit nbdev
```

### 4. Initialize nbdev

Create `settings.ini`:

```ini
[DEFAULT]
lib_name = myproject
user = YourGitHubUser
branch = main
author = YourName
author_email = you@example.com
description = Brief project description
keywords = nbdev jupyter notebook python
language = English
license = apache2
min_python = 3.11
nbs_path = nbs
doc_path = _docs
readme_nb = index.ipynb
doc_host = https://%(user)s.github.io
doc_baseurl = /%(lib_name)s
git_url = https://github.com/%(user)s/%(lib_name)s
lib_path = %(lib_name)s
```

### 5. Create directory structure

```bash
mkdir -p nbs data myproject aicontext
```

### 6. Create `nbs/index.ipynb`

A notebook with a markdown cell describing the project. This generates README.md.

### 7. Create `.pre-commit-config.yaml`

```yaml
repos:
- repo: https://github.com/fastai/nbdev
  rev: 2.2.10
  hooks:
  - id: nbdev_clean
  - id: nbdev_export
```

```bash
uv run pre-commit install
```

### 8. Create `main.py` (minimal)

```python
from fasthtml.common import *
from monsterui.all import *

from myproject.models import *

app, rt = fast_app(
    hdrs=[Theme.blue.headers()],
)

@rt
def index():
    return Title("My App"), Container(
        H1("Hello World"),
    )

serve()
```

### 9. Create first notebook `nbs/00_models.ipynb`

With data model classes following the Pydantic + SQLite pattern.

### 10. Create `Dockerfile`

```dockerfile
FROM ghcr.io/astral-sh/uv:python3.12-trixie-slim
WORKDIR /app
COPY pyproject.toml uv.lock .
RUN --mount=type=cache,target=/root/.cache uv sync --no-install-project
COPY . .
RUN --mount=type=cache,target=/root/.cache uv sync
EXPOSE 5001
CMD ["uv", "run", "main.py"]
```

### 11. Create `.gitignore`

Include at minimum:

```
data/
*.db*
_docs/
_proc/
__pycache__/
*.py[cod]
.venv/
*.egg-info/
.ipynb_checkpoints
.quarto
.env
```

### 12. Copy AI context files

Copy the `aicontext/` folder with library documentation:
- `fasthtml.md`
- `monsterui.md`
- `fastcore.md`
- `nbdev.md`
- `abbreviations.md`

### 13. Copy agent instructions

Copy `AGENTS.md` and `skills/` folder to project root.

### 14. Create `pyproject.toml`

```toml
[build-system]
requires = ["setuptools>=64"]
build-backend = "setuptools.build_meta"

[project]
name = "myproject"
dynamic = ["version"]
description = "Project description"
readme = "README.md"
requires-python = ">=3.11"
license = {text = "Apache-2.0"}
dependencies = [
    "monsterui>=1.0.44",
    "pydantic>=2.12",
    "python-fasthtml>=0.12.47",
]

[project.entry-points.nbdev]
myproject = "myproject._modidx:d"

[tool.setuptools.dynamic]
version = {attr = "myproject.__version__"}

[tool.setuptools.packages.find]
include = ["myproject"]

[tool.nbdev]

[dependency-groups]
dev = ["pre-commit>=4.5"]
```

### 15. Initialize git

```bash
git init
git add .
git commit -m "Initial project setup"
```

## Verification checklist

- [ ] `uv run main.py` starts the server
- [ ] `uv run nbdev_export` generates `.py` files from notebooks
- [ ] `uv run nbdev_test` passes
- [ ] `uv run nbdev_prepare` runs cleanly
- [ ] Git commit succeeds (pre-commit hooks run)
