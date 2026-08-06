-- clean.sql: spire flusso veicoli — wide (24 fasce orarie) → long (1 riga/fascia)
--
-- Il raw è il parquet esportato da OpenData Bologna:
--   data, codice_spira, 24 colonne "00_00_01_00".."23_00_24_00" (passaggi/fascia),
--   id_uni (spira stabile), nome_via, livello, coordinate, ecc.
--
-- Trasformazioni:
--   1. UNPIVOT delle 24 colonne orarie in fascia_oraria + passaggi
--   2. fascia_oraria "00_00_01_00" → label leggibile "00:00-01:00" + ora_inizio INT
--   3. anno da {year} (il toolkit sostituisce l'anno del run)
--   4. typing: int/double con le macro standard
--
-- Chiave spira stabile: id_uni (1 nome_via + 1 coppia lat/lon ciascuna, verificato).
-- primary_key del clean: (data, id_uni, livello, fascia_oraria) — unico verificato.

WITH wide AS (
    SELECT *
    FROM raw_input
    UNPIVOT (
        passaggi FOR fascia_oraria IN (
            "00_00_01_00", "01_00_02_00", "02_00_03_00", "03_00_04_00",
            "04_00_05_00", "05_00_06_00", "06_00_07_00", "07_00_08_00",
            "08_00_09_00", "09_00_10_00", "10_00_11_00", "11_00_12_00",
            "12_00_13_00", "13_00_14_00", "14_00_15_00", "15_00_16_00",
            "16_00_17_00", "17_00_18_00", "18_00_19_00", "19_00_20_00",
            "20_00_21_00", "21_00_22_00", "22_00_23_00", "23_00_24_00"
        )
    )
)
SELECT
    CAST({year} AS INTEGER) AS anno,
    CAST(data AS DATE)     AS data,

    CAST(id_uni AS BIGINT) AS id_uni,
    CAST(chiave AS BIGINT) AS chiave,
    normalize_string(nome_via)   AS nome_via,
    normalize_string(tipologia)  AS tipologia,
    normalize_string(direzione)  AS direzione,
    normalize_string(num_giorno_settimana) AS giorno_settimana,
    CAST(livello AS INTEGER) AS livello,
    cast_int(codice_via) AS codice_via,

    -- fascia oraria: "00_00_01_00" → label "00:00-01:00" + ora di inizio
    replace(
        concat(substr(fascia_oraria, 1, 5), '-', substr(fascia_oraria, 7, 5)),
        '_', ':'
    ) AS fascia_oraria,
    CAST(substr(fascia_oraria, 1, 2) AS INTEGER) AS ora_inizio,

    CAST(passaggi AS BIGINT) AS passaggi,

    CAST(longitudine AS DOUBLE) AS longitudine,
    CAST(latitudine  AS DOUBLE) AS latitudine

FROM wide
WHERE nome_via IS NOT NULL AND nome_via <> ''
