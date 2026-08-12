-- clean.sql: reddito mediano per area statistica (2016-2024)
--
-- Il raw è l'export unico multi-anno dal portale ODS (4 colonne).
-- Trasformazioni:
--   1. anno derivato da anno DATE (multi-anno, {year} è solo il run year)
--   2. typing esplicito con le macro standard
--   3. normalize_string su area_statistica
--   4. alias colonne: il nome raw è lunghissimo
--      (reddito_imponibile_mediano_dei_contribuenti_residenti)
--
-- Chiave verificata: (anno, area_statistica) unica (817=817).
-- Fonte verificata: 0 NULL su reddito e contribuenti.

SELECT
    CAST(EXTRACT(YEAR FROM anno) AS INTEGER) AS anno,
    normalize_string(area_statistica) AS area_statistica,

    cast_bigint(reddito_imponibile_mediano_dei_contribuenti_residenti) AS reddito_imponibile_mediano,
    cast_bigint(numero_contribuenti_residenti) AS numero_contribuenti

FROM raw_input
