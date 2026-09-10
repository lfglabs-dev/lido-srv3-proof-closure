"""Resolve main source-model registrations without changing legacy theorem pairs."""

def main_record(identifier: str, context: dict, theorem_record, fail) -> dict:
    records = context["main_results"]
    if identifier not in records:
        return {}
    main = records[identifier]
    required = {"description", "model", "theorems", "covered", "missing", "conditions", "assumptions", "outside"}
    if set(main) != required:
        fail(f"{identifier}: incomplete main result")
    for key in ("theorems", "covered", "missing", "conditions", "assumptions", "outside"):
        if not isinstance(main[key], list) or (key != "missing" and not main[key]) or not all(isinstance(x, str) and x.strip() for x in main[key]):
            fail(f"{identifier}: invalid main result {key}")
    if not set(main["assumptions"]) <= set(context["assumptions"]):
        fail(f"{identifier}: unknown main assumption")
    resolved = [theorem_record(context["declarations"], "source", {"status": "CHECKED", "theorem": name}) for name in main["theorems"]]
    return {"main_result": {**main, "theorems": resolved}}


def load_main(root):
    import json
    main = json.loads((root / "audit/trio/main-guarantees.json").read_text())
    if main.get("schema") != 1 or set(main.get("guarantees", {})) != {"P-ALLOC-1", "P-ALLOC-2", "P-RESERVE-1", "P-TOPUP-2", "P-DEPOSIT-1", "P-TOPUP-1", "P-SSZ-1", "P-CONSOLIDATION-1"}:
        raise ValueError("main source-model registry must contain the accepted trio and registered actual source consumers")
    return main["guarantees"]


def main_display(row: dict, main: dict) -> dict:
    """Display a closed source result without erasing the historical pair."""
    if not main or main["missing"]:
        return {}
    return {
        "summary": main["description"] + " The theorem pair, fidelity and boundary entries retained below describe the historical models; main_result records the current source claim and its conditions.",
        "classification": {"kind": "NONE"},
        "next_gate": "No internal obligation remains for the registered main_result within its stated conditions and exclusions. This is not completion of other guarantees or a deployed-contract claim.",
        "legacy_display": {key: row[key] for key in ("summary", "classification", "next_gate")},
    }
