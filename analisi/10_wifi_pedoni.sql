-- ============================================================
-- Analisi 10: Bologna a piedi — la mobilità pedonale dal WiFi (2021-2025)
-- Dataset: bolognawifi-matrice (flussi pedoni tra zone WiFi, 1,47M righe)
-- Path: out/data/clean/bolognawifi_matrice/2026/bolognawifi_matrice_2026_clean.parquet
--
-- Domanda: dove e quando camminano i bolognesi? Complementa le analisi
-- 07 (auto in ZTL) e 09 (auto fuori ZTL): ora i PEDONI.
--
-- NOTA METODO:
-- 1. 'totale' = dispositivi connessi spostatisi tra zone → PROXY della
--    mobilità pedonale, non censimento persone.
-- 2. Copertura disomogenea: 2021 parte da aprile (275g), 2025 a 353g →
--    confronti anno-anno su media/giorno, mai sui totali.
-- 3. Il picco orario pedone è confrontabile con mart_wifi_ora e con le
--    analisi 07/09 (profilo auto).
-- ============================================================

-- 0. Verifica copertura: anni, giorni, righe
SELECT anno, count(DISTINCT data) as giorni,
       count(*) as righe, round(sum(totale)/1000000.0, 1) as flussi_mln
FROM read_parquet('out/data/clean/bolognawifi_matrice/2026/bolognawifi_matrice_2026_clean.parquet')
GROUP BY anno ORDER BY anno;

-- 1. Trend annuale normalizzato (media/giorno) — quando si cammina di più?
SELECT anno, count(DISTINCT data) as giorni,
       round(sum(totale) * 1.0 / count(DISTINCT data), 0) as flussi_giorno
FROM read_parquet('out/data/clean/bolognawifi_matrice/2026/bolognawifi_matrice_2026_clean.parquet')
GROUP BY anno ORDER BY anno;

-- 2. Profilo orario 2024 (anno completo): la forma della giornata pedonale
SELECT ora, round(avg(totale), 0) as media_pedoni
FROM read_parquet('out/data/clean/bolognawifi_matrice/2026/bolognawifi_matrice_2026_clean.parquet')
WHERE anno = 2024 AND ora BETWEEN 6 AND 22
GROUP BY ora ORDER BY ora;

-- 3. Feriale vs Weekend 2024: la città pedonale vive di sabato?
SELECT CASE WHEN giorno_num >= 6 THEN 'Weekend' ELSE 'Feriale' END as tipo,
       round(sum(totale) * 1.0 / count(DISTINCT data), 0) as flussi_giorno
FROM read_parquet('out/data/clean/bolognawifi_matrice/2026/bolognawifi_matrice_2026_clean.parquet')
WHERE anno = 2024
GROUP BY tipo ORDER BY flussi_giorno DESC;

-- 4. Le rotte più battute 2025 (coppie origine→destinazione)
SELECT label_origine, label_destinazione, sum(totale) as flussi_2025
FROM read_parquet('out/data/clean/bolognawifi_matrice/2026/bolognawifi_matrice_2026_clean.parquet')
WHERE anno = 2025
GROUP BY label_origine, label_destinazione
ORDER BY flussi_2025 DESC LIMIT 10;

-- 5. Le zone più attive 2025 (origine + destinazione aggregate)
WITH flussi AS (
    SELECT id_origine as zona, totale FROM read_parquet('out/data/clean/bolognawifi_matrice/2026/bolognawifi_matrice_2026_clean.parquet') WHERE anno = 2025
    UNION ALL
    SELECT id_destinazione, totale FROM read_parquet('out/data/clean/bolognawifi_matrice/2026/bolognawifi_matrice_2026_clean.parquet') WHERE anno = 2025
)
SELECT max(label_zona) as zona, sum(totale) as flussi_totali
FROM flussi f JOIN (SELECT DISTINCT id_origine, max(label_origine) as label_zona FROM read_parquet('out/data/clean/bolognawifi_matrice/2026/bolognawifi_matrice_2026_clean.parquet') GROUP BY id_origine) z ON f.zona = z.id_origine
GROUP BY f.zona ORDER BY flussi_totali DESC LIMIT 10;
