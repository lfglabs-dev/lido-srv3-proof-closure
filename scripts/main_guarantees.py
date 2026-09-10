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
        if not isinstance(main[key], list) or not main[key] or not all(isinstance(x, str) and x.strip() for x in main[key]):
            fail(f"{identifier}: invalid main result {key}")
    if not set(main["assumptions"]) <= set(context["assumptions"]):
        fail(f"{identifier}: unknown main assumption")
    resolved = [theorem_record(context["declarations"], "source", {"status": "CHECKED", "theorem": name}) for name in main["theorems"]]
    return {"main_result": {**main, "theorems": resolved}}


def load_main(root):
    import json
    main = json.loads((root / "audit/trio/main-guarantees.json").read_text())
    if main.get("schema") != 1 or set(main.get("guarantees", {})) != {"P-ALLOC-1", "P-ALLOC-2", "P-RESERVE-1", "P-TOPUP-2", "P-DEPOSIT-1", "P-TOPUP-1"}:
        raise ValueError("main source-model registry must contain the accepted trio and the registered actual TOPUP-2 value path")
    return main["guarantees"]
