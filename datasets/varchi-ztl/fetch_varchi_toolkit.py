#!/usr/bin/env python3
"""
Fetch + merge dei 80 varchi ZTL per la pipeline toolkit (bootstrap).

Scarica i CSV da OpenData Bologna (più veloci dei parquet: 0.84 MB/s vs 0.07 MB/s),
li unisce via DuckDB e produce `varchi_ztl.parquet`.

Uso (dalla candidate root):
  python fetch_varchi_toolkit.py                 # merge da cache
  python fetch_varchi_toolkit.py --fetch         # scarica mancanti + merge
  python fetch_varchi_toolkit.py --cache <dir>   # cache alternativa
  python fetch_varchi_toolkit.py --out <file>    # output alternativo
"""
import os, sys, json, urllib.parse, concurrent.futures
from pathlib import Path
from lab_connectors.duckdb import safe_connect
from lab_connectors.http import download

BASE = Path(__file__).resolve().parent
DEFAULT_CACHE = BASE / "cache"
DEFAULT_OUT = BASE / "varchi_ztl.parquet"

API = "https://opendata.comune.bologna.it/api/explore/v2.1/catalog/datasets"


def list_varchi():
    """Ritorna gli id dei dataset varco-n-* dal catalogo ODS live."""
    url = f"{API}?where=" + urllib.parse.quote('search("varco")') + "&limit=100&select=dataset_id"
    content = download(url, timeout=30, max_retries=2)
    data = json.loads(content)
    return [x["dataset_id"] for x in data["results"] if x["dataset_id"].startswith("varco-n-")]


def fetch_one(varco_id, cache):
    """Scarica un varco in CSV nella cache. Ritorna (id, ok, status)."""
    dest = cache / f"{varco_id}.csv"
    if dest.exists():
        return (varco_id, True, "cached")
    url = f"{API}/{varco_id}/exports/csv"
    try:
        content = download(url, timeout=180, max_retries=3)
        dest.write_bytes(content)
        return (varco_id, True, "downloaded")
    except Exception as e:
        return (varco_id, False, str(e))


def main():
    args = sys.argv[1:]
    cache = DEFAULT_CACHE
    out = DEFAULT_OUT
    do_fetch = "--fetch" in args

    if "--cache" in args:
        cache = Path(args[args.index("--cache") + 1])
    if "--out" in args:
        out = Path(args[args.index("--out") + 1])

    cache.mkdir(parents=True, exist_ok=True)
    varchi = list_varchi()
    print(f"Varchi nel catalogo: {len(varchi)}")

    # Fetch dei mancanti (CSV, non parquet — 12x più veloce)
    missing = [v for v in varchi if not (cache / f"{v}.csv").exists()]
    if do_fetch or missing:
        if missing and not do_fetch:
            print(f"Cache parziale: {len(varchi)-len(missing)}/{len(varchi)} presenti. "
                  f"Scarico i {len(missing)} mancanti...")
        else:
            print(f"Fetch di {len(missing) if do_fetch else 0} varchi mancanti "
                  f"({len(varchi)-len(missing)} già in cache)...")
        ok, err = 0, 0
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as ex:
            futs = {ex.submit(fetch_one, v, cache): v for v in missing}
            for fut in concurrent.futures.as_completed(futs):
                vid, success, status = fut.result()
                if success:
                    ok += 1
                else:
                    err += 1
                    print(f"  ❌ {vid}: {status}")
        print(f"Fetch: {ok} ok, {err} errori")

    # Cache completa?
    files = [cache / f"{v}.csv" for v in varchi if (cache / f"{v}.csv").exists()]
    if len(files) != len(varchi):
        print(f"❌ Cache incompleta: {len(files)}/{len(varchi)} varchi. Esegui --fetch.")
        sys.exit(1)

    # Merge via DuckDB — legge tutti i CSV, estrae lat/lon, dedup, scrive parquet
    files_sql = ", ".join(f"'{f}'" for f in files)
    with safe_connect() as con:
        con.execute(f"""
            CREATE TABLE merged AS
            SELECT
                data, varco, totale_passaggi, non_classificato,
                moto_ciclomotori, auto_furgoni, bus_camion,
                sintatticamente_corretta, lista_bianca_fuori_fascia,
                lista_bianca_regolare, lista_speciale, lista_nera,
                transito_generico_irregolare, segnalazioni,
                nome_varco, descrizione, direzione, tipologia_varco,
                CAST(split_part(coordinate, CHR(44) || CHR(32), 1) AS DOUBLE) AS latitudine,
                CAST(split_part(coordinate, CHR(44) || CHR(32), 2) AS DOUBLE) AS longitudine
            FROM read_csv([{files_sql}], sep=';', auto_detect=true)
        """)
        # Dedup: GROUP BY (data, varco) + max() — vettoriale, nessun window
        con.execute("""
            CREATE OR REPLACE TABLE merged AS
            SELECT data, varco,
                max(nome_varco) nome_varco, max(direzione) direzione,
                max(tipologia_varco) tipologia_varco,
                max(totale_passaggi) totale_passaggi, max(non_classificato) non_classificato,
                max(moto_ciclomotori) moto_ciclomotori, max(auto_furgoni) auto_furgoni,
                max(bus_camion) bus_camion, max(sintatticamente_corretta) sintatticamente_corretta,
                max(lista_bianca_fuori_fascia) lista_bianca_fuori_fascia,
                max(lista_bianca_regolare) lista_bianca_regolare,
                max(lista_speciale) lista_speciale, max(lista_nera) lista_nera,
                max(transito_generico_irregolare) transito_generico_irregolare,
                max(segnalazioni) segnalazioni, max(descrizione) descrizione,
                max(longitudine) longitudine, max(latitudine) latitudine
            FROM merged GROUP BY data, varco
        """)
        con.execute(f"COPY merged TO '{out}' (FORMAT PARQUET)")
        records = con.execute("SELECT count(*) FROM merged").fetchone()[0]
    size_mb = out.stat().st_size / 1024 / 1024
    print(f"✅ Uniti {len(files)} varchi: {records:,} records (dedup), {size_mb:.0f} MB → {out}")


if __name__ == "__main__":
    main()
