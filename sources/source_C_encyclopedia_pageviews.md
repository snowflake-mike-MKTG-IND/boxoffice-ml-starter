# Source C — Reference-page demand (pre-release lookups)

## The signal
How many people are pulling up a film's reference/encyclopedia page in the run-up to
release. Like search interest, a rising lookup curve is a clean, hard-to-game demand proxy —
and it tends to be **absolute** counts, so it's directly comparable across films and dates.

## Options CoCo can help you choose from
Some large public reference sites publish **free page-traffic APIs**; other reference and
catalog sources expose similar view/traffic metrics. Ask CoCo for the options and it will
point you to one with an open, keyless API and daily granularity, and note the etiquette
each expects.

## Things to sort out with whichever you pick
- **Exact title matching.** Reference pages have canonical titles with quirks (spacing,
  disambiguation suffixes, release-year variants) and redirects — resolve to the canonical
  page before pulling.
- **Turn counts into features.** Pull daily views across the pre-release window, align to
  days-out horizons (−21/−14/−7/−3), then convert to **percentiles across your film set**
  (cumulative, rolling, peak, velocity) so the huge dynamic range doesn't dominate.
- **Etiquette.** These APIs are usually keyless but ask for a descriptive contact string and
  polite request rates. History doesn't change, so cache aggressively.

## Feeds these columns
- `ENCYCLOPEDIA_PAGEVIEWS` (per movie, per date)
- Downstream: demand percentiles by horizon in `DEMAND_PERCENTILES`.

## Ask CoCo
> "Read `sources/source_C_encyclopedia_pageviews.md`. What are my options for a pre-release
> reference-page demand signal with an open API? Help me resolve one film to its canonical
> page, pull daily views for the pre-release window, and load them to
> `{{SANDBOX_DB}}.RESEARCH.ENCYCLOPEDIA_PAGEVIEWS`."
