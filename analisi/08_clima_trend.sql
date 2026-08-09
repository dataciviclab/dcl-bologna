-- ============================================================
-- Analisi 08: Bologna si scalda — 25 anni di clima (2001-2025)
-- Dataset: temperature, precipitazioni (serie giornaliera)
-- Path: out/data/clean/temperature_bologna/2026/temperature_bologna_2026_clean.parquet
--       out/data/clean/precipitazioni_bologna/2026/precipitazioni_bologna_2026_clean.parquet
--
-- Domanda: come è cambiato il clima di Bologna negli ultimi 25 anni?
-- Nota metodo: i periodi hanno lunghezze diverse (10/10/5 anni) → ogni
-- conteggio è NORMALIZZATO per anno (÷10 per i decenni, ÷5 per 2021-2025).
-- 2026 escluso (anno parziale). Copertura verificata: 365 giorni/anno.
-- ============================================================

-- 0. Verifica copertura: estremi temporali e giorni per anno
SELECT 'temperature' as ds, min(date) as dal, max(date) as al, count(*) as records
FROM read_parquet('out/data/clean/temperature_bologna/2026/temperature_bologna_2026_clean.parquet')
UNION ALL
SELECT 'precipitazioni', min(date), max(date), count(*)
FROM read_parquet('out/data/clean/precipitazioni_bologna/2026/precipitazioni_bologna_2026_clean.parquet');

-- 1. Temperatura media per periodo
--    Nota: avg() diretto sulle medie giornaliere (ogni giorno conta 1).
SELECT periodo,
       round(avg(avg), 2) as temp_media_anno,
       round(avg(max), 1) as media_max_anno,
       round(avg(min), 1) as media_min_anno
FROM (
    SELECT CASE WHEN extract(year FROM date) BETWEEN 2001 AND 2010 THEN '2001-2010'
                WHEN extract(year FROM date) BETWEEN 2011 AND 2020 THEN '2011-2020'
                ELSE '2021-2025' END as periodo,
           avg, max, min
    FROM read_parquet('out/data/clean/temperature_bologna/2026/temperature_bologna_2026_clean.parquet')
    WHERE extract(year FROM date) <= 2025
) GROUP BY periodo ORDER BY periodo;

-- 2. Giorni estremi per periodo (normalizzati per anno)
SELECT periodo,
       round(afa / anni, 1) as giorni_afa_anno,      -- max >= 35°C
       round(notti / anni, 1) as notti_tropicali_anno, -- min >= 20°C
       round(g30 / anni, 1) as giorni_30plus_anno    -- max >= 30°C
FROM (
    SELECT CASE WHEN extract(year FROM date) BETWEEN 2001 AND 2010 THEN '2001-2010'
                WHEN extract(year FROM date) BETWEEN 2011 AND 2020 THEN '2011-2020'
                ELSE '2021-2025' END as periodo,
           CASE WHEN extract(year FROM date) BETWEEN 2001 AND 2010 THEN 10
                WHEN extract(year FROM date) BETWEEN 2011 AND 2020 THEN 10
                ELSE 5 END as anni,
           count(*) FILTER (WHERE max >= 35) as afa,
           count(*) FILTER (WHERE min >= 20) as notti,
           count(*) FILTER (WHERE max >= 30) as g30
    FROM read_parquet('out/data/clean/temperature_bologna/2026/temperature_bologna_2026_clean.parquet')
    WHERE extract(year FROM date) <= 2025
    GROUP BY periodo, anni
) ORDER BY periodo;

-- 3. Precipitazioni per periodo (normalizzate per anno)
SELECT periodo,
       round(mm / anni, 0) as mm_anno,
       round(gp / anni, 0) as giorni_pioggia_anno
FROM (
    SELECT CASE WHEN extract(year FROM date) BETWEEN 2001 AND 2010 THEN '2001-2010'
                WHEN extract(year FROM date) BETWEEN 2011 AND 2020 THEN '2011-2020'
                ELSE '2021-2025' END as periodo,
           CASE WHEN extract(year FROM date) BETWEEN 2001 AND 2010 THEN 10
                WHEN extract(year FROM date) BETWEEN 2011 AND 2020 THEN 10
                ELSE 5 END as anni,
           sum(pioggia_mm) as mm,
           count(*) FILTER (WHERE pioggia_mm >= 1) as gp
    FROM read_parquet('out/data/clean/precipitazioni_bologna/2026/precipitazioni_bologna_2026_clean.parquet')
    WHERE extract(year FROM date) <= 2025
    GROUP BY periodo, anni
) ORDER BY periodo;

-- 4. Gli anni più caldi della serie (top 5)
SELECT extract(year FROM date) as anno, round(avg(avg), 2) as t_media
FROM read_parquet('out/data/clean/temperature_bologna/2026/temperature_bologna_2026_clean.parquet')
WHERE extract(year FROM date) <= 2025
GROUP BY anno ORDER BY t_media DESC LIMIT 5;

-- 5. Gli anni più piovosi della serie (top 5)
SELECT extract(year FROM date) as anno, round(sum(pioggia_mm), 0) as mm_anno
FROM read_parquet('out/data/clean/precipitazioni_bologna/2026/precipitazioni_bologna_2026_clean.parquet')
GROUP BY anno ORDER BY mm_anno DESC LIMIT 5;

-- 6. Variazione per stagione 2001-2010 vs 2021-2025 (dove si scalda di più?)
SELECT stagione,
       round(avg(avg) FILTER (WHERE extract(year FROM date) BETWEEN 2001 AND 2010), 1) as t_2001_2010,
       round(avg(avg) FILTER (WHERE extract(year FROM date) BETWEEN 2021 AND 2025), 1) as t_2021_2025,
       round(avg(avg) FILTER (WHERE extract(year FROM date) BETWEEN 2021 AND 2025) -
             avg(avg) FILTER (WHERE extract(year FROM date) BETWEEN 2001 AND 2010), 1) as delta_c
FROM read_parquet('out/data/clean/temperature_bologna/2026/temperature_bologna_2026_clean.parquet')
WHERE extract(year FROM date) <= 2025
GROUP BY stagione ORDER BY delta_c DESC;
