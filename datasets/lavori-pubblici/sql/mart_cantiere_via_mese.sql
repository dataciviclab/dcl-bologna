-- mart_cantiere_via_mese.sql: cantieri attivi per via × mese
--
-- Vista pensata per l'incrocio con le spire del traffico (e con i varchi):
-- per ogni via e ogni mese in cui risulta almeno un cantiere, quanti cantieri
-- sono attivi e quanti impattano la carreggiata.
--
-- "Attivo nel mese m" = intervallo [data_inizio, data_fine] che interseca m.
-- I lavori IN CORSO (data_fine NULL) si considerano attivi fino all'ultimo
-- mese noto del dataset (limite), non oltre: è un'approssimazione dichiarata.
--
-- Chiave: (via, anno, mese). Tabella sparsa: esistono solo le coppie
-- via × mese con almeno un cantiere attivo (per un LEFT JOIN parti dalla
-- serie del traffico, non da qui).

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
attivi AS (
    SELECT
        c.via,
        m.data_mese,
        COUNT(*) AS cantieri_attivi,
        COUNT(*) FILTER (
            WHERE c.impatto_categoria IN ('chiusura', 'restringimento', 'senso_unico', 'divieto_transito')
        ) AS cantieri_impatto_carreggiata,
        COUNT(*) FILTER (WHERE c.impatto_categoria = 'chiusura')      AS cantieri_chiusura,
        COUNT(*) FILTER (WHERE c.impatto_categoria = 'restringimento') AS cantieri_restringimento,
        COUNT(*) FILTER (WHERE c.impatto_categoria = 'nessuna_modifica') AS cantieri_senza_impatto,
        COUNT(*) FILTER (
            WHERE c.impatto_categoria IN ('non_dichiarato', 'altro')
        ) AS cantieri_impatto_non_classificato,
        COUNT(*) FILTER (WHERE date_trunc('month', c.data_inizio) = m.data_mese) AS cantieri_iniziati,
        COUNT(DISTINCT c.id) AS lavori_distinti
    FROM clean_input c
    JOIN mesi m
      ON m.data_mese >= date_trunc('month', c.data_inizio)
     AND m.data_mese <= COALESCE(date_trunc('month', c.data_fine), m.mese_max)
    GROUP BY c.via, m.data_mese
)
SELECT
    via,
    CAST(EXTRACT(YEAR FROM data_mese) AS INTEGER)  AS anno,
    CAST(EXTRACT(MONTH FROM data_mese) AS INTEGER) AS mese,
    data_mese,
    cantieri_attivi,
    cantieri_impatto_carreggiata,
    cantieri_chiusura,
    cantieri_restringimento,
    cantieri_senza_impatto,
    cantieri_impatto_non_classificato,
    cantieri_iniziati,
    lavori_distinti
FROM attivi
