-- 10_feature_view.sql — assemble the modeling matrix, one row per (MOVIE_ID, DAYS_OUT).
-- Replace {{SANDBOX_DB}}. This is an illustrative-but-faithful reconstruction of the
-- demand-forward feature set — NOT a 1:1 copy of any production view.
--
-- Design choices that mirror the reference model:
--  * Grain = one row per film per pre-release horizon (DAYS_OUT in -21/-14/-7/-3), so the
--    demand signals are read as-of each horizon.
--  * Feature families: trailer conversation (volume + decomposed intent + sentiment),
--    search & pageview DEMAND percentiles, genre/rating/runtime/season, quality-adjusted
--    demand, and demand-gated pedigree interactions.
--  * PEDIGREE IS GATED: budget / star power / predecessor gross / IP tier are NOT used as
--    standalone features. They enter ONLY multiplied by demand (e.g. SEARCH7_X_STAR), so the
--    model can't lean on hype the crowd isn't backing. See docs/06_model_overview.md.
--  * NO leakage feature (a live popularity score) — deliberately absent.

USE SCHEMA {{SANDBOX_DB}}.RESEARCH;

CREATE OR REPLACE VIEW OW_FEATURES AS
WITH comment_agg AS (          -- one aggregate per film (comments as of release)
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
    -- keys / grain
    dp.MOVIE_ID,
    m.MOVIE_TITLE,
    rd.RELEASE_DATE,
    dp.DAYS_OUT,
    -- target
    bo.OPENING_WEEKEND,
    LN(bo.OPENING_WEEKEND)                                          AS LOG_OPENING_WEEKEND,
    bo.THEATER_COUNT,

    -- ── Source B: the core signal (volume + decomposed intent + sentiment) ──
    c.YT_COMMENTS,
    c.LOG_YT,
    c.AVG_SENT,
    c.PCT_THEA, c.PCT_PASS, c.PCT_POS, c.PCT_NEG,
    c.NET_INTENT_PCT,

    -- ── Sources A + C: demand percentiles as of this horizon ──
    dp.SEARCH_ROLLING_3D_PCTILE, dp.SEARCH_ROLLING_7D_PCTILE, dp.SEARCH_ROLLING_14D_PCTILE,
    dp.SEARCH_PEAK_PCTILE, dp.SEARCH_VEL_PCTILE, dp.SEARCH_SLOPE_PCTILE,
    dp.PAGEVIEW_R7D_PCTILE, dp.PAGEVIEW_PEAK_PCTILE, dp.PAGEVIEW_CUM_PCTILE, dp.PAGEVIEW_VEL_PCTILE,

    -- ── calendar / content (standalone is fine for these) ──
    MONTH(rd.RELEASE_DATE)                                         AS RELEASE_MONTH,
    IFF(MONTH(rd.RELEASE_DATE) IN (5,6,7,11,12), 1, 0)             AS IS_PEAK_SEASON,
    m2.RUNTIME,
    m2.GENRE_ACTION_FRANCHISE, m2.GENRE_HORROR, m2.GENRE_ANIMATION_FAMILY, m2.GENRE_ORIGINAL,
    m2.RATING_G, m2.RATING_PG, m2.RATING_PG13, m2.RATING_R,

    -- ── quality-adjusted demand: demand weighted by how the intent leans ──
    (1/(1+EXP(-0.2*c.NET_INTENT_PCT)))                             AS QMULT,
    dp.SEARCH_ROLLING_7D_PCTILE * (1/(1+EXP(-0.2*c.NET_INTENT_PCT))) AS QADJ_SEARCH,
    dp.PAGEVIEW_PEAK_PCTILE     * (1/(1+EXP(-0.2*c.NET_INTENT_PCT))) AS QADJ_PAGEVIEW,

    -- ── demand-gated PEDIGREE interactions (pedigree only counts when demand backs it) ──
    dp.SEARCH_ROLLING_7D_PCTILE * m2.MAX_STAR_POWER                AS SEARCH7_X_STAR,
    dp.SEARCH_ROLLING_7D_PCTILE * m2.IP_HIGH_PROFILE               AS SEARCH7_X_IP_HIGH,
    dp.SEARCH_ROLLING_7D_PCTILE * m2.PREDECESSOR_OW_LOG            AS SEARCH7_X_PREDOW,
    dp.SEARCH_ROLLING_7D_PCTILE * m2.GENRE_ACTION_FRANCHISE        AS SEARCH7_X_ACTION,
    dp.SEARCH_ROLLING_7D_PCTILE * m2.GENRE_HORROR                  AS SEARCH7_X_HORROR,
    dp.PAGEVIEW_PEAK_PCTILE     * m2.MAX_STAR_POWER                AS PAGEVIEWPK_X_STAR,

    -- ── intent × demand interactions ──
    c.AVG_SENT       * dp.SEARCH_ROLLING_7D_PCTILE                 AS SENT_X_SEARCH7,
    c.PCT_THEA       * dp.SEARCH_ROLLING_7D_PCTILE                 AS THEA_X_SEARCH7,
    c.NET_INTENT_PCT * dp.SEARCH_ROLLING_7D_PCTILE                 AS NET_X_SEARCH7,
    c.NET_INTENT_PCT * dp.PAGEVIEW_PEAK_PCTILE                     AS NET_X_PAGEVIEWPK,
    c.AVG_SENT       * dp.PAGEVIEW_PEAK_PCTILE                     AS SENT_X_PAGEVIEWPK,
    c.PCT_THEA       * dp.PAGEVIEW_PEAK_PCTILE                     AS THEA_X_PAGEVIEWPK

FROM DEMAND_PERCENTILES dp
JOIN MOVIE_MAP m                 ON dp.MOVIE_ID = m.MOVIE_ID
JOIN RELEASE_DATES rd            ON dp.MOVIE_ID = rd.MOVIE_ID
JOIN BOX_OFFICE bo               ON dp.MOVIE_ID = bo.MOVIE_ID
LEFT JOIN comment_agg c          ON dp.MOVIE_ID = c.MOVIE_ID
LEFT JOIN MOVIE_METADATA m2      ON dp.MOVIE_ID = m2.MOVIE_ID
WHERE dp.MOVIE_ID NOT IN (SELECT MOVIE_ID FROM REMOVE_FROM_MODEL)
  AND bo.OPENING_WEEKEND IS NOT NULL
  AND (bo.THEATER_COUNT >= 1000 OR bo.THEATER_COUNT IS NULL)
  AND COALESCE(m2.GENRE_PRESTIGE, 0) = 0;      -- reference model scopes out awards-season prestige
