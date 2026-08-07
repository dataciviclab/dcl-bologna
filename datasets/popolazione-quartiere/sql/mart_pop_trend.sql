-- mart_pop_trend.sql: trend demografico per quartiere (1986→2024)
--
-- Calcola primo/ultimo anno, variazione assoluta e CAGR per quartiere.
-- Il clean contiene tutti gli anni (export unico multi-anno), quindi
-- il trend si fa sul singolo clean_input — non serve mart multi-anno.

WITH per_anno AS (
    SELECT
        quartiere,
        anno,
        SUM(residenti) AS residenti
    FROM clean_input
    WHERE quartiere IS NOT NULL AND quartiere <> ''
    GROUP BY quartiere, anno
),
windowed AS (
    SELECT
        quartiere,
        anno,
        residenti,
        FIRST_VALUE(residenti) OVER (PARTITION BY quartiere ORDER BY anno) AS val_first,
        LAST_VALUE(residenti)  OVER (PARTITION BY quartiere ORDER BY anno
                                     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS val_last,
        FIRST_VALUE(anno) OVER (PARTITION BY quartiere ORDER BY anno) AS first_year,
        LAST_VALUE(anno)  OVER (PARTITION BY quartiere ORDER BY anno
                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_year
    FROM per_anno
)
SELECT
    quartiere,
    MAX(first_year)  AS first_year,
    MAX(last_year)   AS last_year,
    MAX(val_first)   AS residenti_primo,
    MAX(val_last)    AS residenti_ultimo,
    MAX(val_last) - MAX(val_first) AS variazione_assoluta,
    ROUND(
        (MAX(val_last) - MAX(val_first)) * 100.0 / NULLIF(MAX(val_first), 0),
        1
    ) AS variazione_pct,
    ROUND(
        (POWER(MAX(val_last) * 1.0 / NULLIF(MAX(val_first), 0),
               1.0 / NULLIF(MAX(last_year) - MAX(first_year), 0)) - 1) * 100,
        2
    ) AS cagr_pct
FROM windowed
GROUP BY quartiere
