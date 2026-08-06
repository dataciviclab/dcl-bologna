-- mart_colonnine_quartiere.sql: passaggi bici per quartiere × anno
--
-- Aggregazione territoriale: somma le colonnine per quartiere.
-- Include benchmark (rank) e quote di passaggi per zona.
-- Utile per confrontare i quartieri e per incroci con spire/varchi.

SELECT
    anno,
    quartiere,
    COUNT(DISTINCT colonnina) AS num_colonnine,
    SUM(totale) AS totale_passaggi,
    ROUND(SUM(totale) * 1.0 / NULLIF(COUNT(DISTINCT data::date), 0), 0) AS bici_giorno_medi,
    ROUND(SUM(totale) * 100.0 / NULLIF(SUM(SUM(totale)) OVER (PARTITION BY anno), 0), 1) AS quota_pct_anno,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY SUM(totale)) AS rank_quartiere
FROM clean_input
WHERE quartiere IS NOT NULL AND quartiere <> ''
GROUP BY anno, quartiere
