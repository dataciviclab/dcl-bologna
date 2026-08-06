-- mart_colonnine_anno.sql: passaggi per colonnina × anno
--
-- Per ogni colonnina e anno: giorni rilevati, totale passaggi, media/giorno,
-- direzione dominante e benchmark di traffico (percentile sul totale annuo).

SELECT
    anno,
    colonnina,
    quartiere,
    COUNT(DISTINCT data::date) AS giorni_rilevati,
    SUM(totale) AS totale_passaggi,
    ROUND(SUM(totale) * 1.0 / NULLIF(COUNT(DISTINCT data::date), 0), 0) AS bici_giorno_medi,
    SUM(direzione_centro)    AS passaggi_centro,
    SUM(direzione_periferia) AS passaggi_periferia,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY SUM(totale)) AS rank_traffico_anno
FROM clean_input
GROUP BY anno, colonnina, quartiere
