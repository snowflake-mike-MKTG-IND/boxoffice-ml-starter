# 06 — Model overview

This repo gets you to a research-ready feature set. How you model it is up to you, but here
is the approach that held up under rigorous, out-of-sample validation — and, just as
important, the traps that didn't.

## The two signals that carry the weight

- **Comment volume** (Source B): how much organic conversation a trailer generates. This is
  the single strongest input — it does most of the predictive work on its own.
- **Net intent** (Source B, via AISQL): the direction of the conversation
  (theatrical-leaning minus skip-leaning). Weak in isolation, but nearly **independent** of
  volume — so the little it carries **stacks additively** on top of volume rather than
  echoing it.

Add **demand percentiles** (Sources A + C) — search interest and consumer research pageviews —
and you have a demand-forward feature set that doesn't lean on gameable marketing numbers.

## Validate out-of-sample: walk-forward in time

Do **not** report accuracy from random k-fold cross-validation on all films — it lets the
model peek at the future. Use **temporal (walk-forward) validation**: sort films by release
date, train only on films released *before* each one, and predict forward. It's harder and
lower-scoring, but it's the only number that reflects real prediction-time performance.

> When you compare two models, hold **everything** constant except the thing you're testing
> — same films, same features, same temporal splits. Comparing a model on an easy film set
> against another on a hard one produces a flattering lie.

## Architecture note: prefer a distributional regressor over a tier classifier

An early instinct is to classify films into size tiers (small / mid / large) and regress
within each. That framing **caps the top** — the biggest films get pulled back toward the
pack and systematically under-predicted. A single model that predicts the opening directly
and reports a **confidence range** (a distribution, not one number) avoids the ceiling and
handles blockbusters through the upper band rather than a fragile point estimate.

On matched films under identical walk-forward validation, moving from the tier-classifier
framing to a distributional one cut average error (MAPE) by a few points — concentrated in
the **tail** (fewer large misses), with the typical/median error roughly unchanged.

This is the short version. The full framework — the two blended learners, the
residual-mixture distribution (HDR band / Bayes point / P78 upside), the demand-forward flag
and point-lift, and the exact validation and flop-safety loss — is in
**`docs/07_model_architecture.md`**, with a runnable reference implementation in
**`model/train_ow_model.py`**.

## Pedigree belongs behind demand

Static "pedigree" features (budget, star power, franchise history, a predecessor's gross)
feel predictive but encourage the model to believe hype. The version that generalized
**dropped standalone pedigree entirely** and let it re-enter only **gated behind demand**
(e.g., demand-percentile × star power). If the crowd isn't showing up in the signals,
pedigree shouldn't rescue the prediction.

## Leakage watch

Exclude any feature contaminated by post-announcement or post-release activity — notably things like screen count which can change up to opening weekend and reflect expectations of the buyers and distributors which may or may not be warranted when final numbers are released. 

## Build it with CoCo

The full architecture and a copy-paste build/backtest prompt live in
**`docs/07_model_architecture.md`** (reference implementation: `model/train_ow_model.py`).
In short: point CoCo at `{{SANDBOX_DB}}.RESEARCH.OW_FEATURES`, run the walk-forward backtest,
and compare the distributional regressor against a tier-classifier baseline on the **same**
films and splits.
