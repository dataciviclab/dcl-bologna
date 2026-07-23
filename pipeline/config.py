"""Config utility: carica dataset YAML, costruisce URL export."""
import os, yaml, urllib.parse

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATASET_DIR = os.path.join(BASE_DIR, "dataset")
DATA_DIR = os.path.join(BASE_DIR, "_data")

API_BASE = "https://opendata.comune.bologna.it/api/explore/v2.1"

def load_config(dataset_id):
    """Carica un file YAML di configurazione dataset."""
    path = os.path.join(DATASET_DIR, f"{dataset_id}.yml")
    if not os.path.exists(path):
        raise FileNotFoundError(f"Config non trovata: {path}")
    with open(path) as f:
        return yaml.safe_load(f)

def export_url(config):
    """Costruisce URL di export Parquet per un dataset config."""
    ds = config["source"]
    ds_id = ds["dataset_id"]
    fmt = ds.get("export_format", "parquet")
    return f"{API_BASE}/catalog/datasets/{ds_id}/exports/{fmt}"

def data_path(dataset_id, fmt="parquet"):
    """Path locale dove salvare il parquet scaricato."""
    os.makedirs(DATA_DIR, exist_ok=True)
    return os.path.join(DATA_DIR, f"{dataset_id}.{fmt}")

def list_datasets():
    """Elenca tutti i dataset configurati."""
    if not os.path.exists(DATASET_DIR):
        return []
    return sorted([
        f.replace(".yml", "") for f in os.listdir(DATASET_DIR)
        if f.endswith(".yml")
    ])
