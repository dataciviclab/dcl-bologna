-- mart_varchi_ora.sql: profilo orario del traffico ZTL
--
-- Passaggi medi per fascia oraria, tutti i varchi aggregati.
-- Il picco orario è confrontabile con spire (auto fuori ZTL) e
-- colonnine (bici) per il quadro completo della mobilità.

SELECT
    anno,
    EXTRACT(HOUR FROM data) AS ora_inizio,
    SUM(totale_passaggi)        AS totale_passaggi,
    SUM(auto_furgoni)           AS auto_furgoni,
    SUM(moto_ciclomotori)       AS moto_ciclomotori,
    SUM(bus_camion)             AS bus_camion,
    COUNT(DISTINCT varco)       AS num_varchi
FROM clean_input
GROUP BY anno, ora_inizio
