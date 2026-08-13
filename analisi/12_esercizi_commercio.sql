-- ============================================================
-- Analisi 12: Il tessuto commerciale di Bologna — bar e ristoranti
-- Dataset: esercizi-somministrazione (17.981 record, storico 1976-2026)
-- Path: out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet
--
-- Domanda: com'è fatto e come cambia il tessuto di bar/ristoranti?
-- Completa il blocco economia per area (reddito #11 + fragilità #35).
--
-- NOTA METODO:
-- 1. 'stato' è la verità (Attivo/Cessato), non data_cessazione.
-- 2. Sopravvivenza per decade: gli aperti nel 2020+ hanno avuto meno
--    anni per cessare → confronto indicativo, non tasso rigoroso.
-- 3. 171 record con quartiere pre-2016 (0,95%) esclusi dalle query
--    per quartiere.
-- ============================================================

-- 0. Verifica copertura: stato e finestra temporale
SELECT stato, count(*) as n
FROM read_parquet('out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet')
GROUP BY stato ORDER BY n DESC;

-- 1. Il quadro: attivi vs cessati, centro storico vs fuori
SELECT 
  CASE WHEN centro_storico IS NOT NULL THEN 'Centro storico' ELSE 'Fuori centro' END as zona_tipo,
  count(*) FILTER (WHERE stato='Attivo') as attivi,
  count(*) FILTER (WHERE stato='Cessato') as cessati,
  round(count(*) FILTER (WHERE stato='Attivo') * 100.0 / nullif(count(*) FILTER (WHERE stato IN ('Attivo','Cessato')),0), 1) as tasso_attivi_pct
FROM read_parquet('out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet')
GROUP BY zona_tipo;

-- 2. La sopravvivenza: quota ancora attiva per decade di apertura
SELECT 
  CASE WHEN extract(year FROM data_inizio_attivita) < 1990 THEN 'pre-1990'
       WHEN extract(year FROM data_inizio_attivita) < 2000 THEN '1990-99'
       WHEN extract(year FROM data_inizio_attivita) < 2010 THEN '2000-09'
       WHEN extract(year FROM data_inizio_attivita) < 2020 THEN '2010-19'
       ELSE '2020+' END as decennio,
  count(*) as aperti,
  count(*) FILTER (WHERE stato='Attivo') as ancora_attivi,
  round(count(*) FILTER (WHERE stato='Attivo') * 100.0 / count(*), 1) as sopravvivenza_pct
FROM read_parquet('out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet')
GROUP BY decennio ORDER BY decennio;

-- 3. Cessazioni per anno (2015+): il ritmo della desertificazione
SELECT extract(year FROM data_cessazione_attivita) as anno_cessazione, count(*) as n
FROM read_parquet('out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet')
WHERE data_cessazione_attivita IS NOT NULL AND extract(year FROM data_cessazione_attivita) >= 2015
GROUP BY anno_cessazione ORDER BY anno_cessazione;

-- 4. Attivi per quartiere (solo quartieri attuali — flag dal mart, no NOT IN)
SELECT quartiere, sum(n_esercizi) as attivi
FROM read_parquet('out/data/mart/esercizi_somministrazione/2026/mart_esercizi_quartiere.parquet')
WHERE stato='Attivo' AND quartiere_attuale = TRUE
GROUP BY quartiere ORDER BY sum(n_esercizi) DESC;

-- 5. Cessati per quartiere (storico, solo quartieri attuali)
SELECT quartiere, sum(n_esercizi) as cessati
FROM read_parquet('out/data/mart/esercizi_somministrazione/2026/mart_esercizi_quartiere.parquet')
WHERE stato='Cessato' AND quartiere_attuale = TRUE
GROUP BY quartiere ORDER BY sum(n_esercizi) DESC;

-- 6. Le botteghe storiche (flag della fonte, 11 record)
SELECT quartiere, esercizio_via, civico
FROM read_parquet('out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet')
WHERE bottega_storica IS NOT NULL AND bottega_storica != ''
ORDER BY quartiere;
