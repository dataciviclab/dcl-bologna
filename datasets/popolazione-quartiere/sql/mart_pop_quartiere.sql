-- mart_pop_quartiere.sql: residenti per quartiere × anno + benchmark
--
-- Totale residenti per quartiere e anno, con quota sul comune,
-- indice di vecchiaia (65+ / 0-14) e rank. Benchmark territoriale
-- fuso nel mart (pattern candidate-standard).

WITH base AS (
    SELECT
        anno,
        quartiere,
        SUM(residenti) AS residenti,
        SUM(CASE WHEN eta_singolo >= 65 THEN residenti ELSE 0 END) AS over65,
        SUM(CASE WHEN eta_singolo < 15  THEN residenti ELSE 0 END) AS under15
    FROM clean_input
    WHERE quartiere IS NOT NULL AND quartiere <> ''
    GROUP BY anno, quartiere
)
SELECT
    anno,
    quartiere,
    residenti,
    ROUND(residenti * 100.0 / NULLIF(SUM(residenti) OVER (PARTITION BY anno), 0), 1) AS quota_pct,
    ROUND(over65 * 1.0 / NULLIF(under15, 0), 1) AS indice_vecchiaia,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY residenti) AS rank_quartiere
FROM base
