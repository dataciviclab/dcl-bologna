#!/usr/bin/env python3
"""
Strumento per consultare il catalogo Bologna in locale.
Uso:
  python3 query_catalog.py                      # panoramica
  python3 query_catalog.py list                  # lista tutti i dataset
  python3 query_catalog.py search <testo>        # cerca per titolo/id
  python3 query_catalog.py theme <tema>          # filtra per tema
  python3 query_catalog.py publisher <nome>      # filtra per publisher
  python3 query_catalog.py geo                   # solo dataset geografici
  python3 query_catalog.py timeserie             # solo serie storiche
  python3 query_catalog.py records <min>         # dataset con >= N records
  python3 query_catalog.py show <id>             # dettaglio dataset
"""

import json, os, sys, textwrap

CATALOG = os.path.join(os.path.dirname(__file__), "catalog_full.json")

with open(CATALOG) as f:
    DATA = json.load(f)

DATASETS = DATA["datasets"]

def print_ds(ds, verbose=False):
    theme = ", ".join(ds.get("theme", [])) if ds["theme"] else "—"
    freq = ""
    if ds["accrualperiodicity"]:
        freq = ds["accrualperiodicity"].split("/")[-1]
    print(f"\n  📁 {ds['id']}")
    print(f"     Titolo: {ds['title'][:100]}")
    if verbose:
        desc = ds.get("description", "")
        desc_plain = desc.replace("<p>","").replace("</p>","").replace("<br>","")[:300]
        if desc_plain:
            print(f"     Descrizione: {desc_plain}")
    print(f"     Records: {ds['records_count']:>8}  |  Tema: {theme}")
    print(f"     Licenza: {ds['license']}  |  Agg.: {freq:10s}  |  Modifica: {ds['modified'][:10]}")
    pub = ds.get('publisher') or '(non specificato)'
    print(f"     Publisher: {pub[:60]}")
    if ds["features"]:
        print(f"     Features: {', '.join(ds['features'])}")
    if verbose and ds.get("keyword"):
        kw_list = [k for k in ds['keyword'] if k]
        if kw_list:
            print(f"     Keywords: {', '.join(kw_list[:8])}")

def cmd_overview():
    themes = {}
    for ds in DATASETS:
        for t in ds.get("theme", []):
            themes[t] = themes.get(t, 0) + 1
    print(f"Catalogo Bologna — {len(DATASETS)} dataset\n")
    print("Temi:")
    for t, n in sorted(themes.items(), key=lambda x: -x[1]):
        print(f"  {t:30s} {n:4d}")
    print(f"\nUsa: query_catalog.py <comando>")
    print(f"Comandi: list, search <t>, theme <t>, publisher <p>, geo, timeserie, records <N>, show <id>")

def cmd_list():
    for ds in sorted(DATASETS, key=lambda x: x["id"]):
        print(f"  {ds['id']:55s} {ds['records_count']:>8d}  {', '.join(ds['theme'])[:40]}")

def cmd_search(terms):
    q = " ".join(terms).lower()
    results = [ds for ds in DATASETS 
               if q in ds["id"].lower() 
               or q in ds.get("title","").lower()
               or any(q in (kw or "").lower() for kw in (ds.get("keyword") or []))]
    print(f"🔍 Cerca '{q}' — {len(results)} risultati\n")
    for ds in results[:30]:
        print_ds(ds)
    if len(results) > 30:
        print(f"\n... e altri {len(results)-30} risultati")

def cmd_theme(terms):
    q = " ".join(terms).lower()
    results = [ds for ds in DATASETS if any(q in t.lower() for t in ds.get("theme",[]))]
    print(f"🏷️  Tema '{q}' — {len(results)} dataset\n")
    for ds in sorted(results, key=lambda x: -x["records_count"]):
        print_ds(ds)

def cmd_publisher(terms):
    q = " ".join(terms).lower()
    results = [ds for ds in DATASETS if q in (ds.get("publisher","") or "").lower()]
    print(f"🏢 Publisher '{q}' — {len(results)} dataset\n")
    for ds in sorted(results, key=lambda x: -x["records_count"])[:30]:
        print_ds(ds)

def cmd_geo():
    results = [ds for ds in DATASETS if "geo" in ds.get("features",[])]
    print(f"🗺️  Dataset geografici — {len(results)}\n")
    for ds in sorted(results, key=lambda x: -x["records_count"])[:30]:
        print_ds(ds)

def cmd_timeserie():
    results = [ds for ds in DATASETS if "timeserie" in ds.get("features",[])]
    print(f"📈 Serie storiche — {len(results)}\n")
    for ds in sorted(results, key=lambda x: -x["records_count"])[:30]:
        print_ds(ds)

def cmd_records(terms):
    try:
        min_rec = int(terms[0])
    except:
        print("Specifica un numero minimo di records")
        return
    results = [ds for ds in DATASETS if ds["records_count"] >= min_rec]
    print(f"📏 Dataset con >= {min_rec} records — {len(results)}\n")
    for ds in sorted(results, key=lambda x: -x["records_count"])[:30]:
        print_ds(ds)

def cmd_show(ds_id):
    results = [ds for ds in DATASETS if ds["id"] == ds_id[0]]
    if not results:
        # cerca parziale
        results = [ds for ds in DATASETS if ds_id[0] in ds["id"]]
    if not results:
        print(f"Nessun dataset trovato per '{ds_id[0]}'")
        return
    for ds in results[:5]:
        print_ds(ds, verbose=True)

if __name__ == "__main__":
    args = sys.argv[1:]
    if not args:
        cmd_overview()
    elif args[0] == "list":
        cmd_list()
    elif args[0] == "search":
        cmd_search(args[1:])
    elif args[0] == "theme":
        cmd_theme(args[1:])
    elif args[0] == "publisher":
        cmd_publisher(args[1:])
    elif args[0] == "geo":
        cmd_geo()
    elif args[0] == "timeserie":
        cmd_timeserie()
    elif args[0] == "records":
        cmd_records(args[1:])
    elif args[0] == "show":
        cmd_show(args[1:])
    else:
        print(f"Comando sconosciuto: {args[0]}")
        cmd_overview()
