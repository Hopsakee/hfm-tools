# AGENTS.md — Notebooks Directory (`nbs/`)

Place this file as `nbs/AGENTS.md` in your project.

## This is the source of truth

All library code lives in Jupyter notebooks in this directory. The `.py` files in the package directory are **auto-generated** by nbdev and must NEVER be edited directly.

## Notebook conventions

### Naming

- Notebooks are numbered: `00_module_name.ipynb`, `01_another_module.ipynb`
- `index.ipynb` generates the README
- The number prefix determines module ordering and documentation sidebar order

### Cell directives

Use nbdev directives in code cells:

```python
#| default_exp module_name    # First cell: declares which module this notebook exports to
#| export                      # Export this cell to the module
#| exporti                     # Export but don't add to __all__
#| hide                        # Hide from documentation
#| eval: false                 # Don't run this cell during nbdev_test
```

### Structure of a notebook

1. **First cell**: `#| default_exp module_name`
2. **Module docstring cell**: Markdown describing the module
3. **Imports cell** (with `#| export`): Import everything needed
4. **Code cells**: Classes and functions, each with `#| export` if they should be in the module
5. **Test cells**: Immediately after the code they test (no `#| export` directive — tests stay in the notebook only)
6. **Prose cells**: Markdown explaining what the code does and why

### Testing in notebooks

Tests use `fastcore.test`:

```python
from fastcore.test import *

test_eq(my_func(1), expected_result)
test_ne(a, b)
test_close(computed, expected, eps=1e-5)
```

Tests are regular cells without the `#| export` directive. They run during `nbdev_test` but don't get exported to the `.py` module.

### Documentation style

- Use `docments` — add a comment right after each parameter:

```python
def my_func(
    name: str,  # Human-readable name of the item
    count: int = 5,  # Number of items to process
) -> list:
    """Brief one-line description with `name` and `count`."""
    ...
```

### Working with notebooks

- After editing a notebook, run `uv run nbdev_export` to regenerate `.py` files
- Before committing, run `uv run nbdev_prepare` (runs export + test + clean + readme)
- Never clean notebooks manually — let nbdev hooks handle metadata
- If `git commit` fails because hooks modified notebooks, re-stage and re-commit

## Pydantic model pattern

All data models in notebooks follow this pattern:

```python
#| export
class MyModel(SluggedModel):
    """Pydantic dataclass for X. Has methods for converting to/from SQLite.
    !IMPORTANT: update serialization methods when adding/changing fields!"""
    id: int | None = Field(default=None, description="Auto-created when added to db")
    name: str = Field(..., description="Name of the item")
    
    _instances: ClassVar[Dict[str, "MyModel"]] = {}
    
    def __init__(self, **data):
        super().__init__(**data)
        type(self)._instances[self.slug] = self
    
    def flatten_for_db(self): ...      # Pydantic → flat dict for SQLite
    @classmethod
    def get_db_schema(cls): ...         # Returns @dataclass for table creation
    @classmethod
    def from_db(cls, db_record): ...    # DB record → Pydantic model
```

### Key serialization rules

- Enums → store `.value` string in SQLite
- Lists/tuples → `json.dumps()` for SQLite, `json.loads()` when reading back
- Nested Pydantic models → flatten to individual columns (e.g., `PhaseQualityData` → `collect_quality`, `retrieve_quality`, etc.)
- Use `_fld(rec, name)` static method to handle both attribute and dict access on DB records
