-- clean.sql: qualità dell'aria — rilevazioni orarie 2017-2026
--
-- Due raw con schemi diversi nella stessa view (clean.read.mode: "all"):
--   A) centraline-qualita-aria      → id, reftime, stazione, value, agente_atm
--      (anno corrente + coda di fine anno precedente; fonte = 'ods_2026')
--   B) dati-centraline-bologna-storico → cod_staz, agente, data_inizio, valore, um
--      (2017 → 2025-12-30; fonte = 'storico')
--
-- Trasformazioni:
--   1. unione dei due schemi su (reftime, stazione, agente_atm, value)
--      - B ha l'intervallo orario 00:01→01:00: date_trunc('hour', data_inizio)
--        dà l'ora di riferimento, identica a reftime di A
--      - stazione: A ha "NOME, BOLOGNA VIA ..." → tengo il nome (cod_staz in B)
--   2. agente_atm: due vocabolari (C6H6 (BENZENE) / Benzene) → codici corti
--   3. um: B la porta per riga; A non la espone → derivata dai valori
--      (CO è in mg/m³ in entrambe le fonti, tutti gli altri in µg/m³)
--   4. anno derivato da reftime
--   5. dedup su (reftime, stazione, agente_atm): collisioni sull'ora 02:00 del
--      cambio ora legale (valori reali diversi). Preferisco la fonte corrente
--      (ods_2026), poi il valore maggiore.
--   6. scarto le righe senza misura (`valore` NULL): sono 12 ore di PM2.5 a
--      Giardini Margherita, febbraio-aprile 2023 — buco del sensore.
--
-- Chiave: (reftime, stazione, agente_atm) unica dopo dedup.
-- Nota: il campo `um` esiste perché CO non è in µg/m³ — aggregare sostanze
-- diverse senza leggere `um` mescola unità di misura.

WITH raw AS (
    -- A) dataset corrente
    SELECT
        CAST(reftime AS TIMESTAMP) AS reftime,
        normalize_string(SPLIT_PART(stazione, ',', 1)) AS stazione,
        normalize_string(agente_atm) AS agente_raw,
        cast_double(value) AS valore,
        CAST(NULL AS VARCHAR) AS um_raw,
        'ods_2026' AS fonte
    FROM raw_input
    WHERE reftime IS NOT NULL

    UNION ALL

    -- B) storico (intervallo orario → ora di riferimento)
    SELECT
        CAST(date_trunc('hour', CAST(data_inizio AS TIMESTAMP)) AS TIMESTAMP) AS reftime,
        normalize_string(cod_staz) AS stazione,
        normalize_string(agente) AS agente_raw,
        cast_double(valore) AS valore,
        normalize_string(um) AS um_raw,
        'storico' AS fonte
    FROM raw_input
    WHERE data_inizio IS NOT NULL
),
norm AS (
    SELECT
        reftime,
        stazione,
        valore,
        um_raw,
        fonte,
        CASE upper(agente_raw)
            WHEN 'C6H6 (BENZENE)'           THEN 'C6H6'
            WHEN 'BENZENE'                  THEN 'C6H6'
            WHEN 'CO (MONOSSIDO DI CARBONIO)' THEN 'CO'
            WHEN 'NO (MONOSSIDO DI AZOTO)'  THEN 'NO'
            WHEN 'NO2 (BIOSSIDO DI AZOTO)'  THEN 'NO2'
            WHEN 'NOX (OSSIDI DI AZOTO)'    THEN 'NOX'
            WHEN 'O3 (OZONO)'               THEN 'O3'
            ELSE agente_raw
        END AS agente_atm
    FROM raw
)
SELECT
    CAST(EXTRACT(YEAR FROM reftime) AS INTEGER) AS anno,
    reftime,
    stazione,
    agente_atm,
    valore AS value,
    -- Unità canonica per inquinante. CO è in mg/m³: la fonte etichetta
    -- 'ug/m3' 7.583 righe CO del 2025, ma i valori sono sulla stessa scala
    -- mg/m³ di tutte le altre (0,0-2,0) → etichetta della fonte errata,
    -- normalizzata qui. Tutti gli altri inquinanti sono in µg/m³.
    CASE WHEN agente_atm = 'CO' THEN 'mg/m3'
         ELSE COALESCE(um_raw, 'ug/m3')
    END AS um,
    -- Qualità della misura: il canale NOx di Porta San Felice nel 2024 non è
    -- comparabile con gli altri anni. Evidenza (vedi notes.md):
    --   NO2/NOX 0,27-0,42 a set-dic 2024 contro 0,66-0,79 negli stessi mesi
    --   degli altri anni; NO +51% mentre NO2 -63%; rientro nel 2025.
    -- Il difetto è del canale NOx: CO, C6H6 e PM10 della stessa stazione
    -- non mostrano lo stesso salto e restano affidabili.
    NOT (
        stazione = 'PORTA SAN FELICE'
        AND EXTRACT(YEAR FROM reftime) = 2024
        AND agente_atm IN ('NO', 'NO2', 'NOX')
    ) AS misura_affidabile,
    fonte
FROM norm
WHERE valore IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY reftime, stazione, agente_atm
    ORDER BY CASE WHEN fonte = 'ods_2026' THEN 0 ELSE 1 END, value DESC
) = 1
