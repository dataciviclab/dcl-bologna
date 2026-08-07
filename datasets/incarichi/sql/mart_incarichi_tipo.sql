-- mart_incarichi_tipo.sql: incarichi per classificazione
--
-- Quota di incarichi e importi per tipologia (X1, X2, ...).
-- Totale annuo pre-calcolato in CTE + JOIN (workaround bug DuckDB
-- NULLIF+window su aggregato minimale).

WITH per_tipo AS (
    SELECT
        classificazione_incarichi,
        COUNT(*) AS numero_incarichi,
        SUM(importo_euro) AS importo_totale
    FROM clean_input
    WHERE classificazione_incarichi IS NOT NULL AND classificazione_incarichi <> ''
    GROUP BY classificazione_incarichi
),
tot AS (
    SELECT SUM(numero_incarichi) AS n, SUM(importo_totale) AS imp
    FROM per_tipo
)
SELECT
    p.classificazione_incarichi,
    p.numero_incarichi,
    ROUND(p.importo_totale, 0) AS importo_totale,
    ROUND(p.numero_incarichi * 100.0 / NULLIF(t.n, 0), 1) AS quota_incarichi_pct,
    ROUND(p.importo_totale * 100.0 / NULLIF(t.imp, 0), 1) AS quota_importo_pct
FROM per_tipo p
CROSS JOIN tot t
