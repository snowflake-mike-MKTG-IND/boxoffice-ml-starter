-- 00_schema.sql — source-agnostic schema for the trailer-signal pipeline.
-- No data. Replace {{SANDBOX_DB}} with your sandbox database (see docs/02).
-- Run in Cortex Code or: snow sql --connection my_sandbox -f sql/00_schema.sql
--
-- Naming is deliberately provider-neutral: SEARCH_* = search/attention demand (Source A),
-- PAGEVIEW_* = consumer-research pageview demand (Source C). Nothing here is a live
-- popularity score — that's excluded as leakage (see sources/source_E_metadata_popularity.md).

USE DATABASE {{SANDBOX_DB}};
CREATE SCHEMA IF NOT EXISTS RESEARCH;
USE SCHEMA RESEARCH;

-- ---------------------------------------------------------------------------
-- Identity / spine
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS MOVIE_MAP (
    MOVIE_ID        NUMBER        PRIMARY KEY,
    MOVIE_TITLE     STRING        NOT NULL          -- Title Case; keep consistent everywhere
);

CREATE TABLE IF NOT EXISTS RELEASE_DATES (
    MOVIE_ID        NUMBER        PRIMARY KEY,
    RELEASE_DATE    DATE          NOT NULL           -- VALIDATE against a 2nd reference (Source D)
);

-- ---------------------------------------------------------------------------
-- Source D — box office (target + history)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS BOX_OFFICE (
    MOVIE_ID        NUMBER        PRIMARY KEY,
    MOVIE_TITLE     STRING,
    OPENING_WEEKEND FLOAT,                            -- domestic OW in dollars (the label)
    THEATER_COUNT   NUMBER                            -- for wide-release filtering
);

-- ---------------------------------------------------------------------------
-- Source A — search / attention interest (relative index) + normalization scaffolding
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ENTITY_IDS (
    MOVIE_ID        NUMBER        PRIMARY KEY,
    MOVIE_TITLE     STRING,
    RELEASE_DATE    DATE,
    ENTITY_ID       STRING,                           -- stable topic/entity id (NOT free text)
    ENTITY_NAME     STRING,
    MATCH_STATUS    STRING
);

CREATE TABLE IF NOT EXISTS SEARCH_INTEREST (
    MOVIE_ID        NUMBER,
    OBS_DATE        DATE,
    INTEREST        FLOAT,                            -- movie interest, co-scaled with anchor
    ANCHOR_INTEREST FLOAT,                            -- anchor term, same-scale within the pull
    PRIMARY KEY (MOVIE_ID, OBS_DATE)
);

CREATE TABLE IF NOT EXISTS SEARCH_ANCHOR_BASELINE (
    OBS_DATE        DATE          PRIMARY KEY,
    ANCHOR_NORM     FLOAT                             -- normalized continuous anchor timeline
);

-- ---------------------------------------------------------------------------
-- Source B — trailer comments (raw + AI-scored)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS TRAILER_COMMENTS_RAW (
    MOVIE_ID        NUMBER,
    VIDEO_ID        STRING,
    COMMENT_ID      STRING,
    AUTHOR_HASH     STRING,                           -- PSEUDONYMIZED handle (hash, never raw)
    COMMENT_TEXT    STRING,
    LIKE_COUNT      NUMBER,
    COMMENT_DATE    DATE
);

CREATE TABLE IF NOT EXISTS TRAILER_COMMENTS_SCORED (
    MOVIE_ID          NUMBER,
    COMMENT_ID        STRING,
    COMMENT_TEXT      STRING,
    LIKE_COUNT        NUMBER,
    SENTIMENT_SCORE   FLOAT,                          -- -1..1 (mapped from AI_SENTIMENT label)
    SENTIMENT_BUCKET  STRING,                         -- 'positive' | 'neutral' | 'negative' | 'mixed'
    THEATRICAL_INTENT NUMBER,                         -- 1/0
    STREAMING_INTENT  NUMBER,                         -- 1/0
    PASS_INTENT       NUMBER                          -- 1/0  (NEUTRAL comment = all three 0)
);

