# Source D — Box-office history (the label)

This provides the **target** the model predicts (domestic opening weekend) plus the
historical grosses used for predecessor/franchise features.

## What it is
An industry box-office tracker that publishes historical **weekend charts**, per-film
**opening weekends**, theater counts, and release dates.

## Fingerprint
- Web tables of weekend charts (rank, title, weekend gross, theaters, cumulative) and
  per-film pages with a "Domestic Releases:" date and opening-weekend figure.
- Predictable URL structure by date and by film slug + year.
- The label you care about is **domestic opening weekend**; you also want theater count
  (to filter wide releases) and an accurate **release date** (a wrong date corrupts the
  whole pre-release feature window).

## ⚠️ Access restriction — read this first
This kind of provider has **restricted automated scraping** (they moved to block AI
scrapers). **Do not build a scraper against it.** Instead:

- Use an **official/licensed data feed or API** if the provider offers one
  (`BOXOFFICE_ACCESS_TOKEN` in `.env`), or
- Use a properly licensed box-office dataset, or
- Enter/curate the handful of figures you need manually for your research set.

Always confirm the current Terms of Service before any programmatic access. Respect it.

## Data-quality discipline (this bit its predecessors)
- **Validate every release date** against a second reference before pulling pre-release
  signals — a wrong date silently corrupts the days-out alignment and the release-month
  feature.
- **Verify opening-weekend figures** independently after release. A past audit of a
  training set found fabricated OW values and corrupted dates — never trust a fresh value
  without a second source.

## Feeds these columns
- `BOX_OFFICE`: `MOVIE_ID`, `MOVIE_TITLE`, `OPENING_WEEKEND`, `THEATER_COUNT`.
- `RELEASE_DATES`: `MOVIE_ID`, `RELEASE_DATE` (validated).

## Ask CoCo
> "Read `sources/source_D_box_office_history.md`. What kind of source is this, and does it
> offer an official/licensed feed I can use instead of scraping? Help me set up licensed
> access, and build a release-date + opening-weekend validation check against a second
> reference before I trust any value."
