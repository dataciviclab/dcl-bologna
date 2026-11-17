-- mart_aria_ora.sql: profilo orario inquinamento per anno × stazione × inquinante
--
-- Media per fascia oraria. Il profilo orario del NO2 è la chiave per
-- incrociare aria ↔ traffico (spire, varchi) e aria ↔ bici.
--
-- `anno` è obbligatorio: il clean copre il 2017-2026, senza la dimensione
-- annuale il profilo orario mescolerebbe otto anni.

SELECT
    anno,
    EXTRACT(HOUR FROM reftime) AS ora_inizio,
    stazione,
    agente_atm,
    ROUND(AVG(value), 1) AS media_valore,
    MAX(value) AS max_valore
FROM clean_input
GROUP BY anno, ora_inizio, stazione, agente_atm
