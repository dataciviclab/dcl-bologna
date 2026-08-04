#!/usr/bin/env python3
"""
Check: validazione, freshness, registry.
Uso:
  python3 pipeline/check.py --registry    # genera/aggiorna registry.json
  python3 pipeline/check.py --status      # stampa stato riassuntivo
  python3 pipeline/check.py --all         # registry + status
"""
import os, sys, json, hashlib, time
from datetime import datetime, timezone

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE)
from pipeline.config import load_config, data_path, list_datasets

REGISTRY_PATH = os.path.join(BASE, "registry.json")

# Frequenze in giorni per calcolare "stale"
FREQ_DAYS = {
    "DAILY": 1, "WEEKLY": 7, "MONTHLY": 30, "QUARTERLY": 90,
    "ANNUAL": 365, "IRREGULAR": 180, "NEVER": 9999, "OTHER": 30,
}

def schema_hash(path):
    """Hash veloce dello schema (nomi colonne ordinati)."""
    try:
        from pipeline.parquet import inspect_parquet
        columns, _ = inspect_parquet(path)
        names = [c[0] for c in columns]
        return hashlib.md5("|".join(names).encode()).hexdigest()[:12]
    except Exception:
        return None

def validate_parquet(path):
    """Valida un file Parquet: esiste, è leggibile, ha records."""
    if not os.path.exists(path):
        return {"valid": False, "error": "file_not_found"}
    
    size = os.path.getsize(path)
    if size == 0:
        return {"valid": False, "error": "empty_file"}
    
    # Magic number
    with open(path, "rb") as f:
        magic = f.read(4)
    if magic != b'PAR1':
        return {"valid": False, "error": f"bad_magic:{magic.hex()}"}
    
    try:
        from pipeline.parquet import inspect_parquet
        columns, records = inspect_parquet(path)
        return {"valid": True, "records": records, "cols": len(columns), "size_bytes": size}
    except Exception as e:
        return {"valid": False, "error": f"duckdb:{str(e)[:100]}"}

def compute_freshness(dataset_id, config, last_fetch):
    """Determina lo stato freshness di un dataset."""
    freq = config.get("schedule", {}).get("frequency", "unknown").upper()
    max_days = FREQ_DAYS.get(freq, 30)
    
    if last_fetch is None:
        return "missing"
    
    elapsed = (datetime.now(timezone.utc) - last_fetch).days
    
    if elapsed <= max_days:
        return "ready"
    elif elapsed <= max_days * 2:
        return "aging"
    else:
        return "stale"

def build_registry():
    """Costruisce il registry completo."""
    datasets = list_datasets()
    now = datetime.now(timezone.utc)
    registry = {
        "generated_at": now.isoformat(),
        "datasets": {},
        "summary": {"total": 0, "ready": 0, "aging": 0, "stale": 0, "missing": 0, "error": 0}
    }
    
    # Carica registry precedente (per last_fetch)
    prev_registry = {}
    if os.path.exists(REGISTRY_PATH):
        try:
            with open(REGISTRY_PATH) as f:
                prev = json.load(f)
                prev_registry = prev.get("datasets", {})
        except: pass
    
    total_records = 0
    total_size = 0
    
    for ds_id in datasets:
        config = load_config(ds_id)
        ds_info = config.get("dataset", {})
        src = config.get("source", {})
        fmt = src.get("export_format", "parquet")
        path = data_path(ds_id, fmt)
        
        schedule = config.get("schedule", {})
        entry = {
            "id": ds_id,
            "title": ds_info.get("title", ""),
            "schedule": schedule.get("frequency", "unknown"),
            "theme": ds_info.get("theme", []),
        }
        
        # Validazione (usa mtime del file come last_fetch)
        validation = validate_parquet(path)
        if validation["valid"]:
            entry["status"] = "ready"
            entry["records"] = validation["records"]
            entry["cols"] = validation["cols"]
            entry["size_bytes"] = validation["size_bytes"]
            entry["size_mb"] = round(validation["size_bytes"] / 1024 / 1024, 1)
            entry["schema_hash"] = schema_hash(path)
            
            # Last fetch = mtime del file Parquet
            mtime = os.path.getmtime(path)
            last_fetch = datetime.fromtimestamp(mtime, tz=timezone.utc)
            entry["last_fetch"] = last_fetch.isoformat()
            
            # Freshness
            freshness = compute_freshness(ds_id, config, last_fetch)
            entry["freshness"] = freshness
            if freshness != "ready":
                entry["status"] = freshness
            
            total_records += validation["records"]
            total_size += validation["size_bytes"]
        else:
            entry["status"] = "missing" if validation["error"] == "file_not_found" else "error"
            entry["error"] = validation["error"]
        
        registry["datasets"][ds_id] = entry
        registry["summary"][entry["status"]] += 1
    
    registry["summary"]["total"] = len(datasets)
    registry["summary"]["total_records"] = total_records
    registry["summary"]["total_size_mb"] = round(total_size / 1024 / 1024, 1)
    
    return registry

def print_status(registry):
    """Stampa sommario stato."""
    s = registry["summary"]
    print(f"\n📊 Bologna Pilota — Registry")
    print(f"{'='*50}")
    print(f"  Dataset configurati: {s['total']}")
    print(f"  ✅ Pronti:   {s['ready']}")
    print(f"  ⚠️  Invecchiati: {s.get('aging', 0)}")
    print(f"  🔴 Stale:    {s.get('stale', 0)}")
    print(f"  ⬜ Mancanti: {s.get('missing', 0)}")
    print(f"  ❌ Errore:   {s.get('error', 0)}")
    print(f"  📦 Records:  {s.get('total_records', 0):,}")
    print(f"  💾 Dimensione: {s.get('total_size_mb', 0)} MB")
    print()
    
    for ds_id, entry in registry["datasets"].items():
        status_icon = {"ready": "✅", "aging": "⚠️", "stale": "🔴", "missing": "⬜", "error": "❌"}.get(entry["status"], "❓")
        size = entry.get("size_mb", "?")
        records = f"{entry.get('records', 0):>8,}" if "records" in entry else "       -"
        freq = entry.get("schedule", "?")[:6]
        last = entry.get("last_fetch", "—")[:10] if entry.get("last_fetch") else "—"
        title = entry.get("title", ds_id)[:55]
        print(f"  {status_icon} {ds_id:35s} {records}  {size:4}MB  {freq:6s}  {last}")

def main():
    args = sys.argv[1:]
    
    if "--registry" in args or "--all" in args or not args:
        registry = build_registry()
        with open(REGISTRY_PATH, "w") as f:
            json.dump(registry, f, indent=2, ensure_ascii=False)
        print(f"✅ Registry salvato: {REGISTRY_PATH}")
        print(f"   {registry['summary']['total']} dataset, "
              f"{registry['summary']['total_records']:,} records, "
              f"{registry['summary']['total_size_mb']} MB")
    
    if "--status" in args or "--all" in args or not args:
        # --status verifica sempre i parquet reali, mai il registry cached
        registry = build_registry()
        print_status(registry)

if __name__ == "__main__":
    main()
