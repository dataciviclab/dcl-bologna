-- ============================================================
-- Analisi 02: Bici vs Auto su Viale Ercolani (2024)
-- Dataset: colonnine-bici, varchi-ztl (varco n.44 Ercolani)
-- Nota: richiede toolkit run per colonnine-bici e varchi-ztl.
-- Copertura 2024: entrambi i dataset coprono l'intero anno
-- (colonnina Ercolani: dati continui dal 2018; varco: dal 2019).
-- ============================================================

-- 0. Verifica copertura: giorni con dati nel 2024
SELECT 'bici' as dataset, count(DISTINCT data::date) as giorni
FROM read_parquet('out/data/clean/colonnine_bici/2026/colonnine_bici_2026_clean.parquet')
WHERE colonnina='Ercolani' AND extract(year FROM data)=2024
UNION ALL
SELECT 'auto', count(DISTINCT data::date)
FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
WHERE varco=44 AND extract(year FROM data)=2024;

-- 1. Volumi annuali: bici (colonnina Ercolani) vs auto (varco n.44)
--    Le medie giornaliere sono calcolate su 365 giorni (anno solare).
SELECT extract(year FROM b.data) as anno,
       sum(b.totale) as bici,
       sum(a.auto_furgoni + a.moto_ciclomotori) as veicoli,
       round(sum(b.totale) * 1.0 / nullif(sum(a.auto_furgoni + a.moto_ciclomotori), 0), 1) as bici_per_veicolo,
       round(sum(b.totale) / 365.0, 0) as bici_giorno,
       round(sum(a.auto_furgoni + a.moto_ciclomotori) / 365.0, 0) as veicoli_giorno
FROM read_parquet('out/data/clean/colonnine_bici/2026/colonnine_bici_2026_clean.parquet') b
JOIN read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet') a ON b.data = a.data AND a.varco = 44
WHERE b.colonnina='Ercolani'
  AND extract(year FROM b.data) = 2024
GROUP BY anno;

-- 2. Profilo orario (media bici e auto per ora, 2024)
SELECT extract(hour FROM b.data) as ora,
       round(avg(b.totale), 0) as media_bici,
       round(avg(a.auto_furgoni + a.moto_ciclomotori), 0) as media_veicoli,
       round(avg(b.totale) * 1.0 / nullif(avg(a.auto_furgoni + a.moto_ciclomotori), 0), 1) as rapporto
FROM read_parquet('out/data/clean/colonnine_bici/2026/colonnine_bici_2026_clean.parquet') b
JOIN read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet') a ON b.data = a.data AND a.varco = 44
WHERE b.colonnina='Ercolani'
  AND extract(year FROM b.data) = 2024
GROUP BY ora ORDER BY ora;
