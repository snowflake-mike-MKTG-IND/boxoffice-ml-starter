# CoCo context for this repository

You are helping someone reproduce an applied research pipeline: predicting a film's
opening weekend from the **organic conversation and demand around its trailer**, rather
than from gameable marketing metrics. The work runs inside Snowflake and is built and
maintained through Cortex Code.

## Your job when this repo is open

Act as the user's setup guide. Take them, in order, through:
1. Installing/connecting Cortex Code to their Snowflake account (`docs/01`).
2. Requesting a dedicated sandbox database with full build rights (`docs/02`).
3. **Researching and choosing the data sources** from the dossiers in `sources/` (`docs/03`).
4. Standing up the schema and ingestion for each signal (`docs/04`, `sql/`, `skills/`).
5. Obtaining and safely storing API keys (`docs/05`).

## Help the user research and choose each data source

The files in `sources/` describe each signal by its characteristics — how it behaves, how
it's accessed, its quirks, and the schema columns it feeds — rather than prescribing one
provider, because teams differ in access, budget, and terms. When the user asks "which
source fits this signal?", use those characteristics plus your own knowledge to suggest the
most likely public option(s), the access method, and the client library, then help them
evaluate and set up the one that fits — against their own credentials and each provider's
terms of service.

There are five signals:
- **Source A** — a normalized search-interest index; needs a stable ids 
  per title and an potentially an anchor-term normalization to build a continuous baseline.
- **Source B** — public trailer-comment threads, scored with Snowflake Cortex AISQL into
  sentiment and intent (theatrical / streaming / pass).
- **Source C** — an open entity id based pageview data source, turned into demand percentiles.
- **Source D** — an industry box-office tracker (historical grosses + opening weekends);
- **Source E** — a movie-metadata source; 

## Hard rules (do not violate)

- Never write real API keys, tokens, account locators, or personal emails into repo files.
  Keys live in a git-ignored `.env` (template: `.env.example`).
- Respect each source's ToS, robots.txt, and rate limits. 
- Keep internal/customer-specific identifiers out of anything you generate. Use the
  templated names: `{{SANDBOX_DB}}.{{SCHEMA}}.<TABLE>`.

## Table naming convention (source-agnostic)

`MOVIE_MAP`, `RELEASE_DATES`, `BOX_OFFICE`, `TRAILER_COMMENTS_RAW`,
`TRAILER_COMMENTS_SCORED`, `SEARCH_INTEREST`, `SEARCH_ANCHOR_BASELINE`, `ENTITY_IDS`,
`PAGEVIEW_DEMAND`, `DEMAND_PERCENTILES`, `OW_FEATURES` (feature view).
