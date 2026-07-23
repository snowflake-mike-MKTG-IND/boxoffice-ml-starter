-- 00_schema.sql — empty, source-agnostic schema for the trailer-signal pipeline.
-- No data. Replace {{SANDBOX_DB}} with your sandbox database (see docs/02).
-- Run in Cortex Code or: snow sql --connection my_sandbox -f sql/00_schema.sql

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
    RELEASE_DATE    DATE          NOT NULL           -- VALIDATE against a 2nd reference (Source D dossier)
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
-- Source A — search interest (relative index) + normalization scaffolding
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
    SENTIMENT_SCORE   FLOAT,                          -- -1..1
    SENTIMENT_BUCKET  STRING,                         -- 'positive' | 'neutral' | 'negative'
    THEATRICAL_INTENT NUMBER,                         -- 1/0
    STREAMING_INTENT  NUMBER,                         -- 1/0
    PASS_INTENT       NUMBER                          -- 1/0
);

-- ---------------------------------------------------------------------------
-- Source C — encyclopedia pageviews
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ENCYCLOPEDIA_PAGEVIEWS (
    MOVIE_ID        NUMBER,
    OBS_DATE        DATE,
    VIEWS           NUMBER,
    PRIMARY KEY (MOVIE_ID, OBS_DATE)
);

-- ---------------------------------------------------------------------------
-- Derived demand percentiles by pre-release horizon (from A + C)
-- horizons: DAYS_OUT in (-21, -14, -7, -3)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS DEMAND_PERCENTILES (
    MOVIE_ID              NUMBER,
    DAYS_OUT              NUMBER,
    ROLLING_7D_PCTILE     FLOAT,
    ROLLING_14D_PCTILE    FLOAT,
    TRENDS_PEAK_PCTILE    FLOAT,
    WIKI_R7D_PCTILE       FLOAT,
    WIKI_PEAK_PCTILE      FLOAT,
    WIKI_CUM_PCTILE       FLOAT,
    PRIMARY KEY (MOVIE_ID, DAYS_OUT)
);

-- ---------------------------------------------------------------------------
-- Optional Source E — static metadata only (NEVER the live popularity score)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS MOVIE_METADATA (
    MOVIE_ID        NUMBER        PRIMARY KEY,
    BUDGET          FLOAT,
    RUNTIME         NUMBER,
    GENRE           STRING,
    RATING          STRING
    -- NOTE: intentionally NO popularity column. See sources/source_E.
);

-- Films to exclude from the model (bad data, re-releases, etc.)
CREATE TABLE IF NOT EXISTS REMOVE_FROM_MODEL (
    MOVIE_ID        NUMBER        PRIMARY KEY,
    REASON          STRING
);
