-- ============================================================
-- Analisi 11: Il reddito a Bologna per area — 2016-2024
-- Dataset: reddito-mediano (817 righe, 91 aree, serie 2016-2024)
-- Path: out/data/clean/reddito_mediano/2024/reddito_mediano_2024_clean.parquet
--
-- Domanda: dove si concentra il reddito a Bologna e come è cambiato?
--
-- NOTA METODO:
-- 1. Valori in EURO CORRENTI (non corretti per inflazione) → "crescita
--    nominale". Dichiarare se si confrontano anni.
-- 2. Aree minuscole (<500 contribuenti) distorcono il ranking: i
--    confronti top/bottom usano aree con >= 1000 contribuenti.
-- 3. Variazione di reddito ≠ impoverimento: leggere SEMPRE insieme a
--    numero_contribuenti (ricambio demografico vs declino).
-- ============================================================

-- 0. Verifica copertura: anni, aree, contribuenti
SELECT anno, count(*) as aree, sum(numero_contribuenti) as contribuenti
FROM read_parquet('out/data/clean/reddito_mediano/2024/reddito_mediano_2024_clean.parquet')
GROUP BY anno ORDER BY anno;

-- 1. Trend comunale: reddito mediano medio e contribuenti (2016-2024)
SELECT anno,
       round(avg(reddito_imponibile_mediano), 0) as reddito_medio,
       sum(numero_contribuenti) as contribuenti
FROM read_parquet('out/data/clean/reddito_mediano/2024/reddito_mediano_2024_clean.parquet')
GROUP BY anno ORDER BY anno;

-- 2. TOP aree 2024 (>= 1000 contribuenti) — dove sta il reddito
SELECT area_statistica, reddito_imponibile_mediano, numero_contribuenti
FROM read_parquet('out/data/clean/reddito_mediano/2024/reddito_mediano_2024_clean.parquet')
WHERE anno = 2024 AND numero_contribuenti >= 1000
ORDER BY reddito_imponibile_mediano DESC LIMIT 6;

-- 3. BOTTOM aree 2024 (>= 1000 contribuenti)
SELECT area_statistica, reddito_imponibile_mediano, numero_contribuenti
FROM read_parquet('out/data/clean/reddito_mediano/2024/reddito_mediano_2024_clean.parquet')
WHERE anno = 2024 AND numero_contribuenti >= 1000
ORDER BY reddito_imponibile_mediano LIMIT 6;

-- 4. Il divario: rapporto max/min tra aree significative (>= 500), 2016 vs 2024
WITH per_area AS (
    SELECT area_statistica,
           max(reddito_imponibile_mediano) FILTER (WHERE anno=2016) as r2016,
           max(reddito_imponibile_mediano) FILTER (WHERE anno=2024) as r2024,
           max(numero_contribuenti) FILTER (WHERE anno=2016) as c16,
           max(numero_contribuenti) FILTER (WHERE anno=2024) as c24
    FROM read_parquet('out/data/clean/reddito_mediano/2024/reddito_mediano_2024_clean.parquet')
    GROUP BY area_statistica
)
SELECT round(max(r2024) * 1.0 / min(r2024), 1) as rapporto_2024
FROM per_area WHERE r2024 IS NOT NULL AND c24 >= 500;

-- 5. Dove il reddito è CALATO di più (2016→2024, aree con >= 500 contribuenti 2024)
WITH per_area AS (
    SELECT area_statistica,
           max(reddito_imponibile_mediano) FILTER (WHERE anno=2016) as r2016,
           max(reddito_imponibile_mediano) FILTER (WHERE anno=2024) as r2024,
           max(numero_contribuenti) FILTER (WHERE anno=2024) as c2024
    FROM read_parquet('out/data/clean/reddito_mediano/2024/reddito_mediano_2024_clean.parquet')
    GROUP BY area_statistica
)
SELECT area_statistica, r2016, r2024,
       round((r2024 - r2016) * 100.0 / r2016, 1) as crescita_pct,
       c2024
FROM per_area
WHERE r2016 IS NOT NULL AND r2024 IS NOT NULL AND c2024 >= 500
ORDER BY crescita_pct LIMIT 5;

-- 6. Dove il reddito è CRESCIUTO di più (2016→2024)
WITH per_area AS (
    SELECT area_statistica,
           max(reddito_imponibile_mediano) FILTER (WHERE anno=2016) as r2016,
           max(reddito_imponibile_mediano) FILTER (WHERE anno=2024) as r2024,
           max(numero_contribuenti) FILTER (WHERE anno=2024) as c2024
    FROM read_parquet('out/data/clean/reddito_mediano/2024/reddito_mediano_2024_clean.parquet')
    GROUP BY area_statistica
)
SELECT area_statistica, r2016, r2024,
       round((r2024 - r2016) * 100.0 / r2016, 1) as crescita_pct
FROM per_area
WHERE r2016 IS NOT NULL AND r2024 IS NOT NULL AND c2024 >= 500
ORDER BY crescita_pct DESC LIMIT 5;
