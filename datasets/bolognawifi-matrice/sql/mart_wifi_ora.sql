-- mart_wifi_ora.sql: profilo orario dei flussi pedonali
--
-- Forma della giornata della mobilità pedonale WiFi (tutta la serie).
-- Confrontabile con il profilo orario di ZTL (analisi 07) e spire
-- (analisi 09): le auto hanno due picchi, i pedoni quanti?

SELECT ora,
       round(avg(totale), 0) as media_flussi,
       sum(totale) as flussi_totali
FROM clean_input
GROUP BY ora
ORDER BY ora;
