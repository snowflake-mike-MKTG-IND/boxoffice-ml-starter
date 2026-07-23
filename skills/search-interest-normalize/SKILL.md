---
name: search-interest-normalize
description: "Pull and normalize a relative search-interest index for films into Snowflake. Use for: search interest, trends, demand index, entity-ID lookup, anchor normalization, continuous baseline. Triggers: search interest, trends, demand signal, normalize interest."
---

# Search-Interest Normalize (Source A)

Pull a **relative 0–100 search-interest** series for each film and normalize it into a
continuous, comparable demand timeline in Snowflake. Read `sources/source_A_search_interest.md`
first, and ask CoCo to confirm the real source + Python client before running anything.

## Prerequisites
- The search-interest Python client `{{SEARCH_INTEREST_LIB}}` installed locally.
- `SEARCH_ENTITY_API_KEY` in `.env` for the entity lookup (or use the keyless fallback).
- Sandbox tables from `sql/00_schema.sql`: `ENTITY_IDS`, `SEARCH_INTEREST`, `SEARCH_ANCHOR_BASELINE`.

## CRITICAL: use a stable entity ID, never free text
Free-text queries match unrelated searches and can invert the signal. Resolve each title to
a stable **entity/topic ID** first and store it in `ENTITY_IDS`.

```python
# Entity lookup — key from .env, NEVER hardcoded
import os, requests
KEY = os.environ["SEARCH_ENTITY_API_KEY"]
def entity_id(title):
    r = requests.get(
        "{{ENTITY_LOOKUP_API}}",                 # CoCo fills the real endpoint
        params={"query": f"{title} film", "key": KEY, "limit": 5, "types": "Movie"},
    ).json()
    items = r.get("itemListElement", [])
    return items[0]["result"]["@id"].split(":")[-1] if items else None
# Fallback: the client's own suggestions endpoint returns topic IDs (keyless).
```

## The two-query normalization
Every pull is rescaled 0–100 *within that pull*, so pulls aren't directly comparable. Fix
it with an anchor term present in every movie pull, plus a standalone anchor baseline.

```python
# Query A — movie entity + anchor together (true ratio, per-pull scale)
kw = [ENTITY_MID, "{{ANCHOR_TERM}}"]        # e.g. an evergreen movie-related term
client.build_payload(kw, timeframe="<-21d> <+21d>", geo="US")
df_a = client.interest_over_time()          # -> INTEREST (movie), ANCHOR_INTEREST (anchor)

# Query B — anchor alone over a long window (consistent standalone scale)
client.build_payload(["{{ANCHOR_TERM}}"], timeframe="<~90d>", geo="US")
df_b = client.interest_over_time()          # -> normalize into SEARCH_ANCHOR_BASELINE via date overlaps
```

- Store Query A's movie column → `SEARCH_INTEREST.INTEREST`, anchor column → `ANCHOR_INTEREST`.
- Use Query B to extend `SEARCH_ANCHOR_BASELINE` (normalized continuous floats) by matching
  overlapping dates to existing baseline values, then rescaling.
- For **manual URL exports**, the anchor must be the literal anchor **text**, not its
  entity ID (an ID can resolve to the wrong concept).

## Load to Snowflake
Write results to `{{SANDBOX_DB}}.{{SCHEMA}}.SEARCH_INTEREST` and `...SEARCH_ANCHOR_BASELINE`
(mixed/Title Case titles; never UPPERCASE). Then build demand percentiles by horizon
(see `pipeline-refresh`).

## Gotchas
- Expect rate-limiting/throttling; back off and retry.
- Validate a new film's pull against the provider's own UI before trusting it.
- A wrong release date corrupts the ±21-day window — validate dates first (Source D).
