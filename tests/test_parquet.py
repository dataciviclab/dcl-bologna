"""Test del contratto condiviso di ispezione Parquet (pipeline/parquet.py).

Marker: contract — helper usato da fetch.py (validazione post-download)
e check.py (registry/status). Protegge la sintassi DuckDB corretta
(`DESCRIBE SELECT * FROM read_parquet(...)`, non `DESCRIBE read_parquet(...)`
che fallisce con Parser Error).
"""
import os
import sys

import pandas as pd

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE)

from pipeline.parquet import inspect_parquet


def test_inspect_parquet_columns_ordered_and_records(tmp_path):
    path = tmp_path / "test.parquet"
    pd.DataFrame({"b": [1, 2, 3], "a": ["x", "y", "z"]}).to_parquet(path)

    columns, records = inspect_parquet(str(path))

    assert records == 3
    # colonne ordinate per nome, con tipo
    assert [c[0] for c in columns] == ["a", "b"]
    assert dict(columns)["b"]  # il tipo esiste


def test_inspect_parquet_uses_valid_describe_syntax(tmp_path):
    """Regressione reale: DESCRIBE read_parquet(...) lancia Parser Error."""
    path = tmp_path / "regression.parquet"
    pd.DataFrame({"x": [1]}).to_parquet(path)

    columns, records = inspect_parquet(str(path))

    assert records == 1
    assert columns[0][0] == "x"
