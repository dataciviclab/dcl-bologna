-- clean.sql: popolazione residente per età, sesso, cittadinanza, quartiere, zona
--
-- Export unico multi-anno (1986-2024). Trasformazioni:
--   1. anno derivato dalla data (il dato è multi-anno, {year} è solo il run year)
--   2. typing: DATE→anno INTEGER, BIGINT→INTEGER dove serve
--   3. normalize_string sulle dimensioni testuali
--
-- Chiave unica verificata: (anno, quartiere, zona, eta_singolo, sesso, cittadinanza).
-- primary_key del clean.

SELECT
    CAST(EXTRACT(YEAR FROM anno) AS INTEGER) AS anno,

    normalize_string(cittadinanza) AS cittadinanza,
    cast_int(eta_singolo)          AS eta_singolo,
    normalize_string(eta_grandi)   AS eta_grandi,
    normalize_string(eta_quinquennali) AS eta_quinquennali,
    normalize_string(quartiere)    AS quartiere,
    normalize_string(zona)         AS zona,
    normalize_string(centro_storico_zone_periferiche) AS centro_storico_zone_periferiche,
    normalize_string(sesso)        AS sesso,

    cast_bigint(residenti) AS residenti

FROM raw_input
