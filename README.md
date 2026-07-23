# Box-Office-ML-Starter

A hands-on starter kit for reproducing a piece of applied research: **can the organic conversation around a movie trailer predict its opening weekend better than the marketing metrics everyone already games?**

This repo will help you build repeatable way to stand up the *pipeline* yourself, inside your own Snowflake account, guided end-to-end by **Cortex Code (CoCo)** — Snowflake's agentic desktop IDE.

You bring your own data access. The repo brings the method, the schema, the guardrails, and a set of CoCo prompts that walk you from an empty sandbox to a research-ready feature set.

---

## What you'll end up with

- A **dedicated Snowflake sandbox** you fully control.
- An **empty, source-agnostic schema** for films, releases, box office, trailer comments, search interest, and encyclopedia demand.
- **Ingestion + normalization + AI scoring** for each signal, built against *your own* data access.
- A **feature view** suitable for leakage-free, walk-forward temporal modeling.

## How to use it

1. **`docs/01_install_cortex_code.md`** — install CoCo Desktop and connect it to your Snowflake account.
2. **`docs/02_request_a_sandbox.md`** — get a dedicated sandbox database from your data team (copy-paste request included).
3. **`docs/03_identify_your_sources.md`** — use the `sources/` dossiers + CoCo to research signal source.
4. **`docs/04_stand_up_the_pipeline.md`** — create the schema and ingest each signal.
5. **`docs/05_api_keys_with_coco.md`** — get and store the keys you need, safely.
6. **`docs/06_model_overview.md`** — the modeling method (feature set + walk-forward validation) at a high level.

`COCO.md` is loaded automatically by Cortex Code when you open this folder — it primes the agent to act as your setup guide.

---


## License

MIT for the code and templates in this repo. **No data is included or licensed** — data access and rights are entirely your responsibility.
