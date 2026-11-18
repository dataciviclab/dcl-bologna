-- mart_quartiere_archi.sql: rete stradale per quartiere
--
-- Benchmark territoriale: quanta strada ha ogni quartiere e quanto è lunga
-- la via media. Serve a normalizzare i dati puntuali (varchi, colonnine,
-- centraline) per estensione della rete, non solo per abitanti.

SELECT
    quartiere,
    COUNT(*)                        AS archi,
    COUNT(DISTINCT codvia)          AS vie,
    ROUND(SUM(lunghezza_m) / 1000.0, 1) AS lunghezza_km,
    ROUND(AVG(lunghezza_m), 0)      AS lunghezza_media_arco_m
FROM clean_input
GROUP BY quartiere
