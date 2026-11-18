-- mart_via_quartiere.sql: crosswalk via (codvia) → quartiere
--
-- È il pezzo riutilizzabile: qualunque dataset che espone un codice via
-- (spire: codice_via) ottiene il quartiere con un join su `codvia`, senza
-- mapping manuali e senza geometrie. Un codvia può comparire su più quartieri
-- solo se la via attraversa il confine: in quel caso la chiave è (codvia,
-- quartiere) e il consumer sceglie (es. quartiere con più archi).

SELECT
    codvia,
    MAX(nome_via)        AS nome_via,
    quartiere,
    MAX(num_quartiere)   AS num_quartiere,
    COUNT(*)             AS archi,
    ROUND(SUM(lunghezza_m), 1) AS lunghezza_m,
    ROUND(SUM(lunghezza_m) / 1000.0, 2) AS lunghezza_km
FROM clean_input
GROUP BY codvia, quartiere
