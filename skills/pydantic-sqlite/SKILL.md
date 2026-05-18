---
name: pydantic-sqlite
description: Use when creating Pydantic data models that need SQLite persistence via fastlite, or when working with database CRUD operations.
---

# Pydantic Models with SQLite (fastlite) Persistence

## Architecture

```
Pydantic BaseModel ←→ flatten_for_db() / from_db() ←→ SQLite via fastlite
```

The key challenge: Pydantic models use rich types (enums, nested models, lists/tuples) that SQLite doesn't support. Each model needs explicit serialization/deserialization methods.

## Base class: SluggedModel

All models inherit from `SluggedModel` which provides:
- Auto-computed `slug` field (URL-friendly version of `name`)
- `_fld()` static method to handle both attribute and dict access on DB records

```python
class SluggedModel(BaseModel):
    @computed_field
    @property
    def slug(self) -> str:
        return ossys.sanitize_name(self.name)

    @staticmethod
    def _fld(rec, name):
        return getattr(rec, name) if hasattr(rec, name) else rec[name]
```

## Complete model pattern

```python
#| export
class MyModel(SluggedModel):
    """Pydantic dataclass for X.
    !IMPORTANT: update serialization methods when adding/changing fields!"""
    id: int | None = Field(default=None, description="Auto-created when added to db")
    name: str = Field(..., description="Human-readable name")
    status: MyEnum = Field(..., description="Current status")
    nested: NestedData = Field(..., description="Complex nested data")

    _instances: ClassVar[Dict[str, "MyModel"]] = {}

    def __init__(self, **data):
        super().__init__(**data)
        type(self)._instances[self.slug] = self

    @classmethod
    def get_instances(cls) -> Dict[str, "MyModel"]:
        return cls._instances

    def flatten_for_db(self):
        """Convert to flat dict for SQLite storage."""
        base = self.model_dump(exclude={'nested'})
        base.update({
            'nested_field_a': self.nested.field_a.value,  # Enum → string
            'nested_field_b': json.dumps(self.nested.field_b),  # List → JSON string
        })
        return base

    @classmethod
    def get_db_schema(cls):
        """Returns @dataclass with SQLite-compatible types for table creation."""
        @dataclass
        class MyModels:  # Plural class name = table name
            id: int
            name: str
            status: str      # Enum stored as string
            slug: str
            nested_field_a: str  # Flattened from nested model
            nested_field_b: str  # JSON string
        return MyModels

    @field_serializer('status')
    def db_serialize(self, v):
        return v.value

    @classmethod
    def from_db(cls, db_record):
        """Reconstruct Pydantic model from database record."""
        nested = NestedData(
            field_a=MyEnum(cls._fld(db_record, 'nested_field_a')),
            field_b=json.loads(cls._fld(db_record, 'nested_field_b')),
        )
        return cls(
            id=cls._fld(db_record, 'id'),
            name=cls._fld(db_record, 'name'),
            status=MyEnum(cls._fld(db_record, 'status')),
            nested=nested,
        )
```

## Serialization rules

| Python type | SQLite storage | Serialize | Deserialize |
|---|---|---|---|
| `str` | `str` | Direct | Direct |
| `int` | `int` | Direct | Direct |
| `Enum` | `str` | `.value` | `MyEnum(value)` |
| `list[Enum]` | `str` | `json.dumps([e.value for e in list])` | `[MyEnum(s) for s in json.loads(v)]` |
| `tuple[str, ...]` | `str` | `json.dumps(tuple)` | `json.loads(v)` |
| Nested Pydantic model | Multiple columns | Flatten to individual `{prefix}_{field}` columns | Reconstruct from individual columns |
| `Optional[X]` | `str` (nullable) | Same as X, with None check | Same as X, with None check |

## Database operations

### Create database and tables

```python
db = database("./data/app.db")
db.execute("PRAGMA foreign_keys = ON;")
create_tables_from_pydantic(db, [ModelA, ModelB, ModelC])
```

### CRUD operations

```python
# Insert
db.t.my_models.insert(model.flatten_for_db())

# Read all
all_rows = db.t.my_models()

# Read filtered
rows = db.t.my_models("slug=?", (slug,))
model = MyModel.from_db(rows[0])

# Update
db.t.my_models.update(model.flatten_for_db())

# Load all as dict
models_dict = dict_from_db(db.t.my_models, MyModel)
```

### The `dict_from_db` utility

```python
def dict_from_db(db_table, class_table) -> dict[str, BaseModel]:
    d = {}
    for t in db_table():
        slug = getattr(t, "slug") if hasattr(t, "slug") else t["slug"]
        d[slug] = class_table.from_db(t)
    return d
```

## Validation

Use Pydantic validators for cross-referencing:

```python
@field_validator('tool')
def validate_tool_names(cls, v):
    valid_tools = Tool.get_instances().keys()
    if v not in valid_tools: raise ValueError(f"Tool '{v}' does not exist")
    return v
```

## Instance tracking

Models use `ClassVar[Dict]` to track all created instances in memory:

```python
_instances: ClassVar[Dict[str, "MyModel"]] = {}

def __init__(self, **data):
    super().__init__(**data)
    type(self)._instances[self.slug] = self
```

This enables validation and lookup by slug without hitting the database.
