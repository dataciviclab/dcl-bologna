-- mart_emigrati_quartiere.sql: emigrati per quartiere × anno + benchmark
--
-- Totale emigrati per quartiere e anno, quota sul comune e rank.
-- Utile per capire quali quartieri perdono più residenti.
--
-- Nota: quota con CTE totale + JOIN (NULLIF su valore aggregato, non su
-- window) — pattern robusto al bug DuckDB "Failed to bind column".

WITH per_quart AS (
    SELECT
        anno,
        quartiere,
        SUM(numero_emigrati) AS totale_emigrati
    FROM clean_input
    WHERE quartiere IS NOT NULL AND quartiere <> ''
    GROUP BY anno, quartiere
),
tot_anno AS (
    SELECT anno, SUM(totale_emigrati) AS tot
    FROM per_quart
    GROUP BY anno
)
SELECT
    q.anno,
    q.quartiere,
    q.totale_emigrati,
    ROUND(q.totale_emigrati * 100.0 / NULLIF(t.tot, 0), 1) AS quota_pct,
    PERCENT_RANK() OVER (PARTITION BY q.anno ORDER BY q.totale_emigrati) AS rank_emigrazione
FROM per_quart q
JOIN tot_anno t ON q.anno = t.anno
