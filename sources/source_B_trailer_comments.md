# Source B — Trailer conversation (volume + AI-scored intent)

This is the **core signal** of the project: the organic conversation under a film's trailer.
Two things matter — **how much** conversation there is (volume) and **which way** it leans
(intent).

## The signal
Public comments posted under official trailer videos: short free text, usually with an
author handle and a like/vote count, often thousands of them for a big title.

## Options CoCo can help you choose from
The conversation lives on the major online video platforms and, to a lesser extent, social
and forum sites. Ask CoCo for the options and it will compare access paths — an official
platform **data API** (preferred, with your own key) vs. rendering the page and reading the
comment section from the DOM — along with their rate limits and terms. Comments typically
load dynamically, so a raw HTML fetch won't contain them; you'll use the API or a rendered
page.

## The processing that makes it useful (Snowflake Cortex AISQL)
Raw comments alone are weak and noisy — the value comes from **classifying** them. A single
AISQL pass scores each comment into:
- **sentiment** (a score and a bucket: positive / neutral / negative), and
- **intent**: `THEATRICAL` ("opening night", "seeing this in IMAX"), `STREAMING` ("wait for
  streaming"), or `PASS` ("hard pass").

From the scored table you derive, per film: comment **volume**, **net intent %**
(theatrical-leaning minus skip-leaning), and sentiment mix. See `docs/06_model_overview.md`.

## Why intent beats raw sentiment (and resists gaming)
Planted hype is generic ("can't wait!!"), and generic praise is the *least* predictive text
in the data. Manipulators also push in one direction, inflating blunt counts while leaving
the decomposed intent signal intact underneath. Classifying *intent* rather than counting
*positivity* is what makes the signal hard to fake.

## Access & etiquette
- Prefer an **official API** with your own key. If you read from a rendered page instead,
  respect the platform's terms, `robots.txt`, and rate limits — don't hammer it.
- **Pseudonymize author handles** on ingest (hash them). Store only what the model needs.

## Feeds these columns
- `TRAILER_COMMENTS_RAW` (text, pseudonymized author, like count, video/movie id).
- `TRAILER_COMMENTS_SCORED` (+ `SENTIMENT_SCORE`, `SENTIMENT_BUCKET`, `THEATRICAL_INTENT`,
  `STREAMING_INTENT`, `PASS_INTENT`).

## Ask CoCo
> "Read `sources/source_B_trailer_comments.md`. What are my options for pulling public
> trailer comments, and which official API should I use with my own key? Show me how to
> ingest comments for one trailer, pseudonymize handles, load to
> `{{SANDBOX_DB}}.RESEARCH.TRAILER_COMMENTS_RAW`, and score them with Cortex AISQL into
> sentiment + intent."
