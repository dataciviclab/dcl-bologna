-- clean.sql: precipitazioni giornaliere a Bologna
--
-- Export unico multi-anno (2001-2026). date unica → primary_key.
-- La colonna raw "184_avg_d" (mm di pioggia) viene rinominata
-- in pioggia_mm nel clean.

SELECT
    CAST(date AS DATE) AS date,
    cast_double("184_avg_d") AS pioggia_mm,
    normalize_string(stagione) AS stagione
FROM raw_input
