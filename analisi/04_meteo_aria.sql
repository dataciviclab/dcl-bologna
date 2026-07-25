-- ============================================================
-- Analisi 04: Meteo e qualità dell'aria a Bologna
-- Dataset: temperature, precipitazioni, centraline-aria
-- Copertura: 2001–2026 (temperature/precipitazioni), 2026 (aria)
-- ============================================================

-- 0. Verifica copertura
SELECT 'temperature' as ds, min(date) as dal, max(date) as al FROM read_parquet('_data/temperature.parquet')
UNION ALL
SELECT 'precipitazioni', min(date), max(date) FROM read_parquet('_data/precipitazioni.parquet')
UNION ALL
SELECT 'aria', min(reftime::date), max(reftime::date) FROM read_parquet('_data/centraline-aria.parquet');

-- 1. Temperatura media per stagione (2001–2026)
SELECT stagione, 
       round(avg(avg), 1) as temp_media,
       round(avg(max), 1) as media_max,
       round(avg(min), 1) as media_min
FROM read_parquet('_data/temperature.parquet')
GROUP BY stagione ORDER BY stagione;

-- 2. Giorni più piovosi (top 10)
SELECT date, "184_avg_d" as mm
FROM read_parquet('_data/precipitazioni.parquet')
ORDER BY mm DESC LIMIT 10;

-- 3. Pioggia media per stagione
SELECT stagione, 
       round(avg("184_avg_d"), 1) as pioggia_media_mm,
       count(*) as giorni
FROM read_parquet('_data/precipitazioni.parquet')
GROUP BY stagione ORDER BY stagione;

-- 4. Correlazione temperatura ~ NO2 (2026)
--    Negativa: più caldo = meno NO2 (effetto ferie + dispersione)
SELECT corr(t.avg, a.value) as corr_temp_no2
FROM read_parquet('_data/temperature.parquet') t
JOIN read_parquet('_data/centraline-aria.parquet') a ON t.date = a.reftime::date
WHERE a.agente_atm = 'NO2 (Biossido di azoto)' 
  AND a.stazione LIKE 'PORTA SAN FELICE%'
  AND extract(year FROM t.date) = 2026;
