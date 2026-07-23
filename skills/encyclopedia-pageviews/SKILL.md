---
name: encyclopedia-pageviews
description: "Pull daily encyclopedia pageviews for films and build demand percentiles in Snowflake. Use for: pageviews, encyclopedia demand, wiki pageviews, demand percentiles. Triggers: pageviews, encyclopedia, demand curve, wiki."
---

# Encyclopedia Pageviews (Source C)

Pull daily pageview counts for each film's encyclopedia article and turn them into robust
**demand percentiles**. Read `sources/source_C_encyclopedia_pageviews.md` first and have
CoCo name the real pageview API and its endpoint shape.

## Prerequisites
- No API key needed; set a descriptive `PAGEVIEW_CONTACT` in `.env` per provider etiquette.
- Sandbox tables: `ENCYCLOPEDIA_PAGEVIEWS`, `DEMAND_PERCENTILES` (from `sql/00_schema.sql`).

## Step 1 — Resolve the canonical article title
Titles need exact matching (spaces↔underscores, disambiguation like "(film)" or a year).
Resolve redirects to the canonical title before pulling.

## Step 2 — Pull daily views for the pre-release window
```python
import os, requests
CONTACT = os.environ.get("PAGEVIEW_CONTACT", "you@example.com")
HEADERS = {"User-Agent": f"trailer-signal-research/1.0 ({CONTACT})"}   # polite identification
def daily_views(article, start, end):
    url = "{{PAGEVIEW_API}}"          # CoCo fills the real per-article daily endpoint
    r = requests.get(url.format(article=article, start=start, end=end), headers=HEADERS, timeout=15)
    return r.json()                   # -> [{date, views}, ...]
# Counts are ABSOLUTE (real views) — cache them; history doesn't change.
```
Load to `{{SANDBOX_DB}}.{{SCHEMA}}.ENCYCLOPEDIA_PAGEVIEWS`.

## Step 3 — Build demand percentiles by horizon
Align to days-out (−21/−14/−7/−3), then convert to percentiles across the film set to tame
the huge dynamic range: cumulative, 7-day rolling, peak-day, velocity. Write to
`DEMAND_PERCENTILES` (columns `WIKI_R7D_PCTILE`, `WIKI_PEAK_PCTILE`, `WIKI_CUM_PCTILE`, ...).

## Etiquette
- Send the contact string; keep request rates polite; cache aggressively.
