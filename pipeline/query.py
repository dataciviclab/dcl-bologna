#!/usr/bin/env python3
"""
Query: interroga i dataset Bologna scaricati.
Uso:
  python3 pipeline/query.py popolazione-quartiere "SELECT * FROM data LIMIT 5"
  python3 pipeline/query.py --list                      # lista dataset + path
  python3 pipeline/query.py --datasets popolazione-quartiere,varco-ztl-44 "SELECT * FROM data JOIN ..."
  
Il dataset viene aliasato come 'data' nelle query.
Usa DuckDB, output in formato tabellare (o --json, --csv).
"""
import sys, os, json, duckdb

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE)
from pipeline.config import load_config, data_path, list_datasets

def get_path(dataset_id):
    config = load_config(dataset_id)
    fmt = config["source"].get("export_format", "parquet")
    return data_path(dataset_id, fmt)

def main():
    args = sys.argv[1:]
    
    if not args or "--help" in args:
        print(__doc__)
        return
    
    if "--list" in args:
        print("Dataset Bologna disponibili:")
        for ds in list_datasets():
            p = get_path(ds)
            ok = "✅" if os.path.exists(p) else "⬜"
            size = f" ({os.path.getsize(p)/1024/1024:.1f} MB)" if os.path.exists(p) else ""
            print(f"   {ok} {ds:40s} {p}{size}")
        return
    
    # Determina dataset e SQL
    datasets = []
    sql_parts = []
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--datasets":
            # --datasets ds1,ds2,ds3
            i += 1
            if i < len(args):
                datasets = args[i].split(",")
            i += 1
            # Tutto ciò che resta è SQL
            sql_parts = args[i:]
            break
        i += 1
    
    if not datasets:
        # Modalità standard: primo argomento è il dataset, resto SQL
        datasets = [args[0]]
        sql_parts = args[1:]
    
    sql = " ".join(sql_parts)
    
    if not datasets or not sql:
        print("Specifica dataset e SQL")
        print(__doc__)
        return
    
    # Costruisce la clausola FROM / CTE
    if len(datasets) == 1:
        path = get_path(datasets[0])
        if not os.path.exists(path):
            print(f"❌ Dataset '{datasets[0]}' non scaricato. Usa pipeline/fetch.py prima.")
            return
        # Dataset singolo: alias 'data' per compatibilità
        full_sql = sql.replace("data", f"read_parquet('{path}')", 1) if "data" in sql else sql
    else:
        # Multi-dataset: genera WITH (CTE) con alias d0, d1, ...
        for i, ds in enumerate(datasets):
            p = get_path(ds)
            if not os.path.exists(p):
                print(f"❌ Dataset '{ds}' non scaricato. Usa pipeline/fetch.py prima.")
                return
        cte_defs = ", ".join(
            f"d{i} AS (SELECT * FROM read_parquet('{get_path(d)}'))"
            for i, d in enumerate(datasets)
        )
        full_sql = f"WITH {cte_defs}\n{sql}"
    
    con = duckdb.connect()
    try:
        if "--json" in args:
            result = con.execute(full_sql).fetchdf()
            print(result.to_json(orient="records", force_ascii=False))
        elif "--csv" in args:
            result = con.execute(full_sql).fetchdf()
            print(result.to_csv(index=False))
        else:
            result = con.execute(full_sql).fetchdf()
            print(result.to_string())
    except Exception as e:
        print(f"❌ Errore SQL: {e}")
        print(f"   Query: {full_sql[:200]}")

if __name__ == "__main__":
    main()
