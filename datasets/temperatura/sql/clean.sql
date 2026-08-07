-- clean.sql: temperature giornaliere a Bologna
--
-- Export unico multi-anno (2001-2026). date unica → primary_key.
-- Typing con le macro standard.

SELECT
    CAST(date AS DATE) AS date,
    cast_double(avg) AS avg,
    cast_double(max) AS max,
    cast_double(min) AS min,
    normalize_string(stagione) AS stagione
FROM raw_input
