-- mart_spire_sintesi.sql: passaggi per via × anno (benchmark territoriale)
--
-- Per ogni nome_via e anno: giorni rilevati, totale passaggi, media/giorno,
-- e ranking relativo rispetto alle altre vie (quantili). Il benchmark è
-- fuso nel mart per evitare join a runtime (pattern candidate-standard).

SELECT
    anno,
    nome_via,
    COUNT(DISTINCT data) AS giorni_rilevati,
    SUM(passaggi)        AS totale_passaggi,
    ROUND(SUM(passaggi) * 1.0 / NULLIF(COUNT(DISTINCT data), 0), 0) AS passaggi_giorno_medi,
    COUNT(DISTINCT id_uni) AS num_spire,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY SUM(passaggi)) AS rank_passaggi_anno
FROM clean_input
GROUP BY anno, nome_via
