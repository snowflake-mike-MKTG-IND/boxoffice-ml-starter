# Data source dossiers

The files in this folder describe each signal the pipeline uses — **without naming the
provider**. That's deliberate. Data-provider identities and their data are not ours to
redistribute, and some providers restrict how their data may be accessed.

Instead, each dossier is a **fingerprint**: what the signal is, how it behaves, how it's
typically accessed, its quirks and gotchas, and the schema columns it feeds. That's enough
for Cortex Code to identify the most likely real source when you ask — and then to help
you set it up against **your own** access.

## The unmask pattern

Open the repo in Cortex Code and ask, for any dossier:

> "Read `sources/source_A_search_interest.md`. Based on this fingerprint, what public data
> source and Python client library is this most likely describing? How would I obtain
> access, and what's the smallest first pull to validate it?"

CoCo will name the likely source, the access method, and the client, then walk you through
setup. Repeat per source. The full prompt set is in `../prompts/coco_prompt_library.md`.

## Why oblique instead of just listing them?

- It keeps provider names and any implied endorsement out of a public repo.
- It forces a moment of due diligence: when CoCo names a source, **you** confirm its
  current Terms of Service and access rules before ingesting. Fingerprints age; ToS change.

## The five signals

| Dossier | Signal | In the model? |
|---|---|---|
| `source_A_search_interest.md` | Normalized search-interest index per title | Yes (demand) |
| `source_B_trailer_comments.md` | Public trailer-comment volume + AI-scored intent | Yes (the core signal) |
| `source_C_encyclopedia_pageviews.md` | Encyclopedia pageview demand | Yes (demand) |
| `source_D_box_office_history.md` | Historical grosses + opening weekends (the label) | Yes (target + history) |
| `source_E_metadata_popularity.md` | Third-party metadata popularity score | **No — excluded as leakage** |

Read `docs/03_identify_your_sources.md` for the guided flow.
