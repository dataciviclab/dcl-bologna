-- ============================================================
-- Analisi 14: controllo del fuso orario (invariante del cambio ora)
--
-- A cosa serve: stabilire se i timestamp orari sono in **ora locale** o in
-- **UTC** senza fidarsi delle etichette dell'export (che mentono: il CSV
-- dice `+00:00`, il parquet `+01:00` fisso anche d'estate).
--
-- L'invariante è fisico: un giorno UTC ha sempre 24 ore, un giorno locale
-- ne ha 23 (passaggio a legale) o 25 (ritorno a solare).
--
-- Copre i tre dataset orari del repo:
--   varchi_ztl        4 letture/ora, unità = varco
--   centraline_aria   1 lettura/ora, unità = stazione (solo NO2)
--   colonnine_bici    1 lettura/ora, unità = colonnina
--
-- Valori attesi (verificati 2026-11-17): 23 / 24 / 24 sui tre giorni.
-- Robustezza: i path sono glob (`*/..._clean.parquet`), quindi una
-- ripartizione per anno non rompe il controllo. Se il glob non trova file
-- la query fallisce con IOException (errore rumoroso); se trova file ma
-- nessuna riga per quelle date, la riga esce con `unita_misurate = 0`.
-- In nessun caso un controllo senza dati può sembrare un controllo ok.
--
-- Se il 31/03 torna 24 ore, la fonte ha cambiato rappresentazione o è
-- passata a UTC: fermarsi e riverificare prima di confrontare le ore.
-- ============================================================

WITH giorni(dataset, letture_ora, giorno) AS (
    SELECT * FROM (VALUES
        ('varchi',       4, DATE '2024-03-31'),
        ('varchi',       4, DATE '2024-10-27'),
        ('varchi',       4, DATE '2024-06-15'),
        ('aria (NO2)',   1, DATE '2024-03-31'),
        ('aria (NO2)',   1, DATE '2024-10-27'),
        ('aria (NO2)',   1, DATE '2024-06-15'),
        ('bici',         1, DATE '2024-03-31'),
        ('bici',         1, DATE '2024-10-27'),
        ('bici',         1, DATE '2024-06-15')
    ) AS t(dataset, letture_ora, giorno)
),
per_unita AS (
    -- varchi: 4 letture/ora per varco
    SELECT 'varchi' AS dataset, CAST(data AS DATE) AS giorno, varco AS unita, COUNT(*) AS letture
    FROM read_parquet('out/data/clean/varchi_ztl/*/varchi_ztl_*_clean.parquet')
    WHERE CAST(data AS DATE) IN (DATE '2024-03-31', DATE '2024-10-27', DATE '2024-06-15')
    GROUP BY 1, 2, 3

    UNION ALL

    -- aria: 1 lettura/ora per stazione, solo NO2 (le altre sostanze hanno buchi)
    SELECT 'aria (NO2)', CAST(reftime AS DATE), stazione, COUNT(*)
    FROM read_parquet('out/data/clean/centraline_aria/*/centraline_aria_*_clean.parquet')
    WHERE agente_atm = 'NO2'
      AND CAST(reftime AS DATE) IN (DATE '2024-03-31', DATE '2024-10-27', DATE '2024-06-15')
    GROUP BY 1, 2, 3

    UNION ALL

    -- bici: 1 lettura/ora per colonnina
    SELECT 'bici', CAST(data AS DATE), colonnina, COUNT(*)
    FROM read_parquet('out/data/clean/colonnine_bici/*/colonnine_bici_*_clean.parquet')
    WHERE CAST(data AS DATE) IN (DATE '2024-03-31', DATE '2024-10-27', DATE '2024-06-15')
    GROUP BY 1, 2, 3
)
SELECT
    g.dataset,
    g.giorno,
    CASE g.giorno
        WHEN DATE '2024-03-31' THEN 'cambio a ora legale'
        WHEN DATE '2024-10-27' THEN 'cambio a ora solare'
        ELSE 'giorno di controllo'
    END AS caso,
    COUNT(p.unita) AS unita_misurate,
    ROUND(MEDIAN(p.letture), 1) AS letture_mediane,
    ROUND(MEDIAN(p.letture) / g.letture_ora, 1) AS ore_medie,
    CASE
        WHEN COUNT(p.unita) = 0 THEN '⚠️ nessuna riga: glob o dataset assente'
        WHEN g.giorno = DATE '2024-03-31'
             AND ROUND(MEDIAN(p.letture) / g.letture_ora, 1) = 23 THEN 'ora locale ✅'
        WHEN g.giorno = DATE '2024-03-31'
             AND ROUND(MEDIAN(p.letture) / g.letture_ora, 1) = 24 THEN '⚠️ 24 ore a marzo: UTC o DST non gestito'
        WHEN ROUND(MEDIAN(p.letture) / g.letture_ora, 1) = 24 THEN 'coerente'
        ELSE 'da verificare'
    END AS esito
FROM giorni g
LEFT JOIN per_unita p
    ON p.dataset = g.dataset AND p.giorno = g.giorno
GROUP BY g.dataset, g.giorno, g.letture_ora
ORDER BY g.dataset, g.giorno
