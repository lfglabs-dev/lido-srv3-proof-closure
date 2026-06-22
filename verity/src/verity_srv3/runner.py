from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from .fixtures import load_fixture
from .properties import PROPERTY_FUNCTIONS


def run_targets(targets_path: Path, fixtures_dir: Path) -> dict[str, Any]:
    manifest = json.loads(targets_path.read_text())
    results = []
    for target in sorted(manifest["targets"], key=lambda item: item["id"]):
        fixture_path = fixtures_dir / target["fixture"]
        state, args = load_fixture(fixture_path)
        check = PROPERTY_FUNCTIONS[target["property"]](state, **args)
        results.append(check.as_json())
    status = "pass" if all(result["status"] == "pass" for result in results) else "fail"
    return {
        "schema": "srv3-proof-report-v1",
        "status": status,
        "targets": results,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--targets", type=Path, default=Path("verity/targets/srv3-proof-targets.json"))
    parser.add_argument("--fixtures", type=Path, default=Path("tests/verity/fixtures"))
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    report = run_targets(args.targets, args.fixtures)
    text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text)
    else:
        print(text, end="")
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
