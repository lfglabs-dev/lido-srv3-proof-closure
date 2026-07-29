#!/usr/bin/env python3
"""Validate and deterministically render the SRv3 audit-control registry."""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import subprocess
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "audit"
REGISTRY = AUDIT / "invariants.yaml"
SCHEMA = AUDIT / "schema.json"
LOCK = AUDIT / "dependencies.lock.json"
ARTIFACTS = AUDIT / "artifacts.json"
EXPECTED_ARTIFACTS = {
    "proof-arithmetic", "proof-trace", "proof-allocation", "proof-strategy",
    "legacy-model", "legacy-proofs", "consolidation-runtime",
}
GENERATED = (
    "BY_FAMILY.md", "BY_STATUS.md", "BY_LAYER.md", "TRUST_BOUNDARIES.md",
    "ASSUMPTIONS.md", "REPRODUCE.md", "MATRIX.csv",
)
LAYERS = ["MODEL", "ALG", "TX", "REL", "TRACE", "SRC", "YUL", "EVM", "CRYPTO", "E2E"]
PRIORITIES = {"P0", "P1", "P2", "STRETCH"}
STATUSES = {"PROVED", "REGRESSION", "DEV-431-READY", "OPEN", "BLOCKED", "STRETCH"}
ENGINES = {"LEAN", "VERITY", "EVMYULLEAN", "INTERFACE", "NATIVE-FFI", "NONE"}
FIELDS = {
    "id", "family", "priority", "status", "layer", "engine", "source_anchors",
    "runtime_anchors", "theorem", "assumptions", "trust_boundary", "falsifier",
    "dependencies", "reproduction",
}
MD_HEADER = "<!-- GENERATED from audit/invariants.yaml; NOT EDITABLE TRUTH. -->\n"
CSV_HEADER = "# GENERATED from audit/invariants.yaml; NOT EDITABLE TRUTH.\n"


class RegistryError(Exception):
    pass


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise RegistryError(f"{path.relative_to(ROOT)}: {error}") from error


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RegistryError(message)


