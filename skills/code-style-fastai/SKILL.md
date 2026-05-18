---
name: code-style-fastai
description: Apply fast.ai code style conventions when writing or reviewing Python code in fast.ai ecosystem projects.
---

# fast.ai Code Style

Apply these rules when writing any new function, rewriting >25 lines, or refactoring/reviewing code.

## Brevity facilitates reasoning

- Use comprehensions (list, dict, generator, set)
- Use lambda functions for simple transforms
- Use f-strings (Python 3.6+)
- Use ternary operator: `x = y if a else b`
- Keep one semantic concept under 60 lines

## One line = one idea

```python
# Good: if + action on one line
if self.store.stretch_dir == 0: x = stretch_cv(x, self.store.stretch, 0)
else:                           x = stretch_cv(x, 0, self.store.stretch)

# Good: 1-line function body on def line
def det_lighting(b, c): return lambda x: lighting(x, b, c)
def det_rotate(deg): return lambda x: rotate_cv(x, deg)
def det_zoom(zoom): return lambda x: zoom_cv(x, zoom)
```

## Naming

- **Classes**: CamelCase
- **Everything else**: under_score
- **Short names** for frequently used things
- **Comprehensions**: `o` for object, `i` for index, `k,v` for key-value
- **Inputs**: `x` for tensor/algorithm input
- Follow the abbreviations in `aicontext/abbreviations.md`

## Layout

- Max **160 characters** per line
- **4-space** indentation
- **Align** similar statements vertically for readability
- **Minimize vertical whitespace** — more visible code at once
- **Multi-import**: `import PIL, os, numpy as np, math, collections`
- **Destructuring**: `self.sz,self.denorm,self.norm = sz,denorm,normalizer`
- No trailing whitespace
- Space around operators follows domain conventions (e.g., no spaces in paths: `a/b/c`)

## Documentation

- **docments** (nbdev style) — comment right after each parameter
- One-line docstrings with backtick references to main params
- Comments only explain *why*, never *how*
- Link to papers/external docs when implementing them

## Imports

- `from module import *` is fine for fast.ai ecosystem packages
- Use `__all__` to control what gets exported

## Testing

```python
from fastcore.test import *
test_eq(func(1), expected)
test_ne(a, b)
test_fail(lambda: func(bad_input))
```

## Performance

- Use numpy/pytorch broadcasting over loops
- Use advanced indexing over specialized methods
- Scale to 16GB RAM on large datasets — use generators, lazy evaluation
- Profile hotspots if code takes >1 second
