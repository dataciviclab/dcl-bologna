-- mart_aria_mese.sql: serie mensile per stazione × inquinante (2017-2026)
--
-- È la granularità che serve per valutare una policy nel tempo: la Città 30
-- parte a gennaio 2024, quindi il confronto utile è mensile (non annuale) e
-- per stazione. Le stazioni sono 3: Giardini Margherita (parco), Porta San
-- Felice (traffico), Via Chiarini (traffico).
--
-- Soglie di riferimento (indicative, non normative) usate per la quota di
-- giornate sopra livello: PM10 > 50, NO2 > 40, O3 > 120 (µg/m³).
-- CO è in mg/m³: non ha soglia qui, e non va aggregato con le altre sostanze.

SELECT
    anno,
    CAST(EXTRACT(MONTH FROM reftime) AS INTEGER) AS mese,
    stazione,
    agente_atm,
    MAX(um) AS um,
    COUNT(DISTINCT CAST(reftime AS DATE)) AS giorni_rilevati,
    ROUND(AVG(value), 1) AS media_valore,
    MAX(value) AS max_valore,
    -- Quota sopra soglia: ore per NO2/O3 (orari), giorni per PM10/PM2.5
    -- (la fonte li pubblica come valore giornaliero).
    ROUND(100.0 * COUNT(*) FILTER (WHERE
        (agente_atm = 'PM10' AND value > 50)
        OR (agente_atm = 'NO2' AND value > 40)
        OR (agente_atm = 'O3' AND value > 120)
    ) / COUNT(*), 1) AS pct_sopra_soglia,
    MIN(misura_affidabile) AS misura_affidabile
FROM clean_input
GROUP BY anno, mese, stazione, agente_atm
