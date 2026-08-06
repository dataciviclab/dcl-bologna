-- ============================================================
-- Analisi 03: Qualità dell'aria e traffico veicolare
-- Dataset: centraline-aria, varchi-ztl (varco n.44 Ercolani)
-- Richiede: make fetch/centraline-aria, make fetch/varchi-ztl
-- ============================================================

-- 0. Verifica copertura: finestra temporale in overlap
SELECT 'aria' as ds, min(reftime) as dal, max(reftime) as al 
FROM read_parquet('_data/centraline-aria.parquet')
UNION ALL
SELECT 'auto', min(data), max(data)
FROM read_parquet('_data/varchi-ztl.parquet')
WHERE varco=44;

-- 1. NO2 medio per stazione (2026)
SELECT stazione, round(avg(value), 1) as media_no2
FROM read_parquet('_data/centraline-aria.parquet')
WHERE agente_atm='NO2 (Biossido di azoto)' AND extract(year FROM reftime)=2026
GROUP BY stazione ORDER BY media_no2 DESC;

-- 2. Profilo orario: NO2 (Porta San Felice) vs veicoli (varco Ercolani)
SELECT extract(hour FROM a.reftime) as ora,
       round(avg(a.value), 1) as media_no2,
       round(avg(v.auto_furgoni + v.moto_ciclomotori), 0) as media_veicoli
FROM read_parquet('_data/centraline-aria.parquet') a
JOIN read_parquet('_data/varchi-ztl.parquet') v ON a.reftime = v.data AND v.varco = 44
WHERE a.agente_atm='NO2 (Biossido di azoto)'
  AND a.stazione LIKE 'PORTA SAN FELICE%'
  AND extract(year FROM a.reftime)=2026
GROUP BY ora ORDER BY ora;

-- 3. Feriale vs Weekend
SELECT CASE WHEN extract(dow FROM a.reftime) IN (0,6) THEN 'Weekend' ELSE 'Feriale' END as tipo,
       round(avg(a.value), 1) as media_no2,
       round(avg(v.auto_furgoni + v.moto_ciclomotori), 0) as media_veicoli
FROM read_parquet('_data/centraline-aria.parquet') a
JOIN read_parquet('_data/varchi-ztl.parquet') v ON a.reftime = v.data AND v.varco = 44
WHERE a.agente_atm='NO2 (Biossido di azoto)'
  AND a.stazione LIKE 'PORTA SAN FELICE%'
  AND extract(year FROM a.reftime)=2026
GROUP BY tipo;

-- 4. Correlazione oraria NO2 ~ traffico
SELECT corr(a.value, v.auto_furgoni + v.moto_ciclomotori) as corr_no2_veicoli
FROM read_parquet('_data/centraline-aria.parquet') a
JOIN read_parquet('_data/varchi-ztl.parquet') v ON a.reftime = v.data AND v.varco = 44
WHERE a.agente_atm='NO2 (Biossido di azoto)'
  AND a.stazione LIKE 'PORTA SAN FELICE%'
  AND extract(year FROM a.reftime)=2026;
