# 06 — Model overview (the honest version)

This repo gets you to a research-ready feature set. How you model it is up to you, but here
is the approach that held up under honest validation — and, just as important, the traps
that didn't.

## The two signals that carry the weight

- **Comment volume** (Source B): how much organic conversation a trailer generates. This is
  the single strongest input — it does most of the predictive work on its own.
- **Net intent** (Source B, via AISQL): the direction of the conversation
  (theatrical-leaning minus skip-leaning). Weak in isolation, but nearly **independent** of
  volume — so the little it carries **stacks additively** on top of volume rather than
  echoing it.

Add **demand percentiles** (Sources A + C) — search interest and encyclopedia pageviews —
and you have a demand-forward feature set that doesn't lean on gameable marketing numbers.

## Validate the honest way: walk-forward in time

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

## Pedigree belongs behind demand

Static "pedigree" features (budget, star power, franchise history, a predecessor's gross)
feel predictive but encourage the model to believe hype. The version that generalized
**dropped standalone pedigree entirely** and let it re-enter only **gated behind demand**
(e.g., demand-percentile × star power). If the crowd isn't showing up in the signals,
pedigree shouldn't rescue the prediction.

## Leakage watch

Exclude any feature contaminated by post-announcement or post-release activity — notably things like screen count which can change up to opening weekend and reflect expectations of the buyers and distributors which may or may not be warranted when final numbers are released. 

## Build it with CoCo

> "Using `{{SANDBOX_DB}}.RESEARCH.OW_FEATURES`, build a walk-forward temporal backtest that
> predicts log opening weekend, compares a tier-classifier baseline against a distributional
> regressor on the **same** films and splits, and reports MAPE, median APE, and error in the
> large-film tail."
