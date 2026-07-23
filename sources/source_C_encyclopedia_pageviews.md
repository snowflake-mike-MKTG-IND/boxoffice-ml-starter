# Source C — Encyclopedia pageview demand

## What it is
Daily **pageview counts** for a film's article on a large, community-maintained online
encyclopedia. A rising pageview curve in the weeks before release is a clean, hard-to-game
proxy for genuine audience curiosity.

## Fingerprint
- The encyclopedia publishes a **free, keyless pageview REST API** returning daily view
  counts for any article, by title, over a date range, with per-article granularity.
- Article titles are canonical and need exact matching (spaces vs underscores, disambiguation
  suffixes like "(film)" or a year). Redirects are common — resolve to the canonical title.
- Counts are absolute (real view numbers), unlike Source A's relative index — so these are
  directly comparable across films and dates.

## Processing
Pull daily views for each film's article across the pre-release window, align to
**days-out** horizons (−21/−14/−7/−3), then convert to **percentiles across the film set**
(cumulative, 7-day rolling, peak-day, velocity). Percentiles keep the feature robust to the
platform's huge dynamic range.

## Access & etiquette
- No API key. The provider asks that you send a descriptive contact string in your
  request identification (`PAGEVIEW_CONTACT` in `.env`) and keep request rates polite.
- Cache aggressively; historical pageviews don't change, so pull once and store.

## Feeds these columns
- `ENCYCLOPEDIA_PAGEVIEWS` (per movie, per date): daily views.
- Downstream: cumulative / rolling / peak / velocity **demand percentiles by horizon** in
  `DEMAND_PERCENTILES`.

## Ask CoCo
> "Read `sources/source_C_encyclopedia_pageviews.md`. Name the source and its pageview API
> endpoint shape. Help me resolve a film to its canonical article title, pull daily views
> for the pre-release window, and load them to `{{SANDBOX_DB}}.RESEARCH.ENCYCLOPEDIA_PAGEVIEWS`."
