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
--
--    AGGIORNAMENTO 2026-11-18 — i numeri vengono dalla query 7 in fondo.
--    Il calo è CONCENTRATO, non diffuso: sul pannello di 775 spire presenti in
--    tutti gli anni (finestra gen-ott), 2022→2026 la mediana per spira è
--    -12,4% e il totale -22,9%, ma il calo netto viene tutto da **204 spire
--    con calo >40%** (-1.019.448 passaggi/spira/giorno su -1.019.818): le
--    altre 571 spire, sommate, valgono -371. Inoltre Via Stalingrado è tornata
--    ai livelli 2023 nel 2026 (140.119 passaggi/giorno a ottobre, contro
--    69.598 nel 2025): su una via di attraversamento è compatibile con
--    cantieri più che con una riduzione strutturale.
--    ATTENZIONE alle etichette: il benchmark della query 6 (-11,7%) è un
--    TOTALE su spire stabili 2022→2025, non una mediana.
--
SELECT 'ZTL (2019-2025)' as cerchia, round((61032.0 - 78017.0) * 100.0 / 78017.0, 1) as var_pct
UNION ALL
SELECT 'Spire (2022-2025)', -11.7;

-- 7. Il calo è concentrato? (pannello di spire presenti in tutti gli anni)
--
--    Sulle spire presenti in TUTTI gli anni 2022-2026, finestra gen-ott:
--    quante spiegano il calo totale? Serve a distinguere una riduzione diffusa
--    (tutte le strade calano un po') da una concentrata (poche arterie).
WITH y AS (
    SELECT id_spira, anno, sum(passaggi) * 1.0 / count(DISTINCT data) AS passaggi_giorno
    FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
    WHERE month(data) <= 10 AND anno BETWEEN 2022 AND 2026
    GROUP BY 1, 2
),
panel AS (
    SELECT id_spira FROM y GROUP BY 1 HAVING count(DISTINCT anno) = 5
),
p AS (
    SELECT
        id_spira,
        max(passaggi_giorno) FILTER (WHERE anno = 2022) AS a22,
        max(passaggi_giorno) FILTER (WHERE anno = 2026) AS a26
    FROM y JOIN panel USING (id_spira)
    GROUP BY 1
),
r AS (
    SELECT id_spira, a22, a26, a26 - a22 AS delta, (a26 - a22) / a22 AS variazione
    FROM p
)
SELECT
    count(*) AS spire,
    round(100.0 * median(variazione), 1) AS mediana_variazione_pct,
    round(100.0 * (sum(a26) - sum(a22)) / sum(a22), 1) AS totale_variazione_pct,
    count(*) FILTER (WHERE variazione < -0.4) AS spire_calo_oltre40,
    round(sum(delta) FILTER (WHERE variazione < -0.4)) AS calo_delle_over40,
    round(sum(delta) FILTER (WHERE variazione >= -0.4)) AS calo_delle_altre
FROM r;
