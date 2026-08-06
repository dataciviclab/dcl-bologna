-- mart_aria_ora.sql: profilo orario inquinamento per stazione × inquinante
--
-- Media per fascia oraria. Il profilo orario del NO2 è la chiave per
-- incrociare aria ↔ traffico (spire, varchi) e aria ↔ bici.

SELECT
    EXTRACT(HOUR FROM reftime) AS ora_inizio,
    stazione,
    agente_atm,
    ROUND(AVG(value), 1) AS media_valore,
    MAX(value) AS max_valore
FROM clean_input
GROUP BY ora_inizio, stazione, agente_atm
