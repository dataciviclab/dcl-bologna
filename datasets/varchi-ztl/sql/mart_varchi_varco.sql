-- mart_varchi_varco.sql: passaggi per varco × anno + benchmark
--
-- Per ogni varco e anno: giorni rilevati, totale passaggi, media/giorno
-- e rank rispetto agli altri varchi. Benchmark territoriale fuso nel mart.

WITH per_varco AS (
    SELECT
        anno,
        varco,
        MAX(nome_varco) AS nome_varco,
        COUNT(DISTINCT data::date) AS giorni_rilevati,
        SUM(totale_passaggi) AS totale_passaggi,
        SUM(auto_furgoni)    AS auto_furgoni,
        SUM(moto_ciclomotori) AS moto_ciclomotori
    FROM clean_input
    GROUP BY anno, varco
),
tot_anno AS (
    SELECT anno, SUM(totale_passaggi) AS tot
    FROM per_varco
    GROUP BY anno
)
SELECT
    p.anno,
    p.varco,
    p.nome_varco,
    p.giorni_rilevati,
    p.totale_passaggi,
    p.auto_furgoni,
    p.moto_ciclomotori,
    ROUND(p.totale_passaggi * 1.0 / NULLIF(p.giorni_rilevati, 0), 0) AS passaggi_giorno_medi,
    ROUND(p.totale_passaggi * 100.0 / NULLIF(t.tot, 0), 1) AS quota_pct,
    PERCENT_RANK() OVER (PARTITION BY p.anno ORDER BY p.totale_passaggi) AS rank_varco
FROM per_varco p
JOIN tot_anno t ON p.anno = t.anno
