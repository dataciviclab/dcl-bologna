-- mart_convivenze_tipo.sql: residenti in convivenza per dimensione struttura × anno
--
-- Quanti residenti vivono in istituti di convivenza, per dimensione
-- della struttura (es. piccole, grandi) e anno.
--
-- Nota: totale annuo pre-calcolato in CTE + JOIN — evita il bug DuckDB
-- "Failed to bind column" con NULLIF dentro window su aggregato minimale.

WITH per_dim AS (
    SELECT
        anno,
        dimensione,
        SUM(residenti) AS residenti
    FROM clean_input
    WHERE dimensione IS NOT NULL AND dimensione <> ''
    GROUP BY anno, dimensione
),
tot_anno AS (
    SELECT anno, SUM(residenti) AS tot
    FROM per_dim
    GROUP BY anno
)
SELECT
    p.anno,
    p.dimensione,
    p.residenti,
    ROUND(p.residenti * 100.0 / NULLIF(t.tot, 0), 1) AS quota_pct
FROM per_dim p
JOIN tot_anno t ON p.anno = t.anno
