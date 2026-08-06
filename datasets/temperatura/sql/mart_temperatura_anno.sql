-- mart_temperatura_anno.sql: statistiche annuali di temperatura
--
-- Media, estremi e giorni di caldo estremo per anno. Il dato è
-- multi-anno nello stesso clean → aggregazione diretta.

SELECT
    CAST(EXTRACT(YEAR FROM date) AS INTEGER) AS anno,
    ROUND(AVG(avg), 1) AS avg_media,
    MAX(max) AS max_max,
    MIN(min) AS min_min,
    SUM(CASE WHEN max > 35 THEN 1 ELSE 0 END) AS giorni_oltre_35,
    SUM(CASE WHEN min < 0  THEN 1 ELSE 0 END) AS giorni_gelo
FROM clean_input
GROUP BY anno
