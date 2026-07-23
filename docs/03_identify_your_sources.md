# 03 — Identify your data sources (with CoCo)

The repo describes each signal obliquely, on purpose (see `sources/README.md`). This page
is the guided flow to turn those fingerprints into named, set-up sources — using Cortex
Code as your research partner.

## The loop, per source

1. Open the dossier (`sources/source_X_*.md`) in Cortex Code.
2. Ask CoCo to **identify** it from the fingerprint.
3. **You confirm** the current Terms of Service and access rules before ingesting.
4. Ask CoCo to help you do the **smallest validated first pull**, then load it.

## Unmask prompts (copy-paste)

**Source A — search interest**
> "Read `sources/source_A_search_interest.md`. Based on this fingerprint — a free 0–100
> relative search-interest index, per-query rescaling, a stable entity/topic ID system, and
> an anchor-term normalization — what is the most likely public source and Python client?
> How do I get the entity-lookup key, and what's the smallest validated pull for one film?"

**Source B — trailer comments**
> "Read `sources/source_B_trailer_comments.md`. Which video platform and which official API
> is this? Show me how to pull comments for one trailer with my own key, pseudonymize
> handles on ingest, and load to `{{SANDBOX_DB}}.RESEARCH.TRAILER_COMMENTS_RAW`."

**Source C — encyclopedia pageviews**
> "Read `sources/source_C_encyclopedia_pageviews.md`. Name the source and its keyless daily
> pageview API. Help me resolve one film to its canonical article and pull the pre-release
> window."

**Source D — box office (the label)**
> "Read `sources/source_D_box_office_history.md`. What kind of provider is this, and does it
> offer an official or licensed feed so I don't scrape it? Help me set up licensed access
> and a release-date/OW validation check against a second reference."

**Source E — metadata popularity (excluded)**
> "Read `sources/source_E_metadata_popularity.md`. Name the likely metadata API. I only want
> static fields (budget, runtime, genre). Explain why the popularity score is leakage and
> keep it out of my feature view."

## Your due-diligence checklist (do this, don't skip)

- [ ] Confirm the source CoCo named is actually the one you intend to use.
- [ ] Read that provider's **current** Terms of Service and API/scraping policy.
- [ ] Use **official or licensed** access wherever offered (required for Source D).
- [ ] Get your **own** key; store it in `.env` (never in git, never in a skill file).
- [ ] Pseudonymize any user handles (Source B).
- [ ] Do one small validated pull before bulk ingesting.

Once all sources are identified and access is sorted, go to **`docs/04_stand_up_the_pipeline.md`**.
