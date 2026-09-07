#!/usr/bin/env python3
"""Check the reader-facing groups without changing the assurance registry."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def validate(catalog, assumptions, guarantees):
    if catalog.get("schema") != "lido-assumption-presentation-v1":
        raise ValueError("unknown assumption presentation schema")
    known = {row["id"] for row in assumptions["assumptions"]}
    groups = catalog["groups"]
    if [group["id"] for group in groups] != ["model-source", "source-chain"]:
        raise ValueError("expected model and deployment groups")
    seen = set()
    for group in groups:
        parts = group["parts"]
        if not parts or not set(parts) <= known or seen.intersection(parts):
            raise ValueError("empty, unknown or repeated assumption parts")
        seen.update(parts)
        if not all(isinstance(text, str) and text.strip()
                   for text in [group["title"], group["mitigation"], *parts.values()]):
            raise ValueError("empty assumption explanation")
    for row in guarantees["guarantees"]:
        ids = set(row["assumptions"])
        grouped = {key for group in groups for key in group["parts"] if key in ids}
        if grouped | (ids - seen) != ids:
            raise ValueError(f"{row['id']}: presentation loses assumptions")


def main():
    def read(name):
        return json.loads((ROOT / "audit" / name).read_text())
    validate(read("assumption-presentation.json"), read("assumptions.yaml"),
             read("guarantees.yaml"))
    print("assumption presentation ok: known, distinct IDs; registry membership preserved")


if __name__ == "__main__":
    main()
