# Source B — Trailer-comment volume + AI-scored intent

This is the **core signal** of the whole project: the organic conversation under a film's
trailer. Two things matter — **how much** conversation there is (volume) and **which way**
it leans (intent).

## What it is
Public comment threads posted under official trailer videos on a large video platform.
Each comment is short free text, with an author handle and a like count.

## Fingerprint
- A dominant global video platform hosts official trailers; each has a public comment
  thread, often thousands of comments for a tentpole.
- Comments load lazily via JavaScript in the modern UI, so a raw HTML fetch won't contain
  them — you either use the platform's **official data API** (preferred) or render the page
  in a browser and extract the comment DOM.
- Comment text is messy, multilingual, and full of noise; raw counts alone are weak. The
  value comes from **classifying** each comment.

## The processing that makes it useful (Snowflake Cortex AISQL)
Raw comments land in a table; then a single AISQL pass scores each one into:
- **sentiment** (a score and a bucket: positive / neutral / negative), and
- **intent**: `THEATRICAL` ("opening night", "seeing this in IMAX"), `STREAMING`
  ("wait for streaming"), or `PASS` ("hard pass", "not interested").

From the scored table you derive, per film: comment **volume**, **net intent %**
(theatrical-leaning minus skip-leaning), and sentiment mix. Net intent is a weak-but-
independent signal that stacks on top of volume — see `docs/06_model_overview.md`.

## Why intent beats raw sentiment (and resists gaming)
Planted hype is generic ("can't wait!!") and generic praise is the *least* predictive
text in the data. Manipulators also push in one direction, inflating blunt counts while
leaving the decomposed intent signal intact underneath. Classifying *intent* rather than
counting *positivity* is what makes the signal hard to fake.

## Access & etiquette
- **Prefer the platform's official API** with your own key (`COMMENT_PLATFORM_API_KEY`).
- If you use a browser-DOM path, respect ToS, `robots.txt`, and rate limits; don't hammer.
- **Pseudonymize author handles** on ingest (hash them). Store only what the model needs.

## Feeds these columns
- `TRAILER_COMMENTS_RAW`: comment text, pseudonymized author, like count, video/movie id.
- `TRAILER_COMMENTS_SCORED`: + `SENTIMENT_SCORE`, `SENTIMENT_BUCKET`, `THEATRICAL_INTENT`,
  `STREAMING_INTENT`, `PASS_INTENT`.
- Downstream per-film features: comment volume, net intent %, sentiment %s.

## Ask CoCo
> "Read `sources/source_B_trailer_comments.md`. Which platform and which official API is
> this? Show me how to pull comments for one trailer with my own key, pseudonymize handles,
> load them to `{{SANDBOX_DB}}.RESEARCH.TRAILER_COMMENTS_RAW`, then score them with Cortex
> AISQL into sentiment + intent."
