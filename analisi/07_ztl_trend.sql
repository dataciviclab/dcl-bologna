-- ============================================================
-- Analisi 07: Meno auto in ZTL — Bologna 2019→2025
-- Dataset: varchi-ztl (80 varchi, 18,6M records, serie oraria)
-- Path: out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet
--
-- Domanda: come è cambiato il traffico veicolare in ZTL dal 2019?
-- Nota: 2026 è parziale (anno in corso) → i confronti usano 2019-2025.
-- Nota: gli anni hanno giorni rilevati diversi (365 nel 2019, 345 nel
-- 2025) → i confronti per varco usano passaggi/giorno, non i totali.
-- ============================================================

-- 0. Verifica copertura: anni, varchi attivi, giorni rilevati
SELECT anno,
       count(DISTINCT varco) as varchi_attivi,
       count(DISTINCT data::date) as giorni_rilevati,
       round(sum(totale_passaggi)/1000000.0, 1) as passaggi_mln
FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
GROUP BY anno ORDER BY anno;

-- 1. Trend totale passaggi (2019-2025) — con media/giorno normalizzata
WITH per_anno AS (
    SELECT anno,
           sum(totale_passaggi) as tot,
           count(DISTINCT data::date) as giorni
    FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
    WHERE anno BETWEEN 2019 AND 2025
    GROUP BY anno
)
SELECT anno, round(tot/1000000.0, 1) as passaggi_mln,
       round(tot * 1.0 / giorni, 0) as passaggi_giorno,
       round((tot * 1.0 / giorni) * 100.0 / first_value(tot * 1.0 / giorni) OVER (ORDER BY anno), 1) as idx_2019_100
FROM per_anno ORDER BY anno;

-- 2. Variazione per varco 2019→2025, normalizzata su giorni (top cali)
--    Nota: 'San Felice' è più varchi con lo stesso nome → chiave = varco.
WITH per_varco AS (
    SELECT varco, max(nome_varco) as nome_varco,
           sum(totale_passaggi) FILTER (WHERE anno=2019) as p2019,
           count(DISTINCT data::date) FILTER (WHERE anno=2019) as g2019,
           sum(totale_passaggi) FILTER (WHERE anno=2025) as p2025,
           count(DISTINCT data::date) FILTER (WHERE anno=2025) as g2025
    FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
    WHERE anno IN (2019, 2025)
    GROUP BY varco
)
SELECT nome_varco, varco,
       round(p2019 * 1.0 / g2019, 0) as media_giorno_2019,
       round(p2025 * 1.0 / g2025, 0) as media_giorno_2025,
       round((p2025 * 1.0 / g2025 - p2019 * 1.0 / g2019) * 100.0 / (p2019 * 1.0 / g2019), 1) as var_pct
FROM per_varco
WHERE p2019 > 0 AND p2025 > 0
ORDER BY var_pct LIMIT 10;

-- 3. Variazione per varco 2019→2025 (top crescita, se esistono)
WITH per_varco AS (
    SELECT varco, max(nome_varco) as nome_varco,
           sum(totale_passaggi) FILTER (WHERE anno=2019) as p2019,
           count(DISTINCT data::date) FILTER (WHERE anno=2019) as g2019,
           sum(totale_passaggi) FILTER (WHERE anno=2025) as p2025,
           count(DISTINCT data::date) FILTER (WHERE anno=2025) as g2025
    FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
    WHERE anno IN (2019, 2025)
    GROUP BY varco
)
SELECT nome_varco, varco,
       round(p2019 * 1.0 / g2019, 0) as media_giorno_2019,
       round(p2025 * 1.0 / g2025, 0) as media_giorno_2025,
       round((p2025 * 1.0 / g2025 - p2019 * 1.0 / g2019) * 100.0 / (p2019 * 1.0 / g2019), 1) as var_pct
FROM per_varco
WHERE p2019 > 0 AND p2025 > 0 AND p2025 * 1.0 / g2025 > p2019 * 1.0 / g2019
ORDER BY var_pct DESC LIMIT 5;

-- 4. Trend passaggi irregolari (transito_generico_irregolare), quota sul totale
--    ⚠ LIMITE: colonne di classificazione non documentate dal Comune e non
--    mutuamente esclusive (la somma delle categorie eccede il totale).
--    Utilizzabile come TREND, non come valore assoluto di "trasgressori".
SELECT anno,
       round(sum(transito_generico_irregolare)/1000000.0, 1) as irregolari_mln,
       round(sum(transito_generico_irregolare) * 100.0 / nullif(sum(totale_passaggi), 0), 1) as pct_irregolari
FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
WHERE anno BETWEEN 2019 AND 2025
GROUP BY anno ORDER BY anno;

-- 5. Top varchi per volume 2025 (passaggi/giorno)
SELECT varco, nome_varco,
       round(sum(totale_passaggi)/1000000.0, 2) as mln_passaggi,
       round(sum(totale_passaggi) * 1.0 / count(DISTINCT data::date), 0) as passaggi_giorno
FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
WHERE anno = 2025
GROUP BY varco, nome_varco
ORDER BY mln_passaggi DESC LIMIT 10;

-- 6. Profilo orario 2019 vs 2025 (tutti i varchi) — come è cambiata la forma della giornata
SELECT extract(hour FROM data) as ora,
       round(avg(totale_passaggi) FILTER (WHERE anno=2019), 0) as media_2019,
       round(avg(totale_passaggi) FILTER (WHERE anno=2025), 0) as media_2025,
       round((avg(totale_passaggi) FILTER (WHERE anno=2025) - avg(totale_passaggi) FILTER (WHERE anno=2019)) * 100.0 /
             nullif(avg(totale_passaggi) FILTER (WHERE anno=2019), 0), 1) as var_pct
FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
WHERE anno IN (2019, 2025) AND extract(hour FROM data) BETWEEN 6 AND 21
GROUP BY ora ORDER BY ora;
