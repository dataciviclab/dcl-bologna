-- clean.sql: famiglie residenti per età, tipologia e cittadinanza del capofamiglia
--
-- Export unico multi-anno (1986-2024). anno derivato dalla data.
-- Chiave unica verificata: (anno, quartiere, zona, eta, tipo_capofamiglia,
-- sesso, cittadinanza_del_capofamiglia).

SELECT
    CAST(EXTRACT(YEAR FROM anno) AS INTEGER) AS anno,
    normalize_string(quartiere) AS quartiere,
    normalize_string(zona) AS zona,
    normalize_string(eta) AS eta,
    normalize_string(tipo_capofamiglia) AS tipo_capofamiglia,
    normalize_string(sesso) AS sesso,
    normalize_string(cittadinanza_del_capofamiglia) AS cittadinanza_del_capofamiglia,
    cast_bigint(numero_famiglie) AS numero_famiglie
FROM raw_input
