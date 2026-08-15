-- ============================================================
-- Analisi 13: Il blocco economia per area — reddito × fragilità × commercio
-- Dataset: reddito-mediano (2024), indici-fragilita (2023), esercizi (attuali)
-- Path: out/data/clean/<slug>/2026/<slug>_2026_clean.parquet
--
-- Domanda: le aree povere sono anche fragili? E dove sta il commercio?
-- Completa e incrocia le analisi 11 (reddito), 12 (commercio) e il
-- candidate fragilità (#35) — prima analisi CROSS del blocco economia.
--
-- NOTA METODO:
-- 1. JOIN su UPPER(area_statistica): esercizi usa MAIUSCOLO, reddito/
--    fragilità case normale (verificato: 88/88 aree matchano con UPPER).
-- 2. Anni: reddito 2024 (ultimo), fragilità 2023 (ultimo), esercizi
--    stato attuale. Non sono lo stesso anno — lettura strutturale,
--    non temporale.
-- 3. frag_compl: indice sintetico (più alto = più fragile).
-- ============================================================

-- 0. Verifica della join: quante aree matchano con UPPER?
WITH reddito AS (SELECT DISTINCT upper(area_statistica) a FROM read_parquet('out/data/clean/reddito_mediano/2026/reddito_mediano_2026_clean.parquet')),
fragilita AS (SELECT DISTINCT upper(area_statistica) a FROM read_parquet('out/data/clean/indici_fragilita/2026/indici_fragilita_2026_clean.parquet')),
esercizi AS (SELECT DISTINCT upper(area_statistica) a FROM read_parquet('out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet'))
SELECT
  (SELECT count(*) FROM reddito r JOIN esercizi e ON r.a = e.a) as reddito_x_esercizi,
  (SELECT count(*) FROM reddito r JOIN fragilita f ON r.a = f.a JOIN esercizi e ON r.a = e.a) as tutti_e_tre;

-- 1. Le correlazioni del blocco (80 aree cross)
WITH reddito AS (
  SELECT upper(area_statistica) as area, reddito_imponibile_mediano
  FROM read_parquet('out/data/clean/reddito_mediano/2026/reddito_mediano_2026_clean.parquet') WHERE anno = 2024
),
fragilita AS (
  SELECT upper(area_statistica) as area, frag_compl
  FROM read_parquet('out/data/clean/indici_fragilita/2026/indici_fragilita_2026_clean.parquet') WHERE anno = 2023 AND aree_escl = 0
),
esercizi AS (
  SELECT upper(area_statistica) as area, count(*) FILTER (WHERE stato='Attivo') as attivi
  FROM read_parquet('out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet')
  WHERE area_statistica IS NOT NULL GROUP BY upper(area_statistica)
)
SELECT count(*) as aree_cross,
       round(corr(reddito_imponibile_mediano, frag_compl), 2) as corr_reddito_fragilita,
       round(corr(reddito_imponibile_mediano, attivi), 2) as corr_reddito_esercizi,
       round(corr(frag_compl, attivi), 2) as corr_fragilita_esercizi
FROM reddito r JOIN fragilita f USING (area) LEFT JOIN esercizi e USING (area);

-- 2. Le 10 aree più fragili: reddito ed esercizi
WITH reddito AS (
  SELECT upper(area_statistica) as area, reddito_imponibile_mediano
  FROM read_parquet('out/data/clean/reddito_mediano/2026/reddito_mediano_2026_clean.parquet') WHERE anno = 2024
),
fragilita AS (
  SELECT upper(area_statistica) as area, frag_compl
  FROM read_parquet('out/data/clean/indici_fragilita/2026/indici_fragilita_2026_clean.parquet') WHERE anno = 2023 AND aree_escl = 0
),
esercizi AS (
  SELECT upper(area_statistica) as area, count(*) FILTER (WHERE stato='Attivo') as attivi
  FROM read_parquet('out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet')
  WHERE area_statistica IS NOT NULL GROUP BY upper(area_statistica)
)
SELECT f.area, frag_compl, reddito_imponibile_mediano, coalesce(attivi,0) as esercizi_attivi
FROM fragilita f JOIN reddito r USING (area) LEFT JOIN esercizi e USING (area)
ORDER BY frag_compl DESC LIMIT 10;

-- 3. Le 10 aree più ricche: fragilità ed esercizi
WITH reddito AS (
  SELECT upper(area_statistica) as area, reddito_imponibile_mediano
  FROM read_parquet('out/data/clean/reddito_mediano/2026/reddito_mediano_2026_clean.parquet') WHERE anno = 2024
),
fragilita AS (
  SELECT upper(area_statistica) as area, frag_compl
  FROM read_parquet('out/data/clean/indici_fragilita/2026/indici_fragilita_2026_clean.parquet') WHERE anno = 2023 AND aree_escl = 0
),
esercizi AS (
  SELECT upper(area_statistica) as area, count(*) FILTER (WHERE stato='Attivo') as attivi
  FROM read_parquet('out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet')
  WHERE area_statistica IS NOT NULL GROUP BY upper(area_statistica)
)
SELECT r.area, reddito_imponibile_mediano, frag_compl, coalesce(attivi,0) as esercizi_attivi
FROM reddito r JOIN fragilita f USING (area) LEFT JOIN esercizi e USING (area)
ORDER BY reddito_imponibile_mediano DESC LIMIT 10;

-- 4. Le 10 aree con più esercizi attivi: reddito e fragilità
WITH reddito AS (
  SELECT upper(area_statistica) as area, reddito_imponibile_mediano
  FROM read_parquet('out/data/clean/reddito_mediano/2026/reddito_mediano_2026_clean.parquet') WHERE anno = 2024
),
fragilita AS (
  SELECT upper(area_statistica) as area, frag_compl
  FROM read_parquet('out/data/clean/indici_fragilita/2026/indici_fragilita_2026_clean.parquet') WHERE anno = 2023 AND aree_escl = 0
),
esercizi AS (
  SELECT upper(area_statistica) as area, count(*) FILTER (WHERE stato='Attivo') as attivi
  FROM read_parquet('out/data/clean/esercizi_somministrazione/2026/esercizi_somministrazione_2026_clean.parquet')
  WHERE area_statistica IS NOT NULL GROUP BY upper(area_statistica)
)
SELECT e.area, attivi, reddito_imponibile_mediano, frag_compl
FROM esercizi e JOIN reddito r USING (area) JOIN fragilita f USING (area)
ORDER BY attivi DESC LIMIT 10;
