# CoCo prompt library

Copy-paste prompts for building the pipeline with Cortex Code. Fill in `{{SANDBOX_DB}}` and
your role. Order roughly follows `docs/01`→`06`.

---

## Setup

**Connect & orient**
> "Read `COCO.md` and `docs/`. Summarize what we're building and confirm my Snowflake
> connection works. My sandbox is `{{SANDBOX_DB}}`, role `{{SANDBOX_ROLE}}`."

**Sandbox request**
> "I don't have a sandbox yet. Using `docs/02`, draft the exact message and the grant SQL my
> data team needs, scoped to full build rights inside one database only."

**Create schema**
> "Run `sql/00_schema.sql` against `{{SANDBOX_DB}}`, substituting the database name. Then
> list the tables you created and confirm they're empty."

---

## Research the sources

**Source A — search & attention demand**
> "Read `sources/source_A_search_interest.md`. What are my options for a pre-release
> search/attention signal, free and paid? Recommend one, explain how to normalize it and
> disambiguate the title, and do one validated pull for a test film."

**Source B — trailer conversation**
> "Read `sources/source_B_trailer_comments.md`. What are my options, and which official API
> should I use? Pull one trailer's comments with my key, pseudonymize handles, load to
> `TRAILER_COMMENTS_RAW`."

**Source C — consumer research pageview demand**
> "Read `sources/source_C_research_pageviews.md`. What are my options for a consumer-research pageview
> demand signal with an open API? Resolve one film to its canonical page and pull the
> pre-release window."

**Source D — box office**
> "Read `sources/source_D_box_office_history.md`. What are my options, and which offer
> official/licensed access? Set one up and a date/OW validation check against a second
> reference."

**Source E — title metadata (use with care)**
> "Read `sources/source_E_metadata_popularity.md`. What are my options? Pull static fields
> only and explain why a live popularity score is leakage."

---

## Ingest & process

**Score comments with AISQL**
> "Update `sql/20_intent_scoring_aisql.sql` to current Cortex AISQL syntax and a good
> available model, run it, and show me per-film volume + net intent %."

**Demand percentiles**
> "From `SEARCH_INTEREST` and `PAGEVIEW_DEMAND`, build `DEMAND_PERCENTILES` at
> horizons -21/-14/-7/-3 (cumulative, rolling, peak, velocity)."

**Feature view**
> "Run `sql/10_feature_view.sql` and sanity-check `OW_FEATURES` — row count, avg comment
> volume, avg net intent, and any films missing signals."

**Refresh**
> "Use the `pipeline-refresh` skill to find films releasing in the next 3 weeks and refresh
> all their signals; fill opening weekends for films that already released."

---

## Keys & safety

> "Walk me through getting my own key for Source <X>, tell me its rate limits, store it in
> the secret store, and use it via `secret_env` so the value never appears in chat or files."

---

## Model (rigorous validation)

> "Using `OW_FEATURES`, build a walk-forward temporal backtest for log opening weekend.
> Compare a tier-classifier baseline vs a distributional regressor on the SAME films and
> splits. Report MAPE, median APE, and large-film tail error. Keep pedigree gated behind
> demand and exclude any leakage features."
