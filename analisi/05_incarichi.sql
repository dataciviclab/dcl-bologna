-- ============================================================
-- Analisi 05: Incarichi di collaborazione del Comune di Bologna
-- Dataset: incarichi
-- Copertura: 2012–2026, update weekly
-- Cross-Lab: partita_iva / ragione_sociale con ANAC
-- ============================================================

-- 0. Verifica copertura
SELECT min(anno_pg_atto) as dal, max(anno_pg_atto) as al, count(*) as records
FROM read_parquet('_data/incarichi.parquet');

-- 1. Incarichi per tipo
SELECT classificazione_incarichi, descrizione_classificazione_incarichi,
       count(*) as n, round(sum(importo_euro), 0) as totale,
       round(avg(importo_euro), 0) as media
FROM read_parquet('_data/incarichi.parquet')
GROUP BY classificazione_incarichi, descrizione_classificazione_incarichi
ORDER BY totale DESC;

-- 2. Incarichi per anno
SELECT extract(year FROM anno_pg_atto) as anno,
       count(*) as n,
       round(sum(importo_euro), 0) as totale
FROM read_parquet('_data/incarichi.parquet')
GROUP BY anno ORDER BY anno;

-- 3. Top 10 soggetti per importo totale
SELECT ragione_sociale, count(*) as incarichi,
       round(sum(importo_euro), 0) as totale,
       round(avg(importo_euro), 0) as media
FROM read_parquet('_data/incarichi.parquet')
GROUP BY ragione_sociale
ORDER BY totale DESC
LIMIT 10;

-- 4. Incarichi per settore/dipartimento
SELECT settore_dipartimento_area, count(*) as n,
       round(sum(importo_euro), 0) as totale
FROM read_parquet('_data/incarichi.parquet')
GROUP BY settore_dipartimento_area
ORDER BY totale DESC;

-- 5. Partite IVA da incrociare con ANAC
SELECT partita_iva, ragione_sociale, round(sum(importo_euro), 0) as totale
FROM read_parquet('_data/incarichi.parquet')
WHERE partita_iva IS NOT NULL AND partita_iva != ''
GROUP BY partita_iva, ragione_sociale
ORDER BY totale DESC;
