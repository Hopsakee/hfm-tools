# AGENTS.md — Main Application File (`main.py`)

Place this file alongside `main.py` in the project root directory.

## What belongs in `main.py`

- FastHTML app setup (`fast_app`, headers, theme)
- Route handlers (`@rt` decorated functions)
- UI helper functions used exclusively by routes (e.g., `WorkflowViz()`, `format_toolflow()`)
- Form field builder functions (e.g., `_improvement_form_fields()`)
- Form save/validation logic (e.g., `_improvement_save()`)
- Navigation components (e.g., `top_nav`)
- Database initialization and table creation
- The `serve()` call at the end

## What does NOT belong in `main.py`

- Data model classes → put in notebooks, exported to package
- Business logic / algorithms → put in notebooks
- Visualization logic → put in notebooks
- Utility functions shared across modules → put in notebooks

## Route handler patterns

### Read (detail page)

```python
@rt
def item(slug: str):
    row = db.t.items("slug=?", (slug,))[0]
    item = MyModel.from_db(row)
    return Titled(f"Item: {item.name}",
        Card(...),
        id="main-content"
    )
```

### Edit form page

```python
@rt
def item_edit(slug: str):
    row = db.t.items("slug=?", (slug,))[0]
    item = MyModel.from_db(row)
    return Titled(f"Edit: {item.name}",
        Button("← Back", hx_get=f"/item?slug={slug}", hx_target="#main-content", hx_swap="innerHTML"),
        Card(Form(
            # form fields ...
            Button("Save", type="submit", cls=ButtonT.primary),
            hx_post=f"/item_save?slug={slug}",
            hx_target="#main-content",
            hx_swap="innerHTML"
        )),
        id="main-content"
    )
```

### Save (form handler)

```python
@rt
async def item_save(slug: str, req):
    form_data = await req.form()
    try:
        # Parse and validate form data
        # Create Pydantic model
        ensure_unique_slug(db.t.items, model.slug, model.id)
        db.t.items.update(model.flatten_for_db())
        return RedirectResponse(url=f"/item?slug={model.slug}", status_code=303)
    except Exception as e:
        return Titled("Validation Error",
            Card(P(f"Error: {str(e)}"), Button("Back", ...))
        )
```

### Create (new item)

```python
@rt("/item_add")
def item_add():
    return Titled("Add Item",
        Card(Form(
            # empty form fields ...
            Button("Create", type="submit", cls=ButtonT.primary),
            hx_post="/item_create",
            hx_target="#main-content",
            hx_swap="innerHTML"
        )),
        id="main-content"
    )

@rt("/item_create")
async def item_create(req):
    form_data = await req.form()
    try:
        # Parse, validate, insert
        db.t.items.insert(model.flatten_for_db())
        return RedirectResponse(url=f"/item?slug={model.slug}", status_code=303)
    except Exception as e:
        return Titled("Validation Error", Card(P(f"Error: {str(e)}"), ...))
```

## Navigation pattern

All pages should use a consistent navigation bar and target `#main-content` for SPA-like behavior:

```python
top_nav = NavBar(
    Button("← Back to Index", hx_get="/", hx_target="body", hx_swap="innerHTML", cls=ButtonT.text),
    Button("Other Page", hx_get="/other", hx_target="#main-content", hx_swap="innerHTML", cls=ButtonT.text),
    brand=H2("App Title"),
)

@rt
def index():
    return Title("App"), Container(
        top_nav,
        DivCentered(..., id="main-content"),
    )
```

## Slug uniqueness

Use `ensure_unique_slug()` before any insert or update to prevent duplicate slugs:

```python
def ensure_unique_slug(table, slug, current_id=None):
    matches = table("slug=?", (slug,))
    if not matches: return
    cid = int(current_id) if current_id is not None else None
    for row in matches:
        rid = int(_row_id(row))
        if cid is None or rid != cid:
            raise ValueError("An item with this name already exists.")
```
