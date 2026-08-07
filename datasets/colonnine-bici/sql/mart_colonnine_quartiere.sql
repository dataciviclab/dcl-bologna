-- mart_colonnine_quartiere.sql: passaggi bici per quartiere × anno
--
-- Aggregazione territoriale: somma le colonnine per quartiere.
-- Include benchmark (rank) e quote di passaggi per zona.
-- Utile per confrontare i quartieri e per incroci con spire/varchi.
--
-- Nota: quota con CTE totale + JOIN (NULLIF su valore aggregato, non su
-- window) — pattern robusto al bug DuckDB "Failed to bind column".

WITH per_quart AS (
    SELECT
        anno,
        quartiere,
        COUNT(DISTINCT colonnina) AS num_colonnine,
        COUNT(DISTINCT data::date) AS giorni,
        SUM(totale) AS totale_passaggi
    FROM clean_input
    WHERE quartiere IS NOT NULL AND quartiere <> ''
    GROUP BY anno, quartiere
),
tot_anno AS (
    SELECT anno, SUM(totale_passaggi) AS tot
    FROM per_quart
    GROUP BY anno
)
SELECT
    q.anno,
    q.quartiere,
    q.num_colonnine,
    q.totale_passaggi,
    ROUND(q.totale_passaggi * 1.0 / NULLIF(q.giorni, 0), 0) AS bici_giorno_medi,
    ROUND(q.totale_passaggi * 100.0 / NULLIF(t.tot, 0), 1) AS quota_pct_anno,
    PERCENT_RANK() OVER (PARTITION BY q.anno ORDER BY q.totale_passaggi) AS rank_quartiere
FROM per_quart q
JOIN tot_anno t ON q.anno = t.anno
