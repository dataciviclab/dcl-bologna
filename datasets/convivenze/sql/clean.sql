-- clean.sql: popolazione residente in istituti di convivenza
--
-- Export unico multi-anno (1986-2024). anno derivato dalla data.
-- Chiave unica verificata: (anno, quartiere, zona, cittadinanza,
-- dimensione, eta_singolo, sesso).

SELECT
    CAST(EXTRACT(YEAR FROM anno) AS INTEGER) AS anno,
    normalize_string(quartiere) AS quartiere,
    normalize_string(zona) AS zona,
    normalize_string(centro_storico_zone_periferiche) AS centro_storico_zone_periferiche,
    normalize_string(cittadinanza) AS cittadinanza,
    normalize_string(dimensione) AS dimensione,
    normalize_string(eta_quinquennali) AS eta_quinquennali,
    normalize_string(eta_grandi) AS eta_grandi,
    cast_int(eta_singolo) AS eta_singolo,
    normalize_string(sesso) AS sesso,
    cast_bigint(residenti) AS residenti
FROM raw_input
