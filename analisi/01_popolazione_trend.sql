-- ============================================================
-- Analisi 01: Trend demografici Bologna 1986–2024
-- Dataset: popolazione-quartiere (clean parquet, anno INTEGER)
-- Path: out/data/clean/popolazione_quartiere/2024/...clean.parquet
-- ============================================================

-- 1. Popolazione totale per anno
SELECT anno, sum(residenti) as popolazione
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
GROUP BY anno ORDER BY anno;

-- 2. Variazione per quartiere (1986 → 2024)
SELECT quartiere,
       sum(CASE WHEN anno=1986 THEN residenti ELSE 0 END) as anno_1986,
       sum(CASE WHEN anno=2024 THEN residenti ELSE 0 END) as anno_2024,
       round((sum(CASE WHEN anno=2024 THEN residenti ELSE 0 END) - 
              sum(CASE WHEN anno=1986 THEN residenti ELSE 0 END)) / 
              sum(CASE WHEN anno=1986 THEN residenti ELSE 0 END) * 100, 1) as var_pct
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
WHERE quartiere != 'Senza fissa dimora'
GROUP BY quartiere
ORDER BY var_pct;

-- 3. Piramide età 2024 (grandi classi)
SELECT eta_grandi,
       sum(CASE WHEN sesso='Maschi' THEN residenti ELSE 0 END) as maschi,
       sum(CASE WHEN sesso='Femmine' THEN residenti ELSE 0 END) as femmine,
       sum(residenti) as totale
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
WHERE anno=2024
GROUP BY eta_grandi
ORDER BY eta_grandi;

-- 4. Stranieri per quartiere 2024
SELECT quartiere,
       sum(CASE WHEN cittadinanza='Straniera' THEN residenti ELSE 0 END) as stranieri,
       sum(residenti) as totale,
       round(sum(CASE WHEN cittadinanza='Straniera' THEN residenti ELSE 0 END) * 100.0 / 
             sum(residenti), 1) as pct_stranieri
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
WHERE anno=2024 AND quartiere != 'Senza fissa dimora'
GROUP BY quartiere
ORDER BY pct_stranieri DESC;

-- 5. Evoluzione stranieri (decennale)
SELECT anno,
       sum(CASE WHEN cittadinanza='Straniera' THEN residenti ELSE 0 END) as stranieri,
       round(sum(CASE WHEN cittadinanza='Straniera' THEN residenti ELSE 0 END) * 100.0 / 
             sum(residenti), 1) as pct
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
WHERE anno IN (1990,1995,2000,2005,2010,2015,2020,2024)
GROUP BY anno ORDER BY anno;

-- 6. Età media per quartiere 2024
SELECT quartiere,
       round(sum(eta_singolo * residenti) / sum(residenti), 1) as eta_media
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
WHERE anno=2024 AND quartiere != 'Senza fissa dimora'
GROUP BY quartiere
ORDER BY eta_media DESC;

-- 7. Rapporto giovani/anziani per quartiere 2024
SELECT quartiere,
       sum(CASE WHEN eta_singolo < 15 THEN residenti ELSE 0 END) as giovani_0_14,
       sum(CASE WHEN eta_singolo >= 65 THEN residenti ELSE 0 END) as anziani_65plus,
       round(sum(CASE WHEN eta_singolo >= 65 THEN residenti ELSE 0 END) * 1.0 / 
             NULLIF(sum(CASE WHEN eta_singolo < 15 THEN residenti ELSE 0 END), 0), 1) as rapporto_anziani_giovani
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
WHERE anno=2024 AND quartiere != 'Senza fissa dimora'
GROUP BY quartiere
ORDER BY rapporto_anziani_giovani DESC;

-- 8. Zone con più bambini 0-5 anni 2024
SELECT quartiere, zona, sum(residenti) as bambini_0_5
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
WHERE anno=2024 AND eta_singolo BETWEEN 0 AND 5
GROUP BY quartiere, zona
ORDER BY bambini_0_5 DESC
LIMIT 10;

-- 9. Zone con più over 80 2024
SELECT quartiere, zona, sum(residenti) as over_80
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
WHERE anno=2024 AND eta_singolo >= 80
GROUP BY quartiere, zona
ORDER BY over_80 DESC
LIMIT 10;

-- 10. Trend residenti italiani 1986-2024 (solo Maschi, filtro rapido)
SELECT anno, sum(residenti) as italiani_maschi
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
WHERE cittadinanza='Italiana' AND sesso='Maschi'
GROUP BY anno ORDER BY anno;
