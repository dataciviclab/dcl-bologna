-- mart_emigrati_quartiere.sql: emigrati per quartiere × anno + benchmark
--
-- Totale emigrati per quartiere e anno, quota sul comune e rank.
-- Utile per capire quali quartieri perdono più residenti.

SELECT
    anno,
    quartiere,
    SUM(numero_emigrati) AS totale_emigrati,
    ROUND(SUM(numero_emigrati) * 100.0 / NULLIF(SUM(SUM(numero_emigrati)) OVER (PARTITION BY anno), 0), 1) AS quota_pct,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY SUM(numero_emigrati)) AS rank_emigrazione
FROM clean_input
WHERE quartiere IS NOT NULL AND quartiere <> ''
GROUP BY anno, quartiere
