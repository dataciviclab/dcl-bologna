"""Test dei contratti config↔runtime (pipeline/config.py + dataset yml).

Marker: contract — export_url deve produrre URL valide per urllib anche
con dataset_id contenenti spazi/parentesi (es. dataset famiglia
Opendatasoft); il yml varchi-ztl deve dichiarare il fetch dedicato
così il fetch generico non ci inciampa.
"""
import os
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE)

from pipeline.config import export_url, load_config

API_BASE = "https://opendata.comune.bologna.it/api/explore/v2.1"


def test_export_url_encodes_special_chars():
    """Regressione reale: 'famiglia varchi (80 dataset varco-n-*)' causava
    InvalidURL su urllib (spazi non encodati)."""
    config = {
        "source": {
            "dataset_id": "famiglia varchi (80 dataset varco-n-*)",
            "export_format": "parquet",
        }
    }
    url = export_url(config)
    assert " " not in url
    assert "%20" in url
    assert url.startswith(API_BASE)


def test_export_url_plain_id_unchanged():
    config = {"source": {"dataset_id": "annuale_popolazione_residente", "export_format": "parquet"}}
    url = export_url(config)
    assert url == f"{API_BASE}/catalog/datasets/annuale_popolazione_residente/exports/parquet"


def test_varchi_ztl_config_declares_dedicated_fetch():
    """Il fetch generico deve sapere che varchi-ztl ha un fetch dedicato."""
    config = load_config("varchi-ztl")
    src = config["source"]
    assert src.get("fetch") == "dedicated"
    assert src.get("fetch_script") == "pipeline/fetch_varchi.py"
