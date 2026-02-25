## Use full words and unit suffixes for variable names

Avoid abbreviations that might be confusing. For variables representing physical quantities or time, append the unit to the name (e.g., `_MS`, `_PX`) to make the value's meaning explicit.

**Bad:**
```typescript
const animDur = 300; // Is it seconds? frames?
const w = 100;
```

**Good:**
```typescript
const ANIMATION_DURATION_MS = 300;
const width_px = 100;
```
