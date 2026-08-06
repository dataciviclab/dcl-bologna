-- clean.sql: emigrati secondo la destinazione, per sesso, quartiere e zona
--
-- Export unico multi-anno (1986-2024). anno derivato dalla data.
-- Chiave unica verificata: (anno, destinazione_comuni_regioni, quartiere, zona, sesso).

SELECT
    CAST(EXTRACT(YEAR FROM anno) AS INTEGER) AS anno,
    normalize_string(destinazione_comuni_regioni) AS destinazione_comuni_regioni,
    normalize_string(destinazione_comuni_e_aree_italia) AS destinazione_comuni_e_aree_italia,
    normalize_string(quartiere) AS quartiere,
    normalize_string(zona) AS zona,
    normalize_string(sesso) AS sesso,
    cast_bigint(numero_emigrati) AS numero_emigrati
FROM raw_input
