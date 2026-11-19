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
--    stimare un effetto.
-- 4. Il join cantieri↔spire copre solo le vie misurate dalle spire (~29%).
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
--    impatta la carreggiata vs mesi SENZA (vie con almeno 3 mesi per lato).
WITH sm AS (
    SELECT nome_via AS via,
           CAST(strftime(data,'%Y') AS INT) AS anno,
           CAST(strftime(data,'%m') AS INT) AS mese,
           SUM(passaggi) * 1.0 / COUNT(DISTINCT data) AS passaggi_giorno
    FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
    GROUP BY 1, 2, 3
),
j AS (
    SELECT sm.via, sm.anno, sm.mese, sm.passaggi_giorno,
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
           avg(passaggi_giorno) FILTER (WHERE impatto = 0)   AS media_senza
    FROM j GROUP BY via
)
SELECT via, mesi_totali, mesi_con_cantiere,
       round(media_con, 0)   AS passaggi_giorno_con_cantiere,
       round(media_senza, 0) AS passaggi_giorno_senza,
       round((media_con - media_senza) * 100.0 / NULLIF(media_senza, 0), 1) AS diff_pct
FROM per_via
WHERE mesi_con_cantiere >= 3 AND (mesi_totali - mesi_con_cantiere) >= 3
ORDER BY mesi_con_cantiere DESC, diff_pct
LIMIT 25;

-- 5. Caso verificato: Via Stalingrado, mese per mese (traffico × cantieri)
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