def validate_theorems(data: dict) -> None:
    theorems = sorted(
        row["theorem"] for row in data["invariants"] if row["status"] == "PROVED"
    )
    for theorem in theorems:
        require(
            re.fullmatch(r"[A-Za-z_][A-Za-z0-9_']*(?:\.[A-Za-z_][A-Za-z0-9_']*)+", theorem) is not None,
            f"invalid fully qualified theorem name: {theorem}",
        )
    source = "import LidoSRv3\n" + "".join(f"#check {theorem}\n" for theorem in theorems)
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".lean", encoding="utf-8", dir=ROOT, delete=False
    ) as check_file:
        check_file.write(source)
        check_path = Path(check_file.name)
    try:
        build = subprocess.run(
            ["lake", "build", "LidoSRv3"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        require(
            build.returncode == 0,
            "cannot build LidoSRv3 theorem surface:\n" + (build.stderr or build.stdout).strip(),
        )
        result = subprocess.run(
            ["lake", "env", "lean", str(check_path)],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
    finally:
        check_path.unlink()
    require(
        result.returncode == 0,
        "PROVED theorem does not exist in LidoSRv3 build surface:\n"
        + (result.stderr or result.stdout).strip(),
    )


def validate(path: Path = REGISTRY) -> dict:
    data = load_json(path)
    schema = load_json(SCHEMA)
    require(isinstance(schema, dict) and schema.get("title"), "schema.json is invalid")
    require(isinstance(data, dict), "registry root must be an object")
    require(set(data) == {"schema_version", "allowed_layers", "invariants"}, "unexpected registry root fields")
    require(data["schema_version"] == 1, "schema_version must be 1")
    require(data["allowed_layers"] == LAYERS, "allowed_layers must match the canonical ordered list")
    require(isinstance(data["invariants"], list) and data["invariants"], "invariants must be a nonempty array")

    ids: set[str] = set()
    theorem_owners: dict[str, str] = {}
    for index, row in enumerate(data["invariants"]):
        prefix = f"invariants[{index}]"
        require(isinstance(row, dict), f"{prefix} must be an object")
        require(set(row) == FIELDS, f"{prefix} fields differ: {sorted(set(row) ^ FIELDS)}")
        invariant_id = row["id"]
        require(isinstance(invariant_id, str) and re.fullmatch(r"[A-Z][A-Z0-9-]*", invariant_id) is not None,
                f"{prefix}.id is not stable-ID shaped")
        require(invariant_id not in ids, f"duplicate id: {invariant_id}")
        ids.add(invariant_id)
        require(isinstance(row["family"], str) and row["family"], f"{invariant_id}: family required")
        require(row["priority"] in PRIORITIES, f"{invariant_id}: invalid priority")
        require(row["status"] in STATUSES, f"{invariant_id}: invalid status")
        require(row["layer"] in LAYERS, f"{invariant_id}: invalid layer")
        require(row["engine"] in ENGINES, f"{invariant_id}: invalid engine")
        for name in ("source_anchors", "runtime_anchors", "assumptions", "trust_boundary", "dependencies"):
            value = row[name]
            require(isinstance(value, list) and all(isinstance(item, str) and item for item in value),
                    f"{invariant_id}: {name} must contain nonempty strings")
            require(len(value) == len(set(value)), f"{invariant_id}: duplicate {name}")
        for name in ("falsifier", "reproduction"):
            require(isinstance(row[name], str) and row[name], f"{invariant_id}: {name} required")
        theorem = row["theorem"]
        require(theorem is None or isinstance(theorem, str) and theorem, f"{invariant_id}: invalid theorem")
        if theorem is not None:
            require(theorem not in theorem_owners, f"theorem {theorem} duplicated by {theorem_owners.get(theorem)}")
            theorem_owners[theorem] = invariant_id
        if row["status"] == "PROVED":
            require(theorem is not None, f"{invariant_id}: PROVED requires theorem")
        if row["layer"] in {"EVM", "E2E"} and row["status"] in {"PROVED", "REGRESSION"}:
            require(bool(row["runtime_anchors"]), f"{invariant_id}: runtime assurance requires anchors")

    graph = {row["id"]: row["dependencies"] for row in data["invariants"]}
    for node, dependencies in graph.items():
        for dependency in dependencies:
            require(dependency in graph, f"{node}: unknown dependency {dependency}")
            require(dependency != node, f"{node}: self dependency")
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(node: str) -> None:
        if node in visiting:
            raise RegistryError(f"dependency cycle at {node}")
        if node in visited:
            return
        visiting.add(node)
        for dependency in graph[node]:
            visit(dependency)
        visiting.remove(node)
        visited.add(node)

    for node in sorted(graph):
        visit(node)
    validate_theorems(data)
    return data


def validate_lock() -> None:
    lock = load_json(LOCK)
    expected = {
        "proof": "ee2e65cd807e913ea245ae6fd7987a7f1d962800",
        "verity": "68f560e66c5de6123061ce5ed60261be162673d1",
        "evmyullean": "f7e4ee0dc8f8d5265ce822a937ab5be771f182e9",
        "lido_core": "af095e48bbc1c3841c2c9936219c8461af01056b",
    }
    for component, commit in expected.items():
        require(lock[component]["commit"] == commit, f"{component}: exact pin mismatch")
    require(lock["future_root"]["direct_dependencies"] == ["verity"], "future root must depend exactly once on Verity")
    require("transitive" in lock["evmyullean"]["resolution"], "EVMYulLean must be transitive")


def validate_artifacts(path: Path = ARTIFACTS) -> None:
    manifest = load_json(path)
    require(isinstance(manifest, dict), "artifact manifest root must be an object")
    require(set(manifest) == {"schema", "trust_levels", "artifacts"}, "unexpected artifact manifest fields")
    require(manifest["schema"] == "srv3-artifacts-v1", "invalid artifact manifest schema")
    trust_levels = manifest.get("trust_levels", {})
    require(isinstance(trust_levels, dict) and trust_levels, "trust_levels must be a nonempty object")
    artifacts = manifest.get("artifacts")
    require(isinstance(artifacts, list) and artifacts, "artifacts must be a nonempty array")
    seen: set[str] = set()
    for artifact in artifacts:
        require(isinstance(artifact, dict), "artifact entry must be an object")
        artifact_id = artifact.get("id")
        require(artifact_id and artifact_id not in seen, f"invalid/duplicate artifact id: {artifact_id}")
        seen.add(artifact_id)
        require(artifact.get("trust") in trust_levels, f"{artifact_id}: undefined trust level")
        path = artifact.get("path")
        digest = artifact.get("sha256")
        if path is None:
            require(digest is None and artifact.get("blocker"), f"{artifact_id}: unavailable artifact needs blocker")
            continue
        file_path = ROOT / path
        require(file_path.is_file(), f"{artifact_id}: missing {path}")
        actual = hashlib.sha256(file_path.read_bytes()).hexdigest()
        require(digest == actual, f"{artifact_id}: sha256 mismatch: expected {digest}, got {actual}")
    require(seen == EXPECTED_ARTIFACTS, f"artifact inventory differs: {sorted(seen ^ EXPECTED_ARTIFACTS)}")


def rows_by(data: dict, key: str) -> dict[str, list[dict]]:
    grouped: dict[str, list[dict]] = defaultdict(list)
    for row in data["invariants"]:
        grouped[row[key]].append(row)
    return grouped


def render_grouped(data: dict, key: str, title: str, order: list[str] | None = None) -> str:
    grouped = rows_by(data, key)
    keys = [value for value in (order or sorted(grouped)) if value in grouped]
    out = [MD_HEADER, f"# {title}\n\n"]
    for value in keys:
        out.append(f"## {value}\n\n")
        out.append("| ID | Priority | Status | Layer | Engine | Theorem |\n")
        out.append("| --- | --- | --- | --- | --- | --- |\n")
        for row in sorted(grouped[value], key=lambda item: item["id"]):
            theorem = row["theorem"] or "—"
            out.append(f"| {row['id']} | {row['priority']} | {row['status']} | {row['layer']} | {row['engine']} | `{theorem}` |\n")
        out.append("\n")
    return "".join(out)


def render_list_view(data: dict, field: str, title: str) -> str:
    out = [MD_HEADER, f"# {title}\n\n"]
    for row in sorted(data["invariants"], key=lambda item: item["id"]):
        out.append(f"## {row['id']}\n\n")
        values = row[field]
        if values:
            out.extend(f"- {value}\n" for value in values)
        else:
            out.append("- None declared.\n")
        out.append("\n")
    return "".join(out)


def render_reproduce(data: dict) -> str:
    out = [MD_HEADER, "# Reproduction commands\n\n"]
    for row in sorted(data["invariants"], key=lambda item: item["id"]):
        out.append(f"## {row['id']}\n\n```sh\n{row['reproduction']}\n```\n\n")
    return "".join(out)


def render_csv(data: dict) -> str:
    stream = io.StringIO(newline="")
    stream.write(CSV_HEADER)
    writer = csv.writer(stream, lineterminator="\n")
    writer.writerow(["id", "family", "priority", "status", "layer", "engine", "theorem",
                     "source_anchors", "runtime_anchors", "dependencies"])
    for row in sorted(data["invariants"], key=lambda item: item["id"]):
        writer.writerow([
            row["id"], row["family"], row["priority"], row["status"], row["layer"], row["engine"],
            row["theorem"] or "", " | ".join(row["source_anchors"]), " | ".join(row["runtime_anchors"]),
            " | ".join(row["dependencies"]),
        ])
    return stream.getvalue()


def rendered(data: dict) -> dict[str, str]:
    return {
        "BY_FAMILY.md": render_grouped(data, "family", "Invariants by family"),
        "BY_STATUS.md": render_grouped(data, "status", "Invariants by status",
                                       ["PROVED", "REGRESSION", "DEV-431-READY", "OPEN", "BLOCKED", "STRETCH"]),
        "BY_LAYER.md": render_grouped(data, "layer", "Invariants by layer", LAYERS),
        "TRUST_BOUNDARIES.md": render_list_view(data, "trust_boundary", "Trust boundaries"),
        "ASSUMPTIONS.md": render_list_view(data, "assumptions", "Assumptions"),
        "REPRODUCE.md": render_reproduce(data),
        "MATRIX.csv": render_csv(data),
    }


def generate(data: dict) -> None:
    for name, content in rendered(data).items():
        (AUDIT / name).write_text(content, encoding="utf-8", newline="\n")


def check_fresh(data: dict) -> None:
    for name, expected in rendered(data).items():
        path = AUDIT / name
        require(path.is_file(), f"missing generated view: audit/{name}")
        assert_fresh(path, expected, f"audit/{name}")


def assert_fresh(path: Path, expected: str, label: str) -> None:
    require(path.read_text(encoding="utf-8") == expected, f"stale generated view: {label}")


def proof_escape_scan() -> None:
    patterns = re.compile(r"(^|[^A-Za-z])(sorry|admit|axiom|unsafe)([^A-Za-z]|$)")
    tracked = subprocess.run(
        ["git", "ls-files", "*.lean"], cwd=ROOT, check=True, text=True, capture_output=True
    ).stdout.splitlines()
    violations = []
    for name in tracked:
        block_depth = 0
        for number, line in enumerate((ROOT / name).read_text(encoding="utf-8").splitlines(), 1):
            code_parts = []
            cursor = 0
            while cursor < len(line):
                if block_depth:
                    opening = line.find("/-", cursor)
                    closing = line.find("-/", cursor)
                    if closing == -1:
                        cursor = len(line)
                    elif opening != -1 and opening < closing:
                        block_depth += 1
                        cursor = opening + 2
                    else:
                        block_depth -= 1
                        cursor = closing + 2
                else:
                    opening = line.find("/-", cursor)
                    comment = line.find("--", cursor)
                    if comment != -1 and (opening == -1 or comment < opening):
                        code_parts.append(line[cursor:comment])
                        cursor = len(line)
                    elif opening == -1:
                        code_parts.append(line[cursor:])
                        cursor = len(line)
                    else:
                        code_parts.append(line[cursor:opening])
                        block_depth = 1
                        cursor = opening + 2
            code = "".join(code_parts)
            if patterns.search(code):
                violations.append(f"{name}:{number}:{line.strip()}")
    require(not violations, "proof escape(s):\n" + "\n".join(violations))


def negative_tests() -> None:
    try:
        validate(AUDIT / "fixtures" / "invalid-entry.yaml")
    except RegistryError:
        pass
    else:
        raise RegistryError("invalid registry fixture unexpectedly passed")
    data = validate()
    mutant = json.loads(json.dumps(data))
    next(row for row in mutant["invariants"] if row["status"] == "PROVED")["theorem"] = "No.Such.Theorem"
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".yaml", encoding="utf-8", dir=AUDIT, delete=False
    ) as mutant_file:
        json.dump(mutant, mutant_file)
        mutant_path = Path(mutant_file.name)
    try:
        try:
            validate(mutant_path)
        except RegistryError:
            pass
        else:
            raise RegistryError("nonexistent theorem mutant unexpectedly passed")
    finally:
        mutant_path.unlink()
    for fixture in ("empty-artifacts.json", "missing-required-artifact.json"):
        try:
            validate_artifacts(AUDIT / "fixtures" / fixture)
        except RegistryError:
            pass
        else:
            raise RegistryError(f"{fixture} unexpectedly passed")
    with tempfile.TemporaryDirectory() as directory:
        stale = Path(directory) / "BY_STATUS.md"
        stale.write_text("stale\n", encoding="utf-8")
        try:
            assert_fresh(stale, rendered(data)["BY_STATUS.md"], "negative fixture")
        except RegistryError:
            pass
        else:
            raise RegistryError("stale generated fixture unexpectedly passed")


def check() -> None:
    data = validate()
    validate_lock()
    validate_artifacts()
    check_fresh(data)
    proof_escape_scan()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("check", "generate", "test-negative"))
    args = parser.parse_args()
    try:
        if args.command == "generate":
            generate(validate())
        elif args.command == "test-negative":
            negative_tests()
        else:
            check()
    except RegistryError as error:
        print(f"audit registry: FAIL: {error}", file=sys.stderr)
        return 1
    print(f"audit registry: {args.command}: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
