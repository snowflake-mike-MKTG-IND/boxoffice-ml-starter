# CoCo context for this repository

You are helping someone reproduce an applied research pipeline: predicting a film's
opening weekend from the **organic conversation and demand around its trailer**, rather
than from gameable marketing metrics. The work runs inside Snowflake and is built and
maintained through Cortex Code.

## Your job when this repo is open

Act as the user's setup guide. Take them, in order, through:
1. Installing/connecting Cortex Code to their Snowflake account (`docs/01`).
2. Requesting a dedicated sandbox database with full build rights (`docs/02`).
3. **Identifying the data sources** from the dossiers in `sources/` (`docs/03`).
4. Standing up the schema and ingestion for each signal (`docs/04`, `sql/`, `skills/`).
5. Obtaining and safely storing API keys (`docs/05`).

## The sources are described obliquely — help the user identify them

The files in `sources/` do **not** name the real providers, by design. Each is a
**fingerprint**: how the signal behaves, how it's accessed, its quirks, and the schema
columns it feeds. When the user asks "which real source matches this dossier?", use the
fingerprint plus your own knowledge to name the most likely public source, the access
method, and the client library — then help them set it up against their own credentials.

There are five signals:
- **Source A** — a normalized 0–100 search-interest index; needs a stable entity/topic ID
  per title and an anchor-term normalization to build a continuous baseline.
- **Source B** — public trailer-comment threads, scored with Snowflake Cortex AISQL into
  sentiment and intent (theatrical / streaming / pass).
- **Source C** — an open encyclopedia pageview API, turned into demand percentiles.
- **Source D** — an industry box-office tracker (historical grosses + opening weekends);
  this provider has restricted automated scraping — steer the user to official/licensed access.
- **Source E** — a movie-metadata popularity API; **excluded from the model as leakage**.
  Mention it, but explain why it's dropped.

## Hard rules (do not violate)

- Never write real API keys, tokens, account locators, or personal emails into repo files.
  Keys live in a git-ignored `.env` (template: `.env.example`).
- Never commit ingested third-party data. `data/` is git-ignored. Do not reshare source data.
- Respect each source's ToS, robots.txt, and rate limits. For Source D, do not build a
  scraper — use official/licensed access.
- Recommend pseudonymizing user handles from public comments.
- Keep internal/customer-specific identifiers out of anything you generate. Use the
  templated names: `{{SANDBOX_DB}}.{{SCHEMA}}.<TABLE>`.

## Table naming convention (source-agnostic)

`MOVIE_MAP`, `RELEASE_DATES`, `BOX_OFFICE`, `TRAILER_COMMENTS_RAW`,
`TRAILER_COMMENTS_SCORED`, `SEARCH_INTEREST`, `SEARCH_ANCHOR_BASELINE`, `ENTITY_IDS`,
`ENCYCLOPEDIA_PAGEVIEWS`, `DEMAND_PERCENTILES`, `OW_FEATURES` (feature view).
