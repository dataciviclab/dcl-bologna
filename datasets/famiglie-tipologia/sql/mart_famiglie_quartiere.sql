-- mart_famiglie_quartiere.sql: famiglie per quartiere × anno
--
-- Totale famiglie e quota per quartiere e anno. Confrontabile con
-- popolazione (indice: persone per famiglia) via join a runtime.
--
-- Nota: quota con CTE totale + JOIN (NULLIF su valore aggregato, non su
-- window) — pattern robusto al bug DuckDB "Failed to bind column".

WITH per_quart AS (
    SELECT
        anno,
        quartiere,
        SUM(numero_famiglie) AS totale_famiglie
    FROM clean_input
    WHERE quartiere IS NOT NULL AND quartiere <> ''
    GROUP BY anno, quartiere
),
tot_anno AS (
    SELECT anno, SUM(totale_famiglie) AS tot
    FROM per_quart
    GROUP BY anno
)
SELECT
    q.anno,
    q.quartiere,
    q.totale_famiglie,
    ROUND(q.totale_famiglie * 100.0 / NULLIF(t.tot, 0), 1) AS quota_pct,
    PERCENT_RANK() OVER (PARTITION BY q.anno ORDER BY q.totale_famiglie) AS rank_quartiere
FROM per_quart q
JOIN tot_anno t ON q.anno = t.anno
