-- 10_feature_view.sql — assemble one modeling row per film from the signal tables.
-- Replace {{SANDBOX_DB}}. Mirrors the demand-forward feature set:
--   volume + decomposed intent (Source B), search + encyclopedia demand percentiles
--   (Source A + C), static metadata (Source E, static fields only), target (Source D).
-- Pedigree (budget/star/etc.) is intentionally kept minimal and, in the model, only
-- enters gated behind demand — see docs/06_model_overview.md.

USE SCHEMA {{SANDBOX_DB}}.RESEARCH;

CREATE OR REPLACE VIEW OW_FEATURES AS
WITH comment_agg AS (
    SELECT
        MOVIE_ID,
        COUNT(*)                                            AS YT_COMMENTS,
        LN(1 + COUNT(*))                                    AS LOG_YT,
        AVG(SENTIMENT_SCORE)                                AS AVG_SENT,
        100.0*AVG(THEATRICAL_INTENT)                        AS PCT_THEA,
        100.0*AVG(PASS_INTENT)                              AS PCT_PASS,
        100.0*AVG(IFF(SENTIMENT_BUCKET='positive',1,0))     AS PCT_POS,
        100.0*AVG(IFF(SENTIMENT_BUCKET='negative',1,0))     AS PCT_NEG,
        100.0*(AVG(THEATRICAL_INTENT) - AVG(PASS_INTENT))   AS NET_INTENT_PCT
    FROM TRAILER_COMMENTS_SCORED
    GROUP BY MOVIE_ID
)
SELECT
    m.MOVIE_ID,
    m.MOVIE_TITLE,
    rd.RELEASE_DATE,
    MONTH(rd.RELEASE_DATE)                                   AS RELEASE_MONTH,
    bo.OPENING_WEEKEND,                                      -- target
    bo.THEATER_COUNT,
    -- Source B: the core signal
    c.YT_COMMENTS, c.LOG_YT, c.AVG_SENT,
    c.PCT_THEA, c.PCT_PASS, c.PCT_POS, c.PCT_NEG, c.NET_INTENT_PCT,
    -- Source A + C: demand percentiles at the final pre-release horizon
    dp.ROLLING_7D_PCTILE, dp.ROLLING_14D_PCTILE, dp.TRENDS_PEAK_PCTILE,
    dp.WIKI_R7D_PCTILE, dp.WIKI_PEAK_PCTILE, dp.WIKI_CUM_PCTILE,
    -- Source E (static only)
    meta.BUDGET, meta.RUNTIME, meta.GENRE, meta.RATING,
    -- example demand x intent / demand x pedigree interactions (built in the model layer)
    (dp.ROLLING_7D_PCTILE * c.NET_INTENT_PCT)               AS NET_X_DEMAND
FROM MOVIE_MAP m
JOIN RELEASE_DATES rd            ON m.MOVIE_ID = rd.MOVIE_ID
JOIN BOX_OFFICE bo               ON m.MOVIE_ID = bo.MOVIE_ID
LEFT JOIN comment_agg c          ON m.MOVIE_ID = c.MOVIE_ID
LEFT JOIN DEMAND_PERCENTILES dp  ON m.MOVIE_ID = dp.MOVIE_ID AND dp.DAYS_OUT = -3
LEFT JOIN MOVIE_METADATA meta    ON m.MOVIE_ID = meta.MOVIE_ID
WHERE m.MOVIE_ID NOT IN (SELECT MOVIE_ID FROM REMOVE_FROM_MODEL)
  AND bo.OPENING_WEEKEND IS NOT NULL
  AND (bo.THEATER_COUNT >= 1000 OR bo.THEATER_COUNT IS NULL);
