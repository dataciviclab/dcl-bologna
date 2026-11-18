-- ============================================================
-- Analisi 15: tassi per abitante e per quartiere
--
-- A cosa serve: normalizzare i dati puntuali. Un quartiere con più bici o
-- più traffico non è "più ciclabile" o "più trafficato" se ha anche più
-- abitanti. Il denominatore è la popolazione per zona/quartiere (già in
-- repo: popolazione_quartiere = popolazione per età × zona × sesso ×
-- cittadinanza, 1986-2024).
--
-- 1. Bici per 1.000 abitanti per zona (colonnine, 2025)
-- 2. Passaggi auto per 1.000 abitanti per quartiere (spire, gen-ott 2025)
--    → il quartiere arriva dal crosswalk RIFTER `codvia` (mart_via_quartiere),
--      non da un mapping manuale: 320/320 vie coperte.
-- 3. Copertura: quante zone/quartieri hanno dati
--
-- Limite noto: i varchi ZTL non hanno `codvia` nel clean (solo coordinate),
-- quindi restano fuori da questo join finché non c'è un join spaziale.
-- ============================================================

-- 1. Bici per 1.000 abitanti per zona (2025, tutte le colonnine attive)
WITH pop_zona AS (
    SELECT zona, SUM(residenti) AS residenti
    FROM read_parquet('out/data/clean/popolazione_quartiere/*/popolazione_quartiere_*_clean.parquet')
    WHERE anno = 2024
    GROUP BY zona
),
bici_zona AS (
    SELECT
        zona,
        COUNT(DISTINCT colonnina) AS colonnine,
        -- `data` è un TIMESTAMP ORARIO: COUNT(DISTINCT data) darebbe le ore
        -- (8.759 nel 2025), non i giorni. Il CAST a DATE è obbligatorio.
        COUNT(DISTINCT CAST(data AS DATE)) AS giorni,
        SUM(totale) AS passaggi_bici
    FROM read_parquet('out/data/clean/colonnine_bici/*/colonnine_bici_*_clean.parquet')
    WHERE anno = 2025 AND zona IS NOT NULL
    GROUP BY zona
)
SELECT
    b.zona,
    b.colonnine,
    b.giorni,
    ROUND(b.passaggi_bici * 1.0 / b.giorni) AS bici_media_giornaliera,
    p.residenti,
    ROUND(1000.0 * (b.passaggi_bici * 1.0 / b.giorni) / p.residenti, 2)
        AS bici_media_giornaliera_per_1000
FROM bici_zona b
JOIN pop_zona p USING (zona)
ORDER BY bici_media_giornaliera_per_1000 DESC;

-- 2. Passaggi auto per 1.000 abitanti per quartiere (spire, gen-ott 2025)
WITH via_quartiere AS (
    -- Una via può stare su due quartieri (120 su 1.972). Il consumer sceglie:
    -- qui il quartiere con più archi, come dichiara il commento del mart.
    SELECT codvia, arg_max(quartiere, archi) AS quartiere
    FROM read_parquet('out/data/mart/rifter_archi/2026/mart_via_quartiere.parquet')
    GROUP BY codvia
),
spire_via AS (
    SELECT
        codice_via,
        SUM(passaggi) * 1.0 / COUNT(DISTINCT data) AS passaggi_giorno
    FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
    WHERE anno = 2025 AND MONTH(data) <= 10 AND codice_via IS NOT NULL
    GROUP BY codice_via
),
pop_quartiere AS (
    SELECT quartiere, SUM(residenti) AS residenti
    FROM read_parquet('out/data/clean/popolazione_quartiere/*/popolazione_quartiere_*_clean.parquet')
    WHERE anno = 2024
    GROUP BY quartiere
)
SELECT
    q.quartiere,
    COUNT(DISTINCT s.codice_via) AS vie,
    ROUND(SUM(s.passaggi_giorno)) AS passaggi_giorno,
    p.residenti,
    ROUND(1000.0 * SUM(s.passaggi_giorno) / p.residenti) AS passaggi_giorno_per_1000
FROM spire_via s
JOIN via_quartiere q ON s.codice_via = q.codvia
JOIN pop_quartiere p ON q.quartiere = p.quartiere
GROUP BY q.quartiere, p.residenti
ORDER BY passaggi_giorno_per_1000 DESC;

-- 3. Copertura: quanto del territorio è rappresentato dai dati puntuali
WITH zone_colonnine AS (
    SELECT DISTINCT zona
    FROM read_parquet('out/data/clean/colonnine_bici/*/colonnine_bici_*_clean.parquet')
    WHERE zona IS NOT NULL
),
zone_popolazione AS (
    SELECT DISTINCT zona
    FROM read_parquet('out/data/clean/popolazione_quartiere/*/popolazione_quartiere_*_clean.parquet')
    WHERE anno = 2024
),
quartieri_spire AS (
    SELECT DISTINCT q.quartiere
    FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet') s
    JOIN (SELECT codvia, arg_max(quartiere, archi) AS quartiere
          FROM read_parquet('out/data/mart/rifter_archi/2026/mart_via_quartiere.parquet')
          GROUP BY codvia) q ON s.codice_via = q.codvia
    WHERE s.anno = 2025
),
quartieri_popolazione AS (
    -- "Senza fissa dimora" è una categoria della fonte, non un quartiere:
    -- 9.703 residenti (2024) che non vanno in un denominatore geografico.
    SELECT DISTINCT quartiere
    FROM read_parquet('out/data/clean/popolazione_quartiere/*/popolazione_quartiere_*_clean.parquet')
    WHERE anno = 2024 AND quartiere <> 'Senza fissa dimora'
)
SELECT 'zone con colonnine' AS indicatore,
       (SELECT COUNT(*) FROM zone_colonnine) AS coperte,
       (SELECT COUNT(*) FROM zone_popolazione) AS totali
UNION ALL
SELECT 'quartieri con spire',
       (SELECT COUNT(*) FROM quartieri_spire),
       (SELECT COUNT(*) FROM quartieri_popolazione);
