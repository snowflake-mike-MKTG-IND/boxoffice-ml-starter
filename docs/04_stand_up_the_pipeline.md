# 04 — Stand up the pipeline

By now you have CoCo connected (docs/01), a sandbox (docs/02), and identified sources
(docs/03). Time to build. Do it conversationally with CoCo — this page is the map.

## 0. Create the schema
```bash
snow sql --connection my_sandbox -f sql/00_schema.sql   # after replacing {{SANDBOX_DB}}
```
Or ask CoCo: *"Run `sql/00_schema.sql` against my sandbox, substituting my database name."*

## 1. Seed the film spine
Populate `MOVIE_MAP` and `RELEASE_DATES` for your research set. **Validate every release
date against a second reference first** (Source D dossier) — a wrong date corrupts the
entire pre-release window.

## 2. Ingest each signal
Run the installed skills (see `skills/`), in this order:

| Order | Skill | Fills |
|---|---|---|
| 1 | `box-office-history` | `BOX_OFFICE`, `RELEASE_DATES` (label + validated dates) |
| 2 | `search-interest-normalize` | `ENTITY_IDS`, `SEARCH_INTEREST`, `SEARCH_ANCHOR_BASELINE` |
| 3 | `encyclopedia-pageviews` | `ENCYCLOPEDIA_PAGEVIEWS` |
| 4 | `comment-ingest-score` | `TRAILER_COMMENTS_RAW` → `TRAILER_COMMENTS_SCORED` |
| 5 | (metadata, optional/static only) | `MOVIE_METADATA` |

## 3. Score comments with Cortex AISQL
```bash
snow sql --connection my_sandbox -f sql/20_intent_scoring_aisql.sql
```
Ask CoCo to refresh it to the current AISQL syntax and a good available model first.

## 4. Build demand percentiles
From Source A + Source C, build `DEMAND_PERCENTILES` at horizons −21/−14/−7/−3
(cumulative / rolling / peak / velocity). The `pipeline-refresh` skill does this across the
film set.

## 5. Assemble the feature view
```bash
snow sql --connection my_sandbox -f sql/10_feature_view.sql
```
Then sanity-check:
```sql
SELECT COUNT(*) AS films, AVG(YT_COMMENTS) AS avg_comments, AVG(NET_INTENT_PCT) AS avg_net_intent
FROM {{SANDBOX_DB}}.RESEARCH.OW_FEATURES;
```

## 6. Keep it fresh
Use the `pipeline-refresh` skill to update films in the active window (−21..+21 days) and to
fill opening weekends once films release.

## You're research-ready
You now have one modeling row per film with volume, decomposed intent, and demand
percentiles against a validated label. For a rigorous modeling approach, see
**`docs/06_model_overview.md`**.
