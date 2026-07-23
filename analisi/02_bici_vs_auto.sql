-- ============================================================
-- Analisi 02: Bici vs Auto su Viale Ercolani (2024)
-- Dataset: colonnine-bici, varco-ercolani
-- Nota: richiede make fetch per entrambi i dataset
-- ============================================================

-- 1. Volumi annuali: bici (colonnina Ercolani) vs auto (varco n.44)
SELECT extract(year FROM b.data) as anno,
       sum(b.totale) as bici,
       sum(a.auto_furgoni + a.moto_ciclomotori) as veicoli,
       round(sum(b.totale) * 1.0 / nullif(sum(a.auto_furgoni + a.moto_ciclomotori), 0), 1) as bici_per_veicolo,
       round(sum(b.totale) / 365.0, 0) as bici_giorno,
       round(sum(a.auto_furgoni + a.moto_ciclomotori) / 365.0, 0) as veicoli_giorno
FROM read_parquet('_data/colonnine-bici.parquet') b
JOIN read_parquet('_data/varco-ercolani.parquet') a ON b.data = a.data
WHERE b.colonnina='Ercolani'
  AND extract(year FROM b.data) = 2024
GROUP BY anno;

-- 2. Profilo orario (media bici e auto per ora, 2024)
SELECT extract(hour FROM b.data) as ora,
       round(avg(b.totale), 0) as media_bici,
       round(avg(a.auto_furgoni + a.moto_ciclomotori), 0) as media_veicoli,
       round(avg(b.totale) * 1.0 / nullif(avg(a.auto_furgoni + a.moto_ciclomotori), 0), 1) as rapporto
FROM read_parquet('_data/colonnine-bici.parquet') b
JOIN read_parquet('_data/varco-ercolani.parquet') a ON b.data = a.data
WHERE b.colonnina='Ercolani'
  AND extract(year FROM b.data) = 2024
GROUP BY ora ORDER BY ora;
