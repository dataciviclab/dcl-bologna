-- clean.sql: bolognawifi matrice spostamenti — flussi pedonali tra zone WiFi
--
-- Il raw è l'export unico multi-anno (2021-2025) dal portale ODS.
-- Trasformazioni:
--   1. anno derivato da data (multi-anno, {year} è solo il run year)
--   2. typing esplicito con le macro standard
--   3. normalize_string sulle dimensioni testuali
--   4. giorno: la fonte lo espone come "1-Lunedì" → estraggo il numero
--      (giorno_num, 1=Lunedì..7=Domenica) e la label (giorno_label)
--
-- Chiave unica verificata: (data, ora, id_origine, id_destinazione).
-- Fonte verificata: 0 NULL su totale/percentile_50/id, 0 zeri.

SELECT
    CAST(EXTRACT(YEAR FROM data) AS INTEGER) AS anno,
    CAST(data AS DATE) AS data,
    cast_int(ora) AS ora,

    -- giorno "1-Lunedì" → numero (INTEGER) + label (VARCHAR)
    cast_int(split_part(giorno, '-', 1)) AS giorno_num,
    normalize_string(split_part(giorno, '-', 2)) AS giorno_label,

    normalize_string(id_origine)       AS id_origine,
    normalize_string(label_origine)    AS label_origine,
    normalize_string(id_destinazione)  AS id_destinazione,
    normalize_string(label_destinazione) AS label_destinazione,

    cast_bigint(totale)       AS totale,
    cast_bigint(percentile_50) AS percentile_50

FROM raw_input
