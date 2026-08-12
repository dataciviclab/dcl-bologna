-- mart_wifi_od.sql: le rotte pedonali più battute (coppie origine→destinazione)
--
-- Top coppie OD per volume totale (serie 2021-2025). Le etichette zona
-- sono leggibili ("Stazione / Piazza Medaglie D'Oro" → "Piazza Verdi").

SELECT label_origine, label_destinazione,
       count(*) as osservazioni,
       sum(totale) as flussi_totali,
       round(sum(totale) * 1.0 / count(DISTINCT data), 0) as flussi_giorno_media
FROM clean_input
GROUP BY label_origine, label_destinazione
ORDER BY flussi_totali DESC
LIMIT 20;
