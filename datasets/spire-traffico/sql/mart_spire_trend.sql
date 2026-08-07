-- mart_spire_trend.sql: trend multi-anno dei passaggi per via (CAGR)
--
-- Aggrega i parquet clean di più anni (mart.tables[].years nel dataset.yml).
-- CAGR = (valore finale / valore iniziale)^(1/anni) - 1.
--
-- NOTA metodologica: il CAGR è calcolato sui PASSAGGI/GIORNO (non sui totali
-- annuali) per non distorcere la copertura parziale del primo/ultimo anno
-- (es. spira attivata a metà anno → totale annuale tagliato → CAGR gonfiato).
-- giorni_rilevati primo/ultimo anno è esposto per rendere la copertura visibile
-- al consumer.

WITH per_anno AS (
    SELECT
        nome_via,
        anno,
        SUM(passaggi)                AS totale_passaggi,
        COUNT(DISTINCT data)         AS giorni_rilevati,
        SUM(passaggi) * 1.0 / NULLIF(COUNT(DISTINCT data), 0) AS passaggi_giorno
    FROM clean_input
    GROUP BY nome_via, anno
),
windowed AS (
    SELECT
        nome_via,
        anno,
        passaggi_giorno,
        giorni_rilevati,
        FIRST_VALUE(passaggi_giorno) OVER (PARTITION BY nome_via ORDER BY anno)  AS val_first,
        LAST_VALUE(passaggi_giorno)  OVER (PARTITION BY nome_via ORDER BY anno
                                           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS val_last,
        FIRST_VALUE(giorni_rilevati) OVER (PARTITION BY nome_via ORDER BY anno)  AS giorni_first,
        LAST_VALUE(giorni_rilevati)  OVER (PARTITION BY nome_via ORDER BY anno
                                           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS giorni_last,
        FIRST_VALUE(anno) OVER (PARTITION BY nome_via ORDER BY anno)  AS first_year,
        LAST_VALUE(anno)  OVER (PARTITION BY nome_via ORDER BY anno
                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_year
    FROM per_anno
)
SELECT
    nome_via,
    MAX(first_year) AS first_year,
    MAX(last_year)  AS last_year,
    ROUND(MAX(val_first), 0) AS passaggi_giorno_primo_anno,
    ROUND(MAX(val_last), 0)  AS passaggi_giorno_ultimo_anno,
    MAX(giorni_first) AS giorni_rilevati_primo_anno,
    MAX(giorni_last)  AS giorni_rilevati_ultimo_anno,
    ROUND(
        (POWER(MAX(val_last) * 1.0 / NULLIF(MAX(val_first), 0),
               1.0 / NULLIF(MAX(last_year) - MAX(first_year), 0)) - 1) * 100,
        1
    ) AS cagr_pct
FROM windowed
GROUP BY nome_via
