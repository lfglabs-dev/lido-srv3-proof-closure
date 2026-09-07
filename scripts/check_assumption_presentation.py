#!/usr/bin/env python3
"""Check the reader-facing groups without changing the assurance registry."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXPECTED_PARTS = {
    "model-source": {
        "A-SOURCE-SHAPED", "A-HANDWRITTEN-MINFIRST", "A-ABSTRACT-TX",
        "A-VERITY-SCAFFOLD", "A-YUL-INTERFACE",
    },
    "source-chain": {"A-SOLC-TRUSTED", "A-RUNTIME-PROVENANCE"},
    "deployment-constants": {"A-DEPOSIT-CONTRACT", "A-TOPUP-BEACON-ADDRESS",
                             "A-CANONICAL-REQUEST-ADDRESS", "A-DEPOSIT-32-ETHER"},
}


def validate(catalog, assumptions, guarantees):
    if catalog.get("schema") != "lido-assumption-presentation-v1":
        raise ValueError("unknown assumption presentation schema")
    known = {row["id"] for row in assumptions["assumptions"]}
    groups = catalog["groups"]
    if [group["id"] for group in groups] != list(EXPECTED_PARTS):
        raise ValueError("expected model, deployment and configured-value groups")
    seen = set()
    for group in groups:
        parts = group["parts"]
        if not parts or not set(parts) <= known or seen.intersection(parts):
            raise ValueError("empty, unknown or repeated assumption parts")
        if set(parts) != EXPECTED_PARTS[group["id"]]:
            raise ValueError(f"{group['id']}: incorrect assumption membership")
        seen.update(parts)
        if not all(isinstance(text, str) and text.strip()
                   for text in [group["title"], group["mitigation"], *parts.values()]):
            raise ValueError("empty assumption explanation")
    for row in guarantees["guarantees"]:
        if not set(row["assumptions"]) <= known:
            raise ValueError(f"{row['id']}: unknown registry assumption")


def main():
    def read(name):
        return json.loads((ROOT / "audit" / name).read_text())
    validate(read("assumption-presentation.json"), read("assumptions.yaml"),
             read("guarantees.yaml"))
    print("assumption presentation ok: known, distinct IDs; registry membership preserved")


if __name__ == "__main__":
    main()
