---
name: comment-ingest-score
description: "Ingest public trailer comments and score them with Snowflake Cortex AISQL into sentiment + intent. Use for: trailer comments, comment ingestion, sentiment, intent classification, AISQL scoring, pseudonymize handles. Triggers: comments, trailer conversation, intent, sentiment, AISQL."
---

# Comment Ingest + Score (Source B)

Ingest public trailer-comment threads and turn them into the project's core signal:
**volume** + **decomposed intent**. Read `sources/source_B_trailer_comments.md` first and
have CoCo confirm the real platform + official API.

## Prerequisites
- `COMMENT_PLATFORM_API_KEY` in `.env` (preferred: official platform API).
- Sandbox tables: `TRAILER_COMMENTS_RAW`, `TRAILER_COMMENTS_SCORED` (from `sql/00_schema.sql`).
- Access to Cortex AISQL (docs/02).

## Step 1 — Ingest (prefer the official API)
```python
import os, hashlib
KEY = os.environ["COMMENT_PLATFORM_API_KEY"]
def pseudonymize(handle: str) -> str:
    return hashlib.sha256(handle.encode()).hexdigest()[:16]   # store hash, never raw handle
# Pull comments for a trailer video via {{COMMENT_PLATFORM}}'s official API, paginating.
# For each comment keep: video_id, comment_id, author_hash, text, like_count, date.
```
- If you must use a browser-DOM path instead of the API, respect ToS/robots/rate limits
  and still pseudonymize. Do not hammer the platform.
- Load rows to `{{SANDBOX_DB}}.{{SCHEMA}}.TRAILER_COMMENTS_RAW`.

## Step 2 — Score with Cortex AISQL
Run `sql/20_intent_scoring_aisql.sql` (ask CoCo to refresh it to current AISQL syntax and a
good available model). It classifies each comment into a sentiment score/bucket and an
intent flag set: `THEATRICAL_INTENT`, `STREAMING_INTENT`, `PASS_INTENT`.

Why intent, not raw positivity: generic praise ("can't wait!!") is the *least* predictive
text, and planted hype only pushes one way. Classifying **intent** is what makes the signal
hard to game.

## Step 3 — Per-film features
```sql
SELECT MOVIE_ID,
       COUNT(*)                                            AS comment_volume,
       AVG(SENTIMENT_SCORE)                                AS avg_sent,
       100.0*(AVG(THEATRICAL_INTENT) - AVG(PASS_INTENT))   AS net_intent_pct
FROM {{SANDBOX_DB}}.{{SCHEMA}}.TRAILER_COMMENTS_SCORED
GROUP BY MOVIE_ID;
```
Volume does most of the predictive work; net intent is weak alone but nearly independent of
volume, so it stacks additively. See `docs/06_model_overview.md`.

## Privacy & compliance
- **Always pseudonymize handles.** Never store raw usernames or PII.
- Keep raw pulls out of git (`data/` is ignored). Don't reshare comment data.
