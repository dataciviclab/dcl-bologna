-- mart_famiglie_tipo.sql: famiglie per tipologia capofamiglia × anno
--
-- Quante famiglie per tipo di capofamiglia (es. persona sola, coppia,
-- monogenitore) e quota sul totale. Cambiamento della struttura familiare
-- nel tempo.
--
-- Nota: il totale annuo è pre-calcolato in una CTE e fuso con JOIN —
-- evita un bug DuckDB (internal "Failed to bind column") con NULLIF
-- dentro window function su aggregato minimale.

WITH per_tipo AS (
    SELECT
        anno,
        tipo_capofamiglia,
        SUM(numero_famiglie) AS totale_famiglie
    FROM clean_input
    GROUP BY anno, tipo_capofamiglia
),
tot_anno AS (
    SELECT anno, SUM(totale_famiglie) AS tot
    FROM per_tipo
    GROUP BY anno
)
SELECT
    p.anno,
    p.tipo_capofamiglia,
    p.totale_famiglie,
    ROUND(p.totale_famiglie * 100.0 / NULLIF(t.tot, 0), 1) AS quota_pct
FROM per_tipo p
JOIN tot_anno t ON p.anno = t.anno
