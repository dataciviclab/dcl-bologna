-- mart_aria_stazione.sql: statistiche per stazione × inquinante × anno
--
-- Media, massimo, giorni rilevati e percentuale giorni sopra soglia
-- (PM10>50, NO2>40, O3>120 — soglie di riferimento). Utile per
-- confrontare le stazioni e per incroci con traffico.

SELECT
    anno,
    stazione,
    agente_atm,
    COUNT(*) AS giorni_rilevati,
    ROUND(AVG(value), 1) AS media_valore,
    MAX(value) AS max_valore,
    ROUND(AVG(CASE
        WHEN agente_atm = 'PM10 (Particolato <10µm)'  AND value > 50  THEN 1
        WHEN agente_atm = 'NO2 (Biossido di azoto)'    AND value > 40  THEN 1
        WHEN agente_atm = 'O3 (Ozono)'                 AND value > 120 THEN 1
        ELSE 0
    END) * 100, 1) AS pct_sopra_soglia
FROM clean_input
GROUP BY anno, stazione, agente_atm
