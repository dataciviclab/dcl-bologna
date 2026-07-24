#!/usr/bin/env python3
"""
Batch fetch: scarica TUTTI i varchi ZTL in parallelo.
Uso:
  python3 pipeline/fetch_varchi.py              # scarica tutti (lento)
  python3 pipeline/fetch_varchi.py --quick       # scarica solo 5 di test
  python3 pipeline/fetch_varchi.py --status      # quanti già presenti
  python3 pipeline/fetch_varchi.py --merge       # unisce tutti in un unico parquet
"""
import os, sys, json, time, urllib.request, concurrent.futures

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE, "_data")
CATALOG = os.path.join(BASE, "catalogo", "catalog_full.json")

# Carica lista varchi dal catalogo
with open(CATALOG) as f:
    cat = json.load(f)

varchi = [ds for ds in cat["datasets"] if ds["id"].startswith("varco-n-")]
print(f"Varchi totali nel catalogo: {len(varchi)}")

API = "https://opendata.comune.bologna.it/api/explore/v2.1/catalog/datasets"

def fetch_one(varco_id):
    """Scarica un varco in Parquet. Ritorna (id, size, error)."""
    dest = os.path.join(DATA_DIR, f"{varco_id}.parquet")
    if os.path.exists(dest):
        size = os.path.getsize(dest)
        return (varco_id, size, None, "cached")
    
    url = f"{API}/{varco_id}/exports/parquet"
    try:
        req = urllib.request.Request(url, headers={"Accept": "application/octet-stream"})
        with urllib.request.urlopen(req, timeout=120) as resp:
            content = resp.read()
        with open(dest, "wb") as f:
            f.write(content)
        return (varco_id, len(content), None, "downloaded")
    except Exception as e:
        return (varco_id, 0, str(e), "error")


def main():
    args = sys.argv[1:]
    
    if "--status" in args:
        ok = sum(1 for v in varchi if os.path.exists(os.path.join(DATA_DIR, f"{v['id']}.parquet")))
        tot = len(varchi)
        size_mb = sum(os.path.getsize(os.path.join(DATA_DIR, f"{v['id']}.parquet")) for v in varchi if os.path.exists(os.path.join(DATA_DIR, f"{v['id']}.parquet"))) / 1024 / 1024
        print(f"Varchi: {ok}/{tot} presenti ({size_mb:.0f} MB)")
        return
    
    if "--merge" in args:
        print("Unione di tutti i varchi in un unico parquet...")
        import duckdb
        con = duckdb.connect()
        parquet_files = [os.path.join(DATA_DIR, f"{v['id']}.parquet") for v in varchi if os.path.exists(os.path.join(DATA_DIR, f"{v['id']}.parquet"))]
        if not parquet_files:
            print("Nessun varco scaricato. Prima esegui fetch.")
            return
        # Aggiungi colonna varco_id per identificare la provenienza
        # DuckDB supporta read_parquet con lista di file
        files_list = "[" + ", ".join(f"'{p}'" for p in parquet_files) + "]"
        dest = os.path.join(DATA_DIR, "varchi-ztl-all.parquet")
        con.execute(f"CREATE TABLE merged AS SELECT * FROM read_parquet({files_list})")
        con.execute(f"COPY merged TO '{dest}' (FORMAT PARQUET)")
        records = con.execute(f"SELECT count(*) FROM merged").fetchone()[0]
        size = os.path.getsize(dest) / 1024 / 1024
        print(f"✅ Uniti {len(parquet_files)} varchi: {records:,} records, {size:.0f} MB → {dest}")
        return
    
    # Fetch selettivo o completo
    targets = varchi
    if "--quick" in args:
        targets = varchi[:5]
        print(f"Modalità quick: 5 varchi")
    
    os.makedirs(DATA_DIR, exist_ok=True)
    print(f"Scaricamento {len(targets)} varchi con 3 workers paralleli...")
    
    # Determina quali varchi scaricare
    to_fetch = [v["id"] for v in targets if not os.path.exists(os.path.join(DATA_DIR, f"{v['id']}.parquet"))]
    cached = len(targets) - len(to_fetch)
    
    if cached:
        print(f"  Già presenti: {cached}")
    
    if not to_fetch:
        print("  Tutti già scaricati.")
        return
    
    # Download in parallelo (max 3 workers)
    ok = 0
    errors = 0
    total_mb = 0
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        futuros = {executor.submit(fetch_one, vid): vid for vid in to_fetch}
        for i, futuro in enumerate(concurrent.futures.as_completed(futuros)):
            vid = futuros[futuro]
            try:
                _, size, err, status = futuro.result()
                if err:
                    print(f"  [{i+1}/{len(to_fetch)}] ❌ {vid}: {err}")
                    errors += 1
                else:
                    print(f"  [{i+1}/{len(to_fetch)}] ✅ {vid} ({size/1024/1024:.1f} MB)")
                    ok += 1
                    total_mb += size
            except Exception as e:
                print(f"  [{i+1}/{len(to_fetch)}] ❌ {vid}: {e}")
                errors += 1
    
    print(f"\nFatto: {ok} nuovi, {errors} errori, +{total_mb/1024/1024:.0f} MB totali ({cached} già presenti)")


if __name__ == "__main__":
    main()
