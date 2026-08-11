-- ============================================================
-- Analisi 09: Fuori dalla cerchia — il traffico cala anche in periferia
-- Dataset: spire-traffico (vie fuori ZTL, ~900 spire, 7,3M records/anno)
-- Path: out/data/clean/spire_traffico/<anno>/spire_traffico_<anno>_clean.parquet
--
-- Domanda: il calo del traffico visto in ZTL (analisi 07, -22%) si vede
-- anche fuori dalla cerchia? Complementare a analisi/07_ztl_trend.sql.
--
-- NOTA METODO (lezione da analisi 02/07):
-- 1. La rete di spire è CAMBIATA tra 2022 e 2025 (spire spente e nuove
--    installazioni) → i confronti su tutte le spire mescolano variazioni
--    di traffico e variazioni della rete di misura.
-- 2. Il confronto ROBUSTO è sulle spire STABILI (attive con passaggi
--    >100 in entrambi gli anni): lì la variazione è solo traffico.
-- 3. Metriche normalizzate per spira e per giorno (365 giorni).
-- ============================================================

-- 0. Verifica copertura: anni, spire attive, giorni rilevati
SELECT anno, count(DISTINCT id_uni) as spire_attive,
       count(DISTINCT data) as giorni,
       round(sum(passaggi)/1000000.0, 1) as passaggi_mln
FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
GROUP BY anno ORDER BY anno;

-- 1. Trend passaggi/spira/giorno (tutte le spire presenti nell'anno)
SELECT anno,
       round(sum(passaggi) * 1.0 / count(DISTINCT id_uni) / count(DISTINCT data), 0) as passaggi_spira_giorno
FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
GROUP BY anno ORDER BY anno;

-- 2. Riconfigurazione della rete: spire attive 2022, quante spente nel 2025
SELECT count(*) as spire_2022,
       count(*) FILTER (WHERE p25 > 0) as attive_anche_2025,
       count(*) FILTER (WHERE p25 = 0 OR p25 IS NULL) as spente_2025
FROM (
    SELECT id_uni,
           sum(passaggi) FILTER (WHERE anno=2022) as p22,
           sum(passaggi) FILTER (WHERE anno=2025) as p25
    FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
    WHERE anno IN (2022, 2025)
    GROUP BY id_uni
);

-- 3. CONFRONTO ROBUSTO: solo spire stabili (passaggi >100 in entrambi gli anni)
WITH per_spira AS (
    SELECT id_uni, max(nome_via) as nome_via,
           sum(passaggi) FILTER (WHERE anno=2022) as p22,
           sum(passaggi) FILTER (WHERE anno=2025) as p25
    FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
    WHERE anno IN (2022, 2025)
    GROUP BY id_uni
)
SELECT count(*) as spire_stabili,
       round(sum(p22) * 1.0 / count(DISTINCT id_uni) / 365, 0) as media_giorno_2022,
       round(sum(p25) * 1.0 / count(DISTINCT id_uni) / 365, 0) as media_giorno_2025,
       round((sum(p25) - sum(p22)) * 100.0 / sum(p22), 1) as var_pct
FROM per_spira WHERE p22 > 100 AND p25 > 100;

-- 4. Spire spente ad alto traffico (p22 > 100.000 passaggi, p25 quasi zero)
--    → dove la rete di misura è stata ritirata
SELECT max(nome_via) as via, id_uni,
       round(sum(passaggi) FILTER (WHERE anno=2022) / 365.0, 0) as passaggi_giorno_2022
FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
WHERE anno IN (2022, 2025)
GROUP BY id_uni
HAVING sum(passaggi) FILTER (WHERE anno=2022) > 100000
   AND (sum(passaggi) FILTER (WHERE anno=2025) < 1000)
ORDER BY passaggi_giorno_2022 DESC;

-- 5. Profilo orario 2022 vs 2025 — SOLO spire stabili (la forma della giornata)
SELECT ora_inizio,
       round(avg(passaggi) FILTER (WHERE anno=2022), 0) as media_2022,
       round(avg(passaggi) FILTER (WHERE anno=2025), 0) as media_2025,
       round((avg(passaggi) FILTER (WHERE anno=2025) - avg(passaggi) FILTER (WHERE anno=2022)) * 100.0 /
             nullif(avg(passaggi) FILTER (WHERE anno=2022), 0), 1) as var_pct
FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
WHERE anno IN (2022, 2025) AND ora_inizio BETWEEN 6 AND 21
  AND id_uni IN (
    SELECT id_uni FROM (
        SELECT id_uni,
               sum(passaggi) FILTER (WHERE anno=2022) p22,
               sum(passaggi) FILTER (WHERE anno=2025) p25
        FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
        WHERE anno IN (2022,2025) GROUP BY id_uni
    ) WHERE p22 > 100 AND p25 > 100
  )
GROUP BY ora_inizio ORDER BY ora_inizio;

-- 6. Confronto con la ZTL: le due cerchie a confronto
--    (ZTL: analisi 07, -22% 2019→2025 su passaggi/giorno)
--    (Spire: -11,7% 2022→2025 su passaggi/spira/giorno, spire stabili)
--    Nota: periodi diversi per disponibilità dati — ZTL dal 2019, spire dal 2022.
SELECT 'ZTL (2019-2025)' as cerchia, round((61032.0 - 78017.0) * 100.0 / 78017.0, 1) as var_pct
UNION ALL
SELECT 'Spire (2022-2025)', -11.7;
