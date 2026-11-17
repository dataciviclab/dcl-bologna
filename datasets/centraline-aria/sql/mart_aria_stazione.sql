-- mart_aria_stazione.sql: statistiche per stazione × inquinante × anno
--
-- Media, massimo, giorni rilevati e quota sopra soglia di riferimento
-- (PM10>50, NO2>40, O3>120). Utile per confrontare le stazioni e per
-- incroci con traffico.
--
-- Attenzione alla granularità della fonte: NO2/O3 sono orari, PM10/PM2.5
-- sono giornalieri. `giorni_rilevati` conta i giorni distinti (non le righe)
-- e `pct_sopra_soglia` è quindi una quota su ore per NO2/O3 e su giorni
-- per PM10/PM2.5.
--
-- `misura_affidabile` propaga il flag del clean: FALSE per il canale NOx di
-- Porta San Felice 2024 (difetto strumentale documentato in notes.md).

SELECT
    anno,
    stazione,
    agente_atm,
    COUNT(DISTINCT CAST(reftime AS DATE)) AS giorni_rilevati,
    ROUND(AVG(value), 1) AS media_valore,
    MAX(value) AS max_valore,
    ROUND(AVG(CASE
        WHEN agente_atm = 'PM10' AND value > 50  THEN 1
        WHEN agente_atm = 'NO2'  AND value > 40  THEN 1
        WHEN agente_atm = 'O3'   AND value > 120 THEN 1
        ELSE 0
    END) * 100, 1) AS pct_sopra_soglia,
    MIN(misura_affidabile) AS misura_affidabile
FROM clean_input
GROUP BY anno, stazione, agente_atm
