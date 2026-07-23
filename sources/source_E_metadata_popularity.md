# Source E — Metadata popularity score (EXCLUDED as leakage)

This dossier exists to explain a source you should **know about but not use** in the model.

## What it is
A large, community-maintained **movie metadata database** exposes an API that includes a
per-title **"popularity" score** — a platform-internal engagement metric updated daily.

## Fingerprint
- A well-known metadata API (keyed) returning cast, budget, runtime, genres, and a
  changing numeric **popularity** field.
- The popularity score updates continuously based on activity *on that platform*, including
  activity that spikes **around and after** release.

## Why it's excluded from the model
It looks like a strong predictor and early versions leaned on it — but its popularity value
is contaminated by information that co-moves with the outcome (it reflects buzz that itself
responds to the release). Using it inflates offline accuracy and **leaks** signal you won't
have cleanly at true prediction time. In honest, walk-forward validation it does not hold
up, so the current model **drops it entirely**.

You may still use this API for **static metadata** (budget, runtime, genre, cast) if you
lack another source — just **never** feed the live popularity score into the model.

## If you use it for static fields only
- Key in `.env` as `METADATA_API_KEY`.
- Pull once, store static attributes; ignore the popularity field for modeling.

## Ask CoCo
> "Read `sources/source_E_metadata_popularity.md`. Name the likely metadata API. I only
> want static fields (budget, runtime, genre). Explain concretely why its popularity score
> is a leakage risk and make sure it never enters my feature view."
