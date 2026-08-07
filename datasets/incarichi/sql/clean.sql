-- clean.sql: incarichi di collaborazione e consulenza del Comune di Bologna
--
-- Export unico multi-anno (2012-2026), update weekly. anno derivato
-- da anno_pg_atto (DATE). id unico → primary_key.
--
-- Nota: importo_euro può avere valori 0 (non è un errore, sono incarichi
-- senza corrispettivo dichiarato); si normalizza solo la stringa, non il valore.

SELECT
    cast_bigint(id) AS id,

    CAST(EXTRACT(YEAR FROM anno_pg_atto) AS INTEGER) AS anno,
    CAST(anno_pg_atto AS DATE) AS anno_pg_atto,
    CAST(durata_dal AS DATE) AS durata_dal,
    CAST(durata_al AS DATE) AS durata_al,

    normalize_string(oggetto) AS oggetto,
    normalize_string(classificazione_incarichi) AS classificazione_incarichi,
    normalize_string(descrizione_classificazione_incarichi) AS descrizione_classificazione_incarichi,
    normalize_string(norma_o_titolo_a_base_dell_attribuzione) AS norma_o_titolo_a_base_dell_attribuzione,

    cast_double(importo_euro) AS importo_euro,
    cast_int(n_pg_atto) AS n_pg_atto,

    normalize_string(settore_dipartimento_area) AS settore_dipartimento_area,
    normalize_string(servizio) AS servizio,
    normalize_string(uo) AS uo,
    normalize_string(dirigente) AS dirigente,
    normalize_string(responsabile) AS responsabile,

    normalize_string(ragione_sociale) AS ragione_sociale,
    normalize_string(partita_iva) AS partita_iva,
    normalize_string(codice_fiscale) AS codice_fiscale,
    normalize_string(curriculum_link) AS curriculum_link

FROM raw_input
