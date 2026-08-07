# Come lavorare su dcl-bologna

## Aggiungere un nuovo dataset

I dataset vivono in `datasets/<slug>/` con lo **standard candidate del Lab**
(raw → clean → mart via [toolkit](https://github.com/dataciviclab/toolkit)). Riferimento:
[docs/candidate-standard.md](https://github.com/dataciviclab/dataset-incubator/blob/main/docs/candidate-standard.md).

```bash
# 1. Crea datasets/<slug>/ con:
#    - dataset.yml      → nome, years, source_id, tags, category, raw/clean/mart
#    - sql/clean.sql    → SELECT ... FROM raw_input (typing, {year}, macro standard)
#    - sql/mart_*.sql   → aggregazioni (SELECT ... FROM clean_input)
#    - README.md + notes.md

# 2. Esegui la pipeline
toolkit run --config datasets/<slug>/dataset.yml
#    target: status: passed, readiness: ready (8/8)

# 3. Verifica schema e dati
toolkit inspect config --config datasets/<slug>/dataset.yml

# 4. Aggiorna README.md (tabella dataset)
```

Per le convenzioni del toolkit (source types, macro, placeholder `{year}`, mart multi-anno):
`toolkit contract --layer all` prima di scrivere.

## Fare un'analisi

```bash
# 1. Crea analisi/XX_nome.sql con:
#    - header con descrizione e dataset necessari
#    - query 0: verifica copertura (date, records)
#    - query 1..N: analisi
#    - ogni query deve funzionare in DuckDB direttamente

# 2. Esegui l'analisi sui parquet clean (out/data/clean/<slug>/<anno>/)
python3 -c "
import duckdb
con = duckdb.connect()
con.execute('SELECT * FROM read_parquet(\"out/data/clean/ds/2026/ds_2026_clean.parquet\") a
             JOIN read_parquet(\"out/data/clean/ds2/2026/ds2_2026_clean.parquet\") b ON a.data = b.data
             LIMIT 10').fetchdf()
"

# 3. Se emergono numeri interessanti, aggiorna README o Discussion
```

## Commit e push

```bash
git add -A
git commit -m "tipo: messaggio"

# tipi: feat (nuovo dataset/analisi), fix (correzione),
#       docs (README, discussioni), chore (manutenzione)
```

Prima di pushare:
- `make status/<slug>` — readiness del dataset
- Controlla che `out/`, `datasets/*/cache/` e i parquet candidate non siano in git (`git status`)
- Il commit deve essere stabile: chi clona deve poter fare `toolkit run` e vedere tutto funzionare

## Principi

- **I dati in `out/` e nelle cache (`datasets/*/cache/`) non vanno in git.** Sono rigenerabili con il toolkit. Il repo contiene solo codice e configurazioni.
- **Un dataset = una cartella `datasets/<slug>/`.** Config + SQL di pulizia + mart. Niente pipeline custom.
- **Le analisi in SQL**, non in Python. Python solo per orchestrazione (script di bootstrap, es. varchi) e visualizzazione. L'analisi deve essere riproducibile.
- **Se un dato non è verificabile, non esiste.** Ogni numero nel README deve avere una query alle spalle.
- **Prima di aggiungere un dataset, controlla se si incrocia con uno già presente.** Se no, probabilmente non serve.
