-- mart_precipitazioni_anno.sql: statistiche annuali di pioggia
--
-- Totale annuo, giorni di pioggia e massimo giornaliero per anno.
-- Il dato è multi-anno nello stesso clean → aggregazione diretta.

SELECT
    CAST(EXTRACT(YEAR FROM date) AS INTEGER) AS anno,
    ROUND(SUM(pioggia_mm), 1) AS pioggia_totale_mm,
    SUM(CASE WHEN pioggia_mm > 0.5 THEN 1 ELSE 0 END) AS giorni_pioggia,
    MAX(pioggia_mm) AS max_giornaliero_mm
FROM clean_input
GROUP BY anno
