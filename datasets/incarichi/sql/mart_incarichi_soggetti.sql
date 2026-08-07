-- mart_incarichi_soggetti.sql: top soggetti per importo complessivo
--
-- Aggrega per ragione_sociale (con partita_iva per il cross ANAC —
-- analisi 05 di dcl-bologna). Include primo/ultimo anno di attività.

SELECT
    ragione_sociale,
    MAX(partita_iva) AS partita_iva,
    COUNT(*) AS numero_incarichi,
    ROUND(SUM(importo_euro), 0) AS importo_totale,
    ROUND(AVG(importo_euro), 0) AS importo_medio,
    MIN(anno) AS primo_anno,
    MAX(anno) AS ultimo_anno
FROM clean_input
WHERE ragione_sociale IS NOT NULL AND ragione_sociale <> ''
GROUP BY ragione_sociale
