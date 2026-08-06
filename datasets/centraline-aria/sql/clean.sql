-- clean.sql: qualità dell'aria — rilevazioni orarie da centraline fisse
--
-- Export ODS con rilevazioni orarie per stazione × agente inquinante.
-- Trasformazioni:
--   1. anno derivato da reftime
--   2. dedup su (reftime, stazione, agente_atm): esistono collisioni
--      sull'ora 02:00 del cambio ora legale (9 coppie, valori reali
--      diversi es. 54 vs 57) → tengo il valore maggiore
--   3. stazione pulita (via il suffisso ", BOLOGNA ...")
--   4. typing con le macro standard
--
-- Chiave: (reftime, stazione, agente_atm) unica dopo dedup.

SELECT
    CAST(EXTRACT(YEAR FROM reftime) AS INTEGER) AS anno,
    CAST(reftime AS TIMESTAMP) AS reftime,

    normalize_string(stazione) AS stazione,
    normalize_string(agente_atm) AS agente_atm,
    cast_double(value) AS value

FROM raw_input
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY reftime, stazione, agente_atm
    ORDER BY value DESC
) = 1
