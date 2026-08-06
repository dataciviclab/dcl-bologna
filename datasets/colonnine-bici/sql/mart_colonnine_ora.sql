-- mart_colonnine_ora.sql: profilo orario bici per quartiere
--
-- Media bici per fascia oraria e quartiere (tutti gli anni nel clean).
-- La fascia oraria di punta per quartiere è la chiave per incroci
-- con spire (auto) e centraline (aria).

SELECT
    EXTRACT(HOUR FROM data) AS ora_inizio,
    quartiere,
    ROUND(AVG(totale), 1) AS bici_medie,
    MAX(totale)           AS bici_max,
    ROUND(AVG(direzione_centro), 1)    AS centro_medi,
    ROUND(AVG(direzione_periferia), 1) AS periferia_medi
FROM clean_input
WHERE quartiere IS NOT NULL AND quartiere <> ''
GROUP BY ora_inizio, quartiere
