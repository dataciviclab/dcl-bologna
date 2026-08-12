-- mart_wifi_anno.sql: flussi pedonali per anno
--
-- Trend annuale della mobilità pedonale WiFi.
-- Nota: 2021 parte da aprile (275 giorni) → il confronto anno-anno
-- va fatto su media/giorno (flussi_giorno), non sui totali.

SELECT anno,
       count(DISTINCT data) as giorni_coperti,
       sum(totale) as flussi_totali,
       round(sum(totale) * 1.0 / count(DISTINCT data), 0) as flussi_giorno,
       PERCENT_RANK() OVER (ORDER BY sum(totale)) as rank_anno
FROM clean_input
GROUP BY anno
ORDER BY anno;
