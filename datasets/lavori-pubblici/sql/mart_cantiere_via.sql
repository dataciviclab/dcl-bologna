-- mart_cantiere_via.sql: riepilogo cantieri per via
--
-- Una riga per via: quanti cantieri, quante fasi (id distinti), quanto
-- impattano la carreggiata, in che arco di tempo e per quanti mesi distinti
-- la via ha avuto almeno un cantiere attivo.
--
-- `mesi_con_cantiere` è calcolato sulla stessa espansione via × mese di
-- mart_cantiere_via_mese: è la copertura temporale utile a normalizzare
-- (es. 20 cantieri su 60 mesi ≠ 20 cantieri su 6 mesi).
--
-- Chiave: via.

WITH confini AS (
    SELECT
        date_trunc('month', MIN(data_inizio)) AS mese_min,
        date_trunc('month', MAX(COALESCE(data_fine, data_inizio))) AS mese_max
    FROM clean_input
),
mesi AS (
    SELECT CAST(UNNEST(generate_series(mese_min, mese_max, INTERVAL 1 MONTH)) AS DATE) AS data_mese,
           mese_max
    FROM confini
),
mesi_via AS (
    SELECT c.via, COUNT(DISTINCT m.data_mese) AS mesi_con_cantiere
    FROM clean_input c
    JOIN mesi m
      ON m.data_mese >= date_trunc('month', c.data_inizio)
     AND m.data_mese <= COALESCE(date_trunc('month', c.data_fine), m.mese_max)
    GROUP BY c.via
)
SELECT
    c.via,
    MAX(c.quartiere)                                                   AS quartiere,
    COUNT(*)                                                           AS cantieri,
    COUNT(DISTINCT c.id)                                               AS fasi_distinte,
    COUNT(*) FILTER (
        WHERE c.impatto_categoria IN ('chiusura', 'restringimento', 'senso_unico', 'divieto_transito')
    )                                                                  AS cantieri_impatto_carreggiata,
    COUNT(*) FILTER (WHERE c.impatto_categoria = 'chiusura')           AS cantieri_chiusura,
    COUNT(*) FILTER (WHERE c.impatto_categoria = 'restringimento')     AS cantieri_restringimento,
    MIN(c.data_inizio)                                                 AS prima_data_inizio,
    MAX(COALESCE(c.data_fine, c.data_inizio))                          AS ultima_data,
    MAX(mv.mesi_con_cantiere)                                          AS mesi_con_cantiere,
    ROUND(AVG(c.longitudine), 6)                                       AS longitudine,
    ROUND(AVG(c.latitudine), 6)                                        AS latitudine
FROM clean_input c
LEFT JOIN mesi_via mv ON mv.via = c.via
GROUP BY c.via
