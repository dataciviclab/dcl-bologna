-- mart_spire_trend.sql: trend multi-anno dei passaggi per via (CAGR)
--
-- Aggrega i parquet clean di più anni (mart.tables[].years nel dataset.yml).
-- CAGR = (valore finale / valore iniziale)^(1/anni) - 1.

WITH per_anno AS (
    SELECT
        nome_via,
        anno,
        SUM(passaggi) AS totale_passaggi
    FROM clean_input
    GROUP BY nome_via, anno
),
windowed AS (
    SELECT
        nome_via,
        anno,
        totale_passaggi,
        FIRST_VALUE(totale_passaggi) OVER (PARTITION BY nome_via ORDER BY anno)  AS val_first,
        LAST_VALUE(totale_passaggi)  OVER (PARTITION BY nome_via ORDER BY anno
                                           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS val_last,
        FIRST_VALUE(anno) OVER (PARTITION BY nome_via ORDER BY anno)  AS first_year,
        LAST_VALUE(anno)  OVER (PARTITION BY nome_via ORDER BY anno
                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_year
    FROM per_anno
)
SELECT
    nome_via,
    MAX(first_year) AS first_year,
    MAX(last_year)  AS last_year,
    MAX(val_first)  AS passaggi_primo_anno,
    MAX(val_last)   AS passaggi_ultimo_anno,
    ROUND(
        (POWER(MAX(val_last) * 1.0 / NULLIF(MAX(val_first), 0),
               1.0 / NULLIF(MAX(last_year) - MAX(first_year), 0)) - 1) * 100,
        1
    ) AS cagr_pct
FROM windowed
GROUP BY nome_via
