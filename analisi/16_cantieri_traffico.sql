-- ============================================================
-- Analisi 16: I cantieri spiegano il calo del traffico?
-- Dataset: lavori-pubblici (+ spire-traffico per il traffico)
--   cantieri: out/data/mart/lavori_pubblici/2026/mart_cantiere_via_mese.parquet
--   clean:    out/data/clean/lavori_pubblici/2026/lavori_pubblici_2026_clean.parquet
--   spire:    out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet
--
-- Domanda: il calo del traffico su alcune arterie è dovuto ai cantieri?
-- Chiude l'ipotesi lasciata aperta in 09 (query 6) e nella discussion #29.
--
-- NOTA METODO:
-- 1. "Cantiere attivo nel mese m" = intervallo [data_inizio, data_fine] che
--    interseca m (dal mart, che espande gli intervalli sui mesi).
-- 2. Il traffico è normalizzato in PASSAGGI/GIORNO per via × mese (la
--    copertura di un mese varia con le spire attive).
-- 3. Il confronto "mesi con cantiere vs mesi senza cantiere" è DESCRITTIVO,
--    non causale: i mesi differiscono per stagionalità e le vie cantierate
--    non sono un controllo casuale. Serve a vedere la direzione, non a
--    stimare un effetto. La query 4 esclude esplicitamente le vie con
--    artefatti di copertura delle spire (crolli/cambi di misura).
-- 4. Copertura del join cantieri↔spire: 230/745 vie cantierate (31%) =
--    230/329 vie misurate dalle spire (70%). Non tutte le vie sono coperte.
-- ============================================================

-- 0. Copertura cantieri: storico + in corso
SELECT origine,
       count(*)                     AS fasi,
       count(DISTINCT id)           AS lavori,
       count(DISTINCT via)          AS vie,
       min(data_inizio)             AS dal,
       max(data_fine)               AS al
FROM read_parquet('out/data/clean/lavori_pubblici/2026/lavori_pubblici_2026_clean.parquet')
GROUP BY origine;

-- 1. Impatto dichiarato (categoria normalizzata)
SELECT impatto_categoria, count(*) AS n
FROM read_parquet('out/data/clean/lavori_pubblici/2026/lavori_pubblici_2026_clean.parquet')
GROUP BY 1 ORDER BY 2 DESC;

-- 2. Le vie più cantierate (per cantieri che impattano la carreggiata)
SELECT via, quartiere, cantieri, cantieri_impatto_carreggiata,
       prima_data_inizio, ultima_data, mesi_con_cantiere
FROM read_parquet('out/data/mart/lavori_pubblici/2026/mart_cantiere_via.parquet')
ORDER BY cantieri_impatto_carreggiata DESC, cantieri DESC
LIMIT 20;

-- 3. Trend città: quanti cantieri attivi e su quante vie, per anno
--    Solo gli anni osservati (2021-2026). Il mart arriva a 2028 perché i
--    lavori IN CORSO dichiarano date di fine future (pianificate): quei mesi
--    non sono attività osservata e restano fuori da questo trend.
SELECT anno,
       count(DISTINCT via)                 AS vie_con_cantiere,
       sum(cantieri_attivi)                AS cantiere_mesi,
       sum(cantieri_impatto_carreggiata)   AS cantiere_mesi_impatto,
       count(DISTINCT mese)                AS mesi_coperti
FROM read_parquet('out/data/mart/lavori_pubblici/2026/mart_cantiere_via_mese.parquet')
WHERE anno BETWEEN 2021 AND 2026
GROUP BY anno ORDER BY anno;

-- 4. Test descrittivo per via: passaggi/giorno nei mesi CON cantiere che
--    impatta la carreggiata vs mesi SENZA.
--
--    GUARD DI COPERTURA (obbligatorio): le spire possono cambiare misura o
--    spegnersi, e un crollo della serie sembrerebbe un "effetto cantiere".
--    Esempio: VIALE DELLA FIERA ha 11.661 passaggi/giorno nel 2022 → 76 nel
--    2024 con le STESSE 2 spire: è un guasto, non un effetto (la query 5
--    mostra i casi esclusi). Per questo si escludono:
--      - vie con mediana/serie che crolla oltre 10× (max/min > 10);
--      - vie minori (< 2.000 passaggi/giorno in uno dei due gruppi) → rumore;
--      - chi ha < 3 mesi per lato.
WITH sm AS (
    SELECT nome_via AS via,
           CAST(strftime(data,'%Y') AS INT) AS anno,
           CAST(strftime(data,'%m') AS INT) AS mese,
           SUM(passaggi) * 1.0 / COUNT(DISTINCT data) AS passaggi_giorno,
           COUNT(DISTINCT id_spira) AS spire
    FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
    GROUP BY 1, 2, 3
),
j AS (
    SELECT sm.via, sm.anno, sm.mese, sm.passaggi_giorno, sm.spire,
           COALESCE(cm.cantieri_impatto_carreggiata, 0) AS impatto
    FROM sm
    LEFT JOIN read_parquet('out/data/mart/lavori_pubblici/2026/mart_cantiere_via_mese.parquet') cm
      ON cm.via = sm.via AND cm.anno = sm.anno AND cm.mese = sm.mese
),
per_via AS (
    SELECT via,
           count(*)                                          AS mesi_totali,
           count(*) FILTER (WHERE impatto > 0)               AS mesi_con_cantiere,
           avg(passaggi_giorno) FILTER (WHERE impatto > 0)   AS media_con,
           avg(passaggi_giorno) FILTER (WHERE impatto = 0)   AS media_senza,
           min(passaggi_giorno)                              AS min_mensile,
           max(passaggi_giorno)                              AS max_mensile,
           max(spire)                                        AS spire
    FROM j GROUP BY via
)
SELECT via, mesi_totali, mesi_con_cantiere, spire,
       round(media_con, 0)   AS passaggi_giorno_con_cantiere,
       round(media_senza, 0) AS passaggi_giorno_senza,
       round((media_con - media_senza) * 100.0 / NULLIF(media_senza, 0), 1) AS diff_pct,
       round(max_mensile * 1.0 / NULLIF(min_mensile, 0), 1) AS salto_copertura
