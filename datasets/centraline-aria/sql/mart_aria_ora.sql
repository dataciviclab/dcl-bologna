-- mart_aria_ora.sql: profilo orario inquinamento per anno × stazione × inquinante
--
-- Media per fascia oraria. Il profilo orario del NO2 è la chiave per
-- incrociare aria ↔ traffico (spire, varchi) e aria ↔ bici.
--
-- `anno` è obbligatorio: il clean copre il 2016-2026, senza la dimensione
-- annuale il profilo orario mescolerebbe dieci anni.
--
-- Solo inquinanti orari: PM10 e PM2.5 arrivano dalla fonte come valore
-- giornaliero (stampato alle 23:00) e in un profilo orario produrrebbero
-- una singola barra fuori scala.
--
-- `misura_affidabile` propaga il flag del clean (FALSE per il canale NOx di
-- Porta San Felice 2024).

SELECT
    anno,
    EXTRACT(HOUR FROM reftime) AS ora_inizio,
    stazione,
    agente_atm,
    ROUND(AVG(value), 1) AS media_valore,
    MAX(value) AS max_valore,
    MIN(misura_affidabile) AS misura_affidabile
FROM clean_input
WHERE agente_atm IN ('NO2', 'NO', 'NOX', 'CO', 'C6H6', 'O3')
GROUP BY anno, ora_inizio, stazione, agente_atm
