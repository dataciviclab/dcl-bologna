# Come lavorare su dcl-bologna

## Aggiungere un nuovo dataset

```bash
# 1. Crea dataset/nome.yml (copia da uno esistente, modifica)
#    source.dataset_id = nome API del dataset su opendata.comune.bologna.it
#    source.export_format = parquet (sempre — è il formato nativo)

# 2. Scarica
make fetch/nome-dataset

# 3. Verifica
make status                  # deve comparire come pronto
python3 pipeline/query.py nome-dataset "SELECT count(*) FROM data"

# 4. Esplora schema e prime righe
python3 pipeline/query.py nome-dataset "DESCRIBE SELECT * FROM data"
python3 pipeline/query.py nome-dataset "SELECT * FROM data LIMIT 5"

# 5. Aggiorna README (tabella dataset attivi + stato)
```

## Fare un'analisi

```bash
# 1. Crea analisi/XX_nome.sql con:
#    - header con descrizione e dataset necessari
#    - query 0: verifica copertura (date, records)
#    - query 1..N: analisi
#    - ogni query deve funzionare in DuckDB direttamente

# 2. Esegui l'analisi
python3 pipeline/query.py dataset1 "SELECT * FROM data LIMIT 10"

# Per analisi multi-dataset:
python3 -c "
import duckdb
con = duckdb.connect()
con.execute('SELECT * FROM read_parquet(\"_data/ds1.parquet\") a
             JOIN read_parquet(\"_data/ds2.parquet\") b ON a.data = b.data
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
- `make status` — verifica che i dataset pronti siano quelli giusti
- Controlla che `_data/` e `.tmp/` non siano in git (`git status`)
- Il commit deve essere stabile: chi clona deve poter fare `make fetch && make status` e vedere tutto funzionare

## Principi

- **I dati in _data/ non vanno in git.** Sono rigenerabili con `make fetch`. Il repo contiene solo codice e configurazioni.
- **Un dataset = un file YAML.** Niente di più. Lo YAML dice dove sta il dato, come si chiama, che colonne ha.
- **Le analisi in SQL**, non in Python. Python solo per orchestrazione (fetch) e visualizzazione. L'analisi deve essere riproducibile.
- **Se un dato non è verificabile, non esiste.** Ogni numero nel README deve avere una query alle spalle.
- **Prima di aggiungere un dataset, controlla se si incrocia con uno già presente.** Se no, probabilmente non serve.
