---
name: fasthtml-monsterui
description: Use when building or modifying FastHTML + MonsterUI web application UI, routes, forms, or any browser-facing functionality.
---

# FastHTML + MonsterUI Web Development

## Core principles

1. **FastHTML is NOT FastAPI** — it generates server-rendered HTML, not JSON APIs
2. **HTMX for interactivity** — no client-side JS frameworks (no React, Vue, Svelte)
3. **MonsterUI for styling** — UIkit-based component framework for FastHTML
4. **Hypermedia-driven** — the server returns HTML fragments; HTMX swaps them into the DOM

## App setup pattern

```python
from fasthtml.common import *
from monsterui.all import *

app, rt = fast_app(
    hdrs=[
        Style(".node { cursor: pointer; }"),  # Custom CSS
        Theme.blue.headers(),                  # MonsterUI theme
    ],
)
# ... routes ...
serve()  # No if __name__ guard needed
```

## Component reference (commonly used)

### Layout
- `Container(...)` — centered max-width container
- `DivCentered(...)` — flex centered
- `DivFullySpaced(...)` — flex space-between
- `DivHStacked(...)` — horizontal flex
- `DivVStacked(...)` — vertical flex
- `DivLAligned(...)` — left-aligned flex
- `DivRAligned(...)` — right-aligned flex
- `Grid(*items, cols=3)` — CSS grid

### Content
- `Card(...)` — card container
- `Titled("Title", ...)` — page with H1 title + Container (also sets meta title)
- `NavBar(..., brand=H2("Title"))` — navigation bar
- `render_md(text)` — render markdown to HTML

### Forms
- `LabelInput("Label", name="field", value="val")` — labeled text input
- `LabelTextArea("Label", name="field", value="val")` — labeled textarea
- `LabelSelect(*options, label="Label", name="field")` — labeled select
- `LabelCheckboxX("Label", name="field", value="val", checked=True)` — labeled checkbox
- `Option("Display", value="val", selected=True)` — select option

### Buttons
- `Button("Text", cls=ButtonT.primary)` — primary button
- `Button("Text", cls=ButtonT.secondary)` — secondary button
- `Button("Text", cls=ButtonT.text)` — text-style button
- `Button("Submit", type="submit", cls=ButtonT.primary)` — form submit

### Typography
- `H2`, `H3`, `H4`, `P`, `Strong`, `I`, `Hr`, `Span`

### Theme
- `ThemePicker()` — theme switching UI
- `Theme.blue.headers()` — include in app headers

## HTMX patterns

### SPA-like navigation (swap part of page)

```python
Button("Go", hx_get="/page", hx_target="#main-content", hx_swap="innerHTML")
```

### Full page transition

```python
Button("Home", hx_get="/", hx_target="body", hx_swap="innerHTML")
```

### Form submission

```python
Form(
    # fields ...
    Button("Save", type="submit", cls=ButtonT.primary),
    hx_post="/save_endpoint",
    hx_target="#main-content",
    hx_swap="innerHTML"
)
```

### Clickable table rows

```python
Tr(
    Td(item.name),
    Td(str(item.count)),
    style="cursor:pointer;",
    hx_get=f"/item?slug={item.slug}",
    hx_target="#main-content",
    hx_swap="innerHTML"
)
```

## Form handling (server side)

```python
@rt
async def save_item(slug: str, req):
    form_data = await req.form()
    value = form_data.get("field_name")
    multi_values = form_data.getlist("checkbox_field")  # For multiple checkboxes
```

## UK utility classes (commonly used)

- `"uk-margin-bottom"`, `"uk-margin-top"`, `"uk-margin-small"`
- `"space-y-2"`, `"space-y-3"` — vertical spacing between children
- `"space-x-4"` — horizontal spacing
- `"w-full"` — full width
- `"min-w-40"` — minimum width
- `"text-primary"` — theme primary color

## Documentation to consult

Before writing non-trivial FastHTML or MonsterUI code, read:

1. `aicontext/fasthtml.md` — overview + links to detailed docs
2. `aicontext/monsterui.md` — component examples + API reference
3. Follow links in those files for specific topics (routing, handlers, forms, etc.)
