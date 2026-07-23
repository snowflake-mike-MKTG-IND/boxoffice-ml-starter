# Source A — Normalized search-interest index

## What it is
A free, public index of **relative search interest** in a topic over time. Values are not
absolute search counts; they're rescaled **0–100 within each query**, where 100 is the
peak point of that particular pull. This per-query rescaling is the single most important
quirk to understand.

## Fingerprint
- Web UI lets you compare a handful of terms over a time window and region; there's a
  popular **unofficial Python client** that automates the same pulls.
- Returns a date-indexed series per term, each on a shared 0–100 scale *within one query*.
- Two different pulls are **not** on the same scale — a "60" today and a "60" last month
  are not comparable unless they were co-scaled in the same request.
- Free-text queries are ambiguous: searching a film's title also matches unrelated things
  with the same words. The provider has a **stable entity/topic ID** system (from a related
  knowledge/entity service) that disambiguates — using the entity ID tracks *the film*,
  not the words.

## Known gotchas (learned the hard way)
- **Always use the entity/topic ID, never free text.** Free text can invert the signal
  (e.g., a generic term dominates the film). Validate against the provider's own UI.
- **Normalize with an anchor term.** Because every pull is rescaled 0–100, you can't stitch
  pulls into a continuous timeline directly. The fix: include a **stable, high-volume anchor
  term** (something evergreen and movie-related) in *every* comparison pull, then use a
  separate standalone pull of the anchor over a long window to build a continuous baseline.
  Normalize each movie pull against the anchor's co-scaled value. See the
  `search-interest-normalize` skill for the exact two-query method.
- The anchor term's **text** matters for manual URL exports — an entity ID for the anchor
  can resolve to the wrong concept. Use the literal anchor text in URLs.

## Access
- The unofficial client needs no API key but does need a locale/timezone config and is
  rate-limited (expect throttling; back off and retry).
- The **entity-ID lookup** service *does* need an API key (`SEARCH_ENTITY_API_KEY` in
  `.env`). There's also a keyless fallback that returns topic IDs via the client's
  suggestions endpoint.

## Feeds these columns
- `SEARCH_INTEREST` (per movie, per date): raw movie interest + co-scaled anchor value.
- `SEARCH_ANCHOR_BASELINE`: the normalized continuous anchor timeline.
- `ENTITY_IDS`: movie → stable entity/topic ID mapping.
- Downstream: rolling/peak/velocity **demand percentiles by horizon** (−21/−14/−7/−3 days).

## Ask CoCo
> "Read `sources/source_A_search_interest.md`. Name the most likely public source and its
> Python client. Explain the entity-ID lookup and the anchor-normalization, then help me do
> one validated pull for a test film and store the entity ID."
