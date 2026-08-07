-- mart_pop_quartiere.sql: residenti per quartiere × anno + benchmark
--
-- Totale residenti per quartiere e anno, con quota sul comune,
-- indice di vecchiaia (65+ / 0-14) e rank. Benchmark territoriale
-- fuso nel mart (pattern candidate-standard).
--
-- Nota: quota calcolata con CTE totale + JOIN (NULLIF su valore aggregato,
-- non su window) — pattern robusto al bug DuckDB "Failed to bind column"
-- con NULLIF(windows) su aggregato.

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
),
tot_anno AS (
    SELECT anno, SUM(residenti) AS tot
    FROM base
    GROUP BY anno
)
SELECT
    b.anno,
    b.quartiere,
    b.residenti,
    ROUND(b.residenti * 100.0 / NULLIF(t.tot, 0), 1) AS quota_pct,
    ROUND(b.over65 * 1.0 / NULLIF(b.under15, 0), 1) AS indice_vecchiaia,
    PERCENT_RANK() OVER (PARTITION BY b.anno ORDER BY b.residenti) AS rank_quartiere
FROM base b
JOIN tot_anno t ON b.anno = t.anno
