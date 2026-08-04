#!/usr/bin/env python3
"""
Fetch: scarica dataset Bologna in formato Parquet.
Uso:
  python3 pipeline/fetch.py                      # scarica tutti i dataset
  python3 pipeline/fetch.py popolazione-quartiere # scarica uno specifico
  python3 pipeline/fetch.py --list               # lista dataset disponibili
  python3 pipeline/fetch.py --info popolazione-quartiere # info senza scaricare
"""
import os, sys, time, json, urllib.request, urllib.error

# Aggiungi _local/explore/bologna al path
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE)
from pipeline.config import load_config, export_url, data_path, list_datasets


def fetch(dataset_id, force=False):
    """Scarica un dataset in Parquet."""
    config = load_config(dataset_id)

    # Dataset con fetch dedicato (es. varchi-ztl → fetch_varchi.py):
    # il fetch generico non può scaricarli, li skippa con istruzione chiara.
    src = config["source"]
    if src.get("fetch") == "dedicated":
        script = src.get("fetch_script", "?")
        print(f"⏭️  {dataset_id}: fetch dedicato ({script}) — usa quello, non il generico")
        return None

    url = export_url(config)
    dest = data_path(dataset_id, config["source"].get("export_format", "parquet"))
    
    ds_info = config["dataset"]
    print(f"\n📁 {ds_info['title']}")
    print(f"   ID: {dataset_id}")
    print(f"   URL: {url}")
    print(f"   Dest: {dest}")
    
    if os.path.exists(dest) and not force:
        size_mb = os.path.getsize(dest) / 1024 / 1024
        print(f"   ✅ Già presente ({size_mb:.1f} MB). Usa --force per riscaricare.")
        return dest
    
    print(f"   ⬇️ Download in corso...", end=" ", flush=True)
    t0 = time.time()
    try:
        req = urllib.request.Request(url, headers={"Accept": "application/octet-stream"})
        with urllib.request.urlopen(req, timeout=300) as resp:
            content = resp.read()
    except urllib.error.HTTPError as e:
        print(f"❌ HTTP {e.code}: {e.reason}")
        return None
    
    with open(dest, "wb") as f:
        f.write(content)
    
    t1 = time.time()
    mb = len(content) / 1024 / 1024
    print(f"✅ {mb:.1f} MB in {t1-t0:.1f}s ({mb/(t1-t0):.1f} MB/s)")
    
    # Validazione minima: è un Parquet valido?
    if content[:4] == b'PAR1':
        print(f"   ✅ Formato Parquet confermato")
    else:
        print(f"   ⚠️ Magic number: {content[:4]} (non PAR1 — forse non è Parquet)")
    
    # Mostra info schema (contratto condiviso: pipeline/parquet.py)
    try:
        from pipeline.parquet import inspect_parquet
        columns, records = inspect_parquet(dest)
        print(f"   📊 {records:,} records × {len(columns)} colonne")
        for name, typ in columns[:5]:
            print(f"      {name:30s} {typ}")
        if len(columns) > 5:
            print(f"      ... e altre {len(columns)-5} colonne")
    except Exception as e:
        print(f"   ⚠️ Errore validazione DuckDB: {e}")
    
    return dest


def info(dataset_id):
    """Mostra info su un dataset senza scaricarlo."""
    config = load_config(dataset_id)
    ds = config["dataset"]
    src = config["source"]
    cov = config.get("coverage", {})
    sch = config.get("schema", {})
    
    print(f"\n📁 {ds['title']}")
    print(f"   ID: {dataset_id}")
    print(f"   Fonte: {src['base_url']}")
    print(f"   Dataset ID API: {src['dataset_id']}")
    print(f"   Export: {src['export_format']}")
    print(f"   Copertura: {cov.get('years','?')} — {cov.get('records','?')} records")
    print(f"   Granularità: {cov.get('granularity','?')}")
    print(f"   Frequenza: {config.get('schedule',{}).get('frequency','?')}")
    
    path = data_path(dataset_id, src.get("export_format", "parquet"))
    if os.path.exists(path):
        size = os.path.getsize(path) / 1024 / 1024
        print(f"   Scaricato: {size:.1f} MB")
    else:
        print(f"   ❌ Non ancora scaricato")
    
    cols = sch.get("columns", [])
    if cols:
        print(f"   Schema ({len(cols)} colonne):")
        for c in cols:
            print(f"      {c['name']:30s} {c['type']:8s}  {c.get('description','')}")


def main():
    args = sys.argv[1:]
    
    if "--list" in args:
        print("Dataset disponibili:")
        for ds in list_datasets():
            path = data_path(ds, "parquet")
            status = "✅" if os.path.exists(path) else "⬜"
            print(f"   {status} {ds}")
        return
    
    if "--info" in args:
        idx = args.index("--info")
        for ds_id in args[idx+1:]:
            info(ds_id)
        return
    
    if not args:
        datasets = list_datasets()
        print(f"🎯 Fetch Bologna — {len(datasets)} dataset configurati")
        for ds_id in datasets:
            try:
                fetch(ds_id)
            except Exception as e:
                print(f"   ❌ {ds_id}: {e}")
        return
    
    for ds_id in args:
        if ds_id.startswith("--"):
            continue
        try:
            fetch(ds_id, force="--force" in args)
        except Exception as e:
            print(f"   ❌ {ds_id}: {e}")


if __name__ == "__main__":
    main()