FROM per_via
WHERE mesi_con_cantiere >= 3 AND (mesi_totali - mesi_con_cantiere) >= 3
  AND media_con >= 2000 AND media_senza >= 2000          -- vie minori = rumore
  AND min_mensile > 0 AND max_mensile <= 10 * min_mensile -- crolli di copertura
ORDER BY mesi_con_cantiere DESC, diff_pct
LIMIT 25;

-- 5. Casi ESCLUSI dal test 4 perché la serie delle spire CROLLA (artefatto di
--    copertura): mesi a ~0 passaggi pur con le stesse spire attive.
--    Deve comparire VIALE DELLA FIERA: 11.671 passaggi/giorno nel 2022 → 76
--    nel 2024 → 53 nel 2026 con le stesse 2 spire. È un guasto/cambio di
--    misura, non un effetto dei cantieri.
WITH sm AS (
    SELECT nome_via AS via,
           CAST(strftime(data,'%Y') AS INT) AS anno,
           CAST(strftime(data,'%m') AS INT) AS mese,
           SUM(passaggi) * 1.0 / COUNT(DISTINCT data) AS passaggi_giorno,
           COUNT(DISTINCT id_spira) AS spire
    FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
    GROUP BY 1, 2, 3
),
j AS (
    SELECT sm.via, sm.anno, sm.mese, sm.passaggi_giorno, sm.spire,
           COALESCE(cm.cantieri_impatto_carreggiata, 0) AS impatto
    FROM sm
    LEFT JOIN read_parquet('out/data/mart/lavori_pubblici/2026/mart_cantiere_via_mese.parquet') cm
      ON cm.via = sm.via AND cm.anno = sm.anno AND cm.mese = sm.mese
),
per_via AS (
    SELECT via,
           count(*)                                          AS mesi_totali,
           count(*) FILTER (WHERE impatto > 0)               AS mesi_con_cantiere,
           avg(passaggi_giorno) FILTER (WHERE impatto > 0)   AS media_con,
           avg(passaggi_giorno) FILTER (WHERE impatto = 0)   AS media_senza,
           min(passaggi_giorno)                              AS min_mensile,
           max(passaggi_giorno)                              AS max_mensile,
           count(*) FILTER (WHERE passaggi_giorno < 100)     AS mesi_sotto_100,
           max(spire)                                        AS spire
    FROM j GROUP BY via
)
SELECT via, mesi_con_cantiere, spire,
       round(media_con, 0)   AS passaggi_giorno_con_cantiere,
       round(media_senza, 0) AS passaggi_giorno_senza,
       round(min_mensile, 0) AS min_mensile,
       round(max_mensile, 0) AS max_mensile,
       -- robusto anche quando min_mensile = 0
       round(max_mensile * 1.0 / GREATEST(min_mensile, 1), 0) AS salto_copertura,
       mesi_sotto_100
FROM per_via
WHERE mesi_con_cantiere >= 3 AND (mesi_totali - mesi_con_cantiere) >= 3
  AND (min_mensile <= 0 OR max_mensile > 10 * GREATEST(min_mensile, 1))
ORDER BY salto_copertura DESC
LIMIT 20;

-- 6. Caso verificato: Via Stalingrado, mese per mese (traffico × cantieri)
WITH sm AS (
    SELECT nome_via AS via,
           CAST(strftime(data,'%Y') AS INT) AS anno,
           CAST(strftime(data,'%m') AS INT) AS mese,
           SUM(passaggi) * 1.0 / COUNT(DISTINCT data) AS passaggi_giorno
    FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
    GROUP BY 1, 2, 3
)
SELECT sm.anno, sm.mese,
       round(sm.passaggi_giorno, 0)                            AS passaggi_giorno,
       COALESCE(cm.cantieri_attivi, 0)                         AS cantieri_attivi,
       COALESCE(cm.cantieri_chiusura, 0)                       AS chiusura,
       COALESCE(cm.cantieri_restringimento, 0)                 AS restringimento
FROM sm
LEFT JOIN read_parquet('out/data/mart/lavori_pubblici/2026/mart_cantiere_via_mese.parquet') cm
  ON cm.via = sm.via AND cm.anno = sm.anno AND cm.mese = sm.mese
WHERE sm.via = 'VIA STALINGRADO' AND sm.anno >= 2023 AND sm.mese IN (1, 3, 6, 8, 10, 12)
ORDER BY sm.anno, sm.mese;
