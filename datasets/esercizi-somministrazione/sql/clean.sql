-- clean.sql: esercizi di somministrazione (bar/ristoranti) — tessuto commerciale
--
-- Il raw è l'export unico dal portale ODS (SUAP/Commercio). Trasformazioni:
--   1. typing esplicito con le macro standard
--   2. normalize_string sulle dimensioni testuali
--   3. dedup per chiave (via, civico, tipologia, inizio, stato) con GROUP BY:
--      ~726 righe duplicate (3,9%) con stessa chiave — guardia riproducibile
--      (lezione varchi-ztl: GROUP BY, non ROW_NUMBER)
--
-- Chiave: (esercizio_via, civico, tipologia_esercizio, data_inizio_attivita, stato).
-- Stato: Attivo / Cessato / Sospeso / Diniegato (verificato).
-- Nota: geopoint (BLOB) non serve — lat/lon già presenti.
-- Nota (fix review): sottoarea (natura giuridica: pubblico/deroga/riservata) e
-- attivita_secondaria (offerta accessoria: radio, videogiochi, mense) sono
-- informazione preservata nel clean — NON droppate. area (1 valore costante) e
-- attivita_prevalente (0 valori) escluse: zero informazione.

SELECT
    max(normalize_string(stato)) AS stato,
    max(normalize_string(quartiere)) AS quartiere,
    max(normalize_string(zona)) AS zona,
    max(normalize_string(area_statistica)) AS area_statistica,
    max(normalize_string(centro_storico)) AS centro_storico,
    max(normalize_string(settore)) AS settore,
    max(normalize_string(sottoarea)) AS sottoarea,
    max(normalize_string(tipologia_esercizio)) AS tipologia_esercizio,
    normalize_string(esercizio_via) AS esercizio_via,
    normalize_string(civico) AS civico,
    max(normalize_string(bottega_storica)) AS bottega_storica,
    max(normalize_string(inserito_in_centro_commercale)) AS inserito_in_centro_commercale,
    max(normalize_string(attivita_secondaria_esercizio)) AS attivita_secondaria,

    CAST(max(data_inizio_attivita) AS DATE) AS data_inizio_attivita,
    CAST(max(data_cessazione_attivita) AS DATE) AS data_cessazione_attivita,

    max(cast_double(latitudine)) AS latitudine,
    max(cast_double(longitudine)) AS longitudine

FROM raw_input
-- 3 record completamente vuoti nella fonte (stato='non definita', no via/geo):
-- esclusi — non contengono alcun dato utilizzabile (documentato in notes.md)
WHERE esercizio_via IS NOT NULL AND esercizio_via <> ''
GROUP BY esercizio_via, civico, tipologia_esercizio, data_inizio_attivita, stato
