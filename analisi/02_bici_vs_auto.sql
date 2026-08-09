-- ============================================================
-- Analisi 02: Bici vs Auto su Viale Ercolani (2024)
-- Dataset: colonnine-bici, varchi-ztl (varco n.44 Ercolani)
-- Nota: richiede toolkit run per colonnine-bici e varchi-ztl.
--
-- METODO (fix 2026-08-09): i due dataset hanno coperture diverse
-- nel 2024 (bici: 366 giorni, auto: 308 giorni). Un JOIN su data
-- butterebbe via i giorni in cui rileva solo uno dei due → le
-- medie/giorno sono calcolate SEPARATAMENTE per dataset, con
-- denominatore = giorni rilevati propri. Il rapporto bici/auto
-- si calcola sulle medie/giorno, non sui totali annuali.
-- ============================================================

-- 0. Verifica copertura: giorni con dati nel 2024 (per dataset)
SELECT 'bici' as dataset, count(DISTINCT data::date) as giorni,
       sum(totale) as totale_anno
FROM read_parquet('out/data/clean/colonnine_bici/2026/colonnine_bici_2026_clean.parquet')
WHERE colonnina='Ercolani' AND extract(year FROM data)=2024
UNION ALL
SELECT 'auto', count(DISTINCT data::date),
       sum(auto_furgoni + moto_ciclomotori)
FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
WHERE varco=44 AND extract(year FROM data)=2024;

-- 1. Volumi annuali: bici (colonnina Ercolani) vs auto (varco n.44)
--    Medie/giorno su giorni EFFETTIVI di rilevazione per dataset.
WITH bici AS (
    SELECT sum(totale) as tot, count(DISTINCT data::date) as giorni
    FROM read_parquet('out/data/clean/colonnine_bici/2026/colonnine_bici_2026_clean.parquet')
    WHERE colonnina='Ercolani' AND extract(year FROM data)=2024
), auto AS (
    SELECT sum(auto_furgoni + moto_ciclomotori) as tot, count(DISTINCT data::date) as giorni
    FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
    WHERE varco=44 AND extract(year FROM data)=2024
)
SELECT round(b.tot / b.giorni, 0) as bici_giorno,
       round(a.tot / a.giorni, 0) as auto_giorno,
       round((b.tot / b.giorni) / nullif(a.tot / a.giorni, 0), 1) as bici_per_auto,
       b.giorni as giorni_bici, a.giorni as giorni_auto
FROM bici b, auto a;

-- 2. Profilo orario (media bici e auto per ora, 2024)
--    Medie calcolate separatamente per dataset: ogni media/ora è
--    su tutti i giorni in cui QUEL dataset rileva (niente JOIN che
--    taglia la copertura). La colonna giorni dice il denominatore.
SELECT extract(hour FROM data) as ora,
       round(avg(totale), 0) as media_bici,
       count(DISTINCT data::date) as giorni_bici
FROM read_parquet('out/data/clean/colonnine_bici/2026/colonnine_bici_2026_clean.parquet')
WHERE colonnina='Ercolani' AND extract(year FROM data)=2024
GROUP BY ora
ORDER BY ora;
-- (la media auto/ora è nella query 2b, qui sotto, per leggibilità)
-- 2b. Profilo orario auto (varco 44, 2024)
SELECT extract(hour FROM data) as ora,
       round(avg(auto_furgoni + moto_ciclomotori), 0) as media_auto,
       count(DISTINCT data::date) as giorni_auto
FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
WHERE varco=44 AND extract(year FROM data)=2024
GROUP BY ora
ORDER BY ora;
