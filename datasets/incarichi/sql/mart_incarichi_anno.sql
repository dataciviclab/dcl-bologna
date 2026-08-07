-- mart_incarichi_anno.sql: incarichi per anno
--
-- Numero incarichi e importi aggregati per anno. L'anno deriva da
-- anno_pg_atto (data dell'atto protocollato).

SELECT
    anno,
    COUNT(*) AS numero_incarichi,
    ROUND(SUM(importo_euro), 0) AS importo_totale,
    ROUND(AVG(importo_euro), 0) AS importo_medio,
    SUM(CASE WHEN importo_euro = 0 THEN 1 ELSE 0 END) AS senza_corrispettivo
FROM clean_input
GROUP BY anno
