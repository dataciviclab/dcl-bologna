-- ============================================================
-- Analisi 14: controllo del fuso orario (invariante del cambio ora)
--
-- A cosa serve: stabilire se i timestamp orari sono in **ora locale** o in
-- **UTC**, senza fidarsi delle etichette dell'export (che mentono: il CSV
-- dice `+00:00`, il parquet dice `+01:00` fisso anche d'estate).
--
-- L'unico invariante affidabile è il cambio ora: un giorno UTC ha sempre
-- 24 ore, un giorno locale ne ha 23 (legale) o 25 (solare).
--
-- Valori attesi sul nostro clean (verificati 2026-11-17):
--   2024-03-31 (legale)  -> 23 ore: manca l'ora 01:xx
--   2024-06-15 (controllo) -> 24 ore
--   2024-10-27 (solare)  -> 24 ore: la fonte NON rappresenta l'ora doppia
--                           (l'API JSON duplica le 01:xx, il mergiato no)
--
-- Se il 31/03 torna 24 ore, la fonte ha cambiato rappresentazione (o è
-- passata a UTC): fermarsi e riverificare prima di confrontare le ore.
-- ============================================================

WITH giorni AS (
    SELECT
        varco,
        CAST(data AS DATE) AS giorno,
        COUNT(*) AS letture,
        COUNT(DISTINCT CAST(data AS TIME)) AS slot_distinti
    FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
    WHERE CAST(data AS DATE) IN (DATE '2024-03-31', DATE '2024-10-27', DATE '2024-06-15')
    GROUP BY varco, giorno
)
SELECT
    giorno,
    CASE giorno
        WHEN DATE '2024-03-31' THEN 'cambio a ora legale'
        WHEN DATE '2024-10-27' THEN 'cambio a ora solare'
        ELSE 'giorno di controllo'
    END AS caso,
    COUNT(*) AS varchi,
    ROUND(AVG(slot_distinti), 1) AS slot_medi,
    ROUND(AVG(slot_distinti) / 4.0, 1) AS ore_medie,
    CASE
        WHEN giorno = DATE '2024-03-31' AND ROUND(AVG(slot_distinti) / 4.0, 1) = 23 THEN 'ora locale ✅'
        WHEN giorno = DATE '2024-03-31' AND ROUND(AVG(slot_distinti) / 4.0, 1) = 24 THEN 'UTC o DST non gestito ⚠️'
        WHEN giorno <> DATE '2024-03-31' AND ROUND(AVG(slot_distinti) / 4.0, 1) = 24 THEN 'coerente'
        ELSE 'da verificare'
    END AS esito
FROM giorni
GROUP BY giorno
ORDER BY giorno
