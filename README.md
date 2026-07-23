# Box-Office-ML-Starter

A hands-on starter kit for reproducing a piece of applied research: **can the organic conversation around a movie trailer predict its opening weekend better than the marketing metrics everyone already games?**

This repo does **not** ship data, keys, or a finished model. It ships something more useful: a repeatable way to stand up the *pipeline* yourself, inside your own Snowflake account, guided end-to-end by **Cortex Code (CoCo)** — Snowflake's agentic desktop IDE.

You bring your own data access. The repo brings the method, the schema, the guardrails, and a set of CoCo prompts that walk you from an empty sandbox to a research-ready feature set.

---

## What you'll end up with

- A **dedicated Snowflake sandbox** you fully control.
- An **empty, source-agnostic schema** for films, releases, box office, trailer comments, search interest, and encyclopedia demand.
- **Ingestion + normalization + AI scoring** for each signal, built against *your own* data access.
- A **feature view** suitable for honest, walk-forward temporal modeling.

## What this repo will *not* do for you

- It won't hand you anyone else's data. Third-party data is not ours to reshare — you ingest it yourself, under your own terms of access.
- It won't hand you API keys. You'll get your own and store them locally (never in git).
- It won't name the sources for you in these files. Instead, `sources/` contains **dossiers** — fingerprints of each signal — and CoCo will help you identify the real source from those fingerprints when you ask. See `docs/03_identify_your_sources.md`.

## How to use it

1. **`docs/01_install_cortex_code.md`** — install CoCo Desktop and connect it to your Snowflake account.
2. **`docs/02_request_a_sandbox.md`** — get a dedicated sandbox database from your data team (copy-paste request included).
3. **`docs/03_identify_your_sources.md`** — use the `sources/` dossiers + CoCo to identify each signal source.
4. **`docs/04_stand_up_the_pipeline.md`** — create the schema and ingest each signal.
5. **`docs/05_api_keys_with_coco.md`** — get and store the keys you need, safely.
6. **`docs/06_model_overview.md`** — the modeling method (feature set + walk-forward validation) at a high level.

`COCO.md` is loaded automatically by Cortex Code when you open this folder — it primes the agent to act as your setup guide.

---

## Ethics & compliance (read before you ingest anything)

- **Do not reshare ingested third-party data.** Bring your own access. Keep raw pulls out of git (`data/` is ignored).
- **Respect each source's Terms of Service, `robots.txt`, and rate limits.** At least one signal here comes from a provider that has restricted automated access — use official or licensed access, not a scraper. The relevant dossier says so explicitly.
- **Pseudonymize** any user handles you collect from public comments. Store only what the model needs.
- **Keys are yours.** Never commit them. Use `.env` (git-ignored) and `.env.example` as the template.

## License

MIT for the code and templates in this repo. **No data is included or licensed** — data access and rights are entirely your responsibility.