-- ---------------------------------------------------------------------------
-- Source C — consumer research pageview activity
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PAGEVIEW_DEMAND (
    MOVIE_ID        NUMBER,
    OBS_DATE        DATE,
    VIEWS           NUMBER,                           -- absolute daily views
    PRIMARY KEY (MOVIE_ID, OBS_DATE)
);

-- ---------------------------------------------------------------------------
-- Static attributes & pedigree (per film)
-- Your own catalog and/or Source E static fields. NOTE: intentionally NO live
-- popularity score — that co-moves with the outcome and leaks (see source_E).
-- In the model, the raw pedigree columns (budget/star/predecessor/IP) are NOT used
-- standalone — they enter ONLY through demand-gated interactions in OW_FEATURES.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS MOVIE_METADATA (
    MOVIE_ID              NUMBER PRIMARY KEY,
    RUNTIME               NUMBER,
    BUDGET                FLOAT,
    BUDGET_LOG            FLOAT,
    -- star power (from your own cast/history source)
    MAX_STAR_POWER        FLOAT,
    TOP2_STAR_POWER       FLOAT,
    AVG_STAR_POWER        FLOAT,
    NUM_STARS_WITH_HISTORY NUMBER,
    -- franchise / prior title
    PREDECESSOR_OW        FLOAT,
    PREDECESSOR_OW_LOG    FLOAT,
    -- IP tier flags (one-hot)
    KNOWN_IP_TIER         NUMBER,
    IP_HIGH_PROFILE       NUMBER,
    IP_MODERATE           NUMBER,
    IP_NICHE              NUMBER,
    IP_ORIGINAL           NUMBER,
    IS_MAJOR_STUDIO       NUMBER,
    -- genre flags (one-hot)
    GENRE_ACTION_FRANCHISE NUMBER,
    GENRE_HORROR          NUMBER,
    GENRE_ANIMATION_FAMILY NUMBER,
    GENRE_ORIGINAL        NUMBER,
    GENRE_PRESTIGE        NUMBER,
    -- rating flags (one-hot)
    RATING_G              NUMBER,
    RATING_PG             NUMBER,
    RATING_PG13           NUMBER,
    RATING_R              NUMBER
);

-- ---------------------------------------------------------------------------
-- Derived demand percentiles by pre-release horizon (from Source A + Source C).
-- One row per (MOVIE_ID, DAYS_OUT); DAYS_OUT in (-21, -14, -7, -3).
-- Percentiles are ranked ACROSS the film set per horizon (PERCENT_RANK), which tames
-- the huge dynamic range. In production this is often an auto-computing VIEW; a table
-- works fine for a starter build.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS DEMAND_PERCENTILES (
    MOVIE_ID                 NUMBER,
    DAYS_OUT                 NUMBER,
    -- search / attention demand (Source A)
    SEARCH_ROLLING_3D_PCTILE  FLOAT,
    SEARCH_ROLLING_7D_PCTILE  FLOAT,
    SEARCH_ROLLING_14D_PCTILE FLOAT,
    SEARCH_PEAK_PCTILE        FLOAT,
    SEARCH_VEL_PCTILE         FLOAT,                   -- velocity (3d-vs-7d change)
    SEARCH_SLOPE_PCTILE       FLOAT,                   -- log slope, 14d -> 3d
    -- consumer research pageview demand (Source C)
    PAGEVIEW_R7D_PCTILE       FLOAT,
    PAGEVIEW_PEAK_PCTILE      FLOAT,
    PAGEVIEW_CUM_PCTILE       FLOAT,
    PAGEVIEW_VEL_PCTILE       FLOAT,
    PRIMARY KEY (MOVIE_ID, DAYS_OUT)
);

-- Films to exclude from the model (bad data, re-releases, etc.)
CREATE TABLE IF NOT EXISTS REMOVE_FROM_MODEL (
    MOVIE_ID        NUMBER        PRIMARY KEY,
    REASON          STRING
);
