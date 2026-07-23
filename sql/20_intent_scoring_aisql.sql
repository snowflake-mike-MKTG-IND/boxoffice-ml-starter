-- 20_intent_scoring_aisql.sql — score trailer comments with Snowflake Cortex AISQL.
-- Turns raw comment text into sentiment + intent (theatrical / streaming / pass).
-- Replace {{SANDBOX_DB}}. Requires access to Cortex AISQL functions (see docs/02).
--
-- This is a TEMPLATE. Model names and exact AISQL function signatures evolve —
-- ask CoCo: "update this to the current Cortex AISQL syntax and a good available model."

USE SCHEMA {{SANDBOX_DB}}.RESEARCH;

-- Option 1: classification + sentiment via AI_CLASSIFY / AI_SENTIMENT ---------
-- Score each raw comment into a single intent label and a sentiment score, then
-- pivot the label into the 1/0 intent flags the feature view expects.

INSERT INTO TRAILER_COMMENTS_SCORED
    (MOVIE_ID, COMMENT_ID, COMMENT_TEXT, LIKE_COUNT,
     SENTIMENT_SCORE, SENTIMENT_BUCKET, THEATRICAL_INTENT, STREAMING_INTENT, PASS_INTENT)
WITH scored AS (
    SELECT
        r.MOVIE_ID,
        r.COMMENT_ID,
        r.COMMENT_TEXT,
        r.LIKE_COUNT,
        AI_SENTIMENT(r.COMMENT_TEXT):categories[0]:sentiment::STRING    AS sent_label,
        AI_CLASSIFY(
            r.COMMENT_TEXT,
            ['theatrical','streaming','pass','other']
        ):labels[0]::STRING                                             AS intent_label
    FROM TRAILER_COMMENTS_RAW r
    WHERE r.COMMENT_TEXT IS NOT NULL
)
SELECT
    MOVIE_ID,
    COMMENT_ID,
    COMMENT_TEXT,
    LIKE_COUNT,
    -- AI_SENTIMENT returns a label; map it to a numeric score the feature view can average
    CASE sent_label WHEN 'positive' THEN 1 WHEN 'negative' THEN -1 ELSE 0 END AS SENTIMENT_SCORE,
    sent_label                                                              AS SENTIMENT_BUCKET,
    IFF(intent_label = 'theatrical', 1, 0)                              AS THEATRICAL_INTENT,
    IFF(intent_label = 'streaming',  1, 0)                              AS STREAMING_INTENT,
    IFF(intent_label = 'pass',       1, 0)                              AS PASS_INTENT
FROM scored;

-- Option 2 (alternative): one AI_COMPLETE call returning structured JSON -------
-- Useful if you want sentiment + intent + a rationale in a single pass. Ask CoCo
-- to generate a version using AI_COMPLETE with a JSON response schema, e.g.:
--   {"sentiment": "positive|negative|neutral|mixed", "intent": "theatrical|streaming|pass|other"}
-- then parse the JSON into the same columns as above.

-- Per-film aggregate the feature view will read (sanity check):
--   SELECT MOVIE_ID,
--          COUNT(*)                                             AS comment_volume,
--          AVG(SENTIMENT_SCORE)                                 AS avg_sent,
--          100.0*AVG(THEATRICAL_INTENT)                         AS pct_theatrical,
--          100.0*AVG(PASS_INTENT)                               AS pct_pass,
--          100.0*(AVG(THEATRICAL_INTENT) - AVG(PASS_INTENT))    AS net_intent_pct
--   FROM TRAILER_COMMENTS_SCORED GROUP BY MOVIE_ID;
