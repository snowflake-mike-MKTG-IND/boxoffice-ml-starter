# Source A — Pre-release search & attention demand

## The signal
How much the public is actively searching for or looking up a film in the weeks before it
opens. A rising interest curve ahead of release is one of the strongest, hardest-to-game
demand proxies you can get.

## Options CoCo can help you choose from
Several public and commercial services expose pre-release interest/attention data. Ask CoCo
and it will lay out the common choices with their trade-offs — free vs. paid, an official
API vs. a community client library, geographic coverage, history depth, and rate limits —
then help you pick one that fits your access and budget. Most solo research projects land on
a widely-used free interest index; paid attention-data vendors are alternatives when you
need higher resolution or a guaranteed SLA.

## Things to sort out with whichever you pick
- **Comparability.** Some interest sources return a *relative* index (rescaled per request)
  rather than absolute counts, so two separate pulls aren't on the same scale. The usual fix
  is to include a stable, high-volume reference term in each pull and normalize against a
  standalone baseline of that reference — CoCo will tailor the exact method to your source.
- **Disambiguation.** Track the *film*, not every search that happens to share its title.
  Most sources offer a stable topic/entity ID or an exact-match mode; prefer that over
  free-text, which pulls in unrelated results.
- **Access.** May need an API key plus a locale/timezone config; expect throttling, so build
  in backoff and validate a new title's pull against the source's own UI before trusting it.

## Feeds these columns
- `SEARCH_INTEREST`, `SEARCH_ANCHOR_BASELINE`, `ENTITY_IDS`
- Downstream: rolling / peak / velocity **demand percentiles by horizon** (−21/−14/−7/−3 days)
  in `DEMAND_PERCENTILES`.

## Ask CoCo
> "Read `sources/source_A_search_interest.md`. What are my options for a pre-release
> search/attention demand signal? Compare a couple of free and paid choices, recommend one
> for a solo research project, explain how to normalize it and disambiguate the title, and
> help me pull a validated sample for one film."
