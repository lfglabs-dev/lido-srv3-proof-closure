#!/usr/bin/env python3
"""Validate and deterministically render the SRv3 audit-control registry."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import io
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "audit"
REGISTRY = AUDIT / "invariants.yaml"
SCHEMA = AUDIT / "schema.json"
LOCK = AUDIT / "dependencies.lock.json"
ARTIFACTS = AUDIT / "artifacts.json"
EXPECTED_ARTIFACTS = {
    "proof-arithmetic": ("LidoSRv3/Audit/Arithmetic.lean", "LEAN-CHECKED"),
    "proof-trace": ("LidoSRv3/Audit/Trace.lean", "LEAN-CHECKED"),
    "proof-allocation": ("LidoSRv3/Audit/Allocation.lean", "LEAN-CHECKED"),
    "proof-strategy-model": ("LidoSRv3/Audit/Strategy.lean", "LEAN-CHECKED"),
    "proof-strategy": ("LidoSRv3/Audit/StrategyProofs.lean", "LEAN-CHECKED"),
    "proof-strategy-vectors": ("LidoSRv3/Audit/Vectors.lean", "LEAN-CHECKED"),
    "legacy-model": ("LidoSRv3/Model.lean", "REGRESSION"),
    "legacy-proofs": ("LidoSRv3/SpecProofs.lean", "REGRESSION"),
    "consolidation-runtime": (None, "PROVENANCE-BLOCKED"),
}
GENERATED = (
    "BY_FAMILY.md", "BY_STATUS.md", "BY_LAYER.md", "TRUST_BOUNDARIES.md",
    "ASSUMPTIONS.md", "REPRODUCE.md", "MATRIX.csv",
)
MD_HEADER = "<!-- GENERATED from audit/invariants.yaml; NOT EDITABLE TRUTH. -->\n"
CSV_FIELDS = ["id", "family", "priority", "status", "layer", "engine", "theorem",
              "source_anchors", "runtime_anchors", "dependencies"]


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


def json_type_matches(value: object, expected: str) -> bool:
    return {
        "array": isinstance(value, list),
        "null": value is None,
        "object": isinstance(value, dict),
        "string": isinstance(value, str),
    }.get(expected, False)


def validate_schema_definition(schema: object) -> dict:
    require(isinstance(schema, dict), "schema.json: schema root must be an object")
    require(schema.get("type") == "object", "schema.json: registry root schema must be object")
    require(schema.get("additionalProperties") is False,
            "schema.json: registry root schema must be closed")
    properties = schema.get("properties")
    required = schema.get("required")
    require(isinstance(properties, dict) and properties,
            "schema.json: registry root properties required")
    require(isinstance(required, list) and set(required) == set(properties),
            "schema.json: registry root required must equal properties")
    require({"schema_version", "allowed_layers", "invariants"} <= set(properties),
            "schema.json: registry root constraints incomplete")

    invariants = properties["invariants"]
    require(isinstance(invariants, dict) and invariants.get("type") == "array",
            "schema.json: invariants must be an array schema")
    require(invariants.get("minItems") == 1,
            "schema.json: invariants must require at least one item")
    item = invariants.get("items")
    require(isinstance(item, dict) and item.get("type") == "object",
            "schema.json: invariant item must be an object schema")
    require(item.get("additionalProperties") is False,
            "schema.json: invariant item schema must be closed")
    item_properties = item.get("properties")
    item_required = item.get("required")
    require(isinstance(item_properties, dict) and item_properties,
            "schema.json: invariant properties required")
    require(isinstance(item_required, list) and set(item_required) == set(item_properties),
            "schema.json: invariant required must equal properties")
    for field in ("priority", "status", "layer", "engine"):
        values = item_properties.get(field, {}).get("enum")
        require(
            isinstance(values, list)
            and values
            and len(values) == len(set(values))
            and all(isinstance(value, str) for value in values),
            f"schema.json: {field} enum must contain unique strings",
        )
    layers = properties["allowed_layers"].get("const")
    require(layers == item_properties["layer"]["enum"],
            "schema.json: allowed_layers const must equal layer enum")
    return schema


def validate_against_schema(value: object, schema: dict, location: str = "registry") -> None:
    if "const" in schema:
        require(value == schema["const"], f"{location}: does not match schema const")
    if "enum" in schema:
        require(value in schema["enum"], f"{location}: value is not in schema enum")
    expected_types = schema.get("type")
    if expected_types is not None:
        candidates = expected_types if isinstance(expected_types, list) else [expected_types]
        require(
            all(isinstance(candidate, str) for candidate in candidates)
            and any(json_type_matches(value, candidate) for candidate in candidates),
            f"{location}: does not match schema type",
        )
    if isinstance(value, dict):
        properties = schema.get("properties", {})
        required = schema.get("required", [])
        require(all(name in value for name in required),
                f"{location}: missing required schema field")
        if schema.get("additionalProperties") is False:
            require(set(value) <= set(properties),
                    f"{location}: additional field forbidden by schema")
        for name, child in value.items():
            if name in properties:
                validate_against_schema(child, properties[name], f"{location}.{name}")
    if isinstance(value, list):
        if "minItems" in schema:
            require(len(value) >= schema["minItems"],
                    f"{location}: fewer items than schema minimum")
        if schema.get("uniqueItems"):
            require(len({json.dumps(item, sort_keys=True) for item in value}) == len(value),
                    f"{location}: duplicate items forbidden by schema")
        if "items" in schema:
            for index, child in enumerate(value):
                validate_against_schema(child, schema["items"], f"{location}[{index}]")
    if isinstance(value, str):
        if "minLength" in schema:
            require(len(value) >= schema["minLength"],
                    f"{location}: shorter than schema minimum")
        if "pattern" in schema:
            require(re.fullmatch(schema["pattern"], value) is not None,
                    f"{location}: does not match schema pattern")


def schema_values(schema: dict, field: str) -> list[str]:
    return schema["properties"]["invariants"]["items"]["properties"][field]["enum"]


def validate_theorems(data: dict) -> None:
    theorems = sorted(
        row["theorem"] for row in data["invariants"] if row["theorem"] is not None
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
    check_path.chmod(0o644)
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
            ["lake", "env", "lean", str(check_path.relative_to(ROOT))],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
    finally:
        check_path.unlink()
    require(
        result.returncode == 0,
        "registry theorem does not exist in LidoSRv3 build surface:\n"
        + (result.stderr or result.stdout).strip(),
    )


def validate(path: Path = REGISTRY, schema_path: Path = SCHEMA) -> dict:
    data = load_json(path)
    schema = validate_schema_definition(load_json(schema_path))
    validate_against_schema(data, schema)
    layers = schema_values(schema, "layer")

    ids: set[str] = set()
    theorem_owners: dict[str, str] = {}
    for row in data["invariants"]:
        invariant_id = row["id"]
        require(invariant_id not in ids, f"duplicate id: {invariant_id}")
        ids.add(invariant_id)
        for name in ("source_anchors", "runtime_anchors", "assumptions", "trust_boundary", "dependencies"):
            value = row[name]
            require(len(value) == len(set(value)), f"{invariant_id}: duplicate {name}")
        theorem = row["theorem"]
        if theorem is not None:
            require(theorem not in theorem_owners, f"theorem {theorem} duplicated by {theorem_owners.get(theorem)}")
            theorem_owners[theorem] = invariant_id
        if row["status"] == "PROVED":
            require(theorem is not None, f"{invariant_id}: PROVED requires theorem")
        if row["layer"] in set(layers) & {"EVM", "E2E"} and row["status"] in {"PROVED", "REGRESSION"}:
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
        require(artifact_id in EXPECTED_ARTIFACTS, f"unexpected artifact id: {artifact_id}")
        expected_path, expected_trust = EXPECTED_ARTIFACTS[artifact_id]
        require(artifact.get("path") == expected_path,
                f"{artifact_id}: path must be {expected_path}")
        require(artifact.get("trust") == expected_trust,
                f"{artifact_id}: trust must be {expected_trust}")
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
    require(seen == set(EXPECTED_ARTIFACTS),
            f"artifact inventory differs: {sorted(seen ^ set(EXPECTED_ARTIFACTS))}")


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
    writer = csv.writer(stream, lineterminator="\n")
    writer.writerow(CSV_FIELDS)
    for row in sorted(data["invariants"], key=lambda item: item["id"]):
        writer.writerow([
            row["id"], row["family"], row["priority"], row["status"], row["layer"], row["engine"],
            row["theorem"] or "", " | ".join(row["source_anchors"]), " | ".join(row["runtime_anchors"]),
            " | ".join(row["dependencies"]),
        ])
    return stream.getvalue()


def rendered(data: dict, schema: dict | None = None) -> dict[str, str]:
    schema = schema or validate_schema_definition(load_json(SCHEMA))
    views = {
        "BY_FAMILY.md": render_grouped(data, "family", "Invariants by family"),
        "BY_STATUS.md": render_grouped(data, "status", "Invariants by status",
                                       schema_values(schema, "status")),
        "BY_LAYER.md": render_grouped(data, "layer", "Invariants by layer",
                                      schema_values(schema, "layer")),
        "TRUST_BOUNDARIES.md": render_list_view(data, "trust_boundary", "Trust boundaries"),
        "ASSUMPTIONS.md": render_list_view(data, "assumptions", "Assumptions"),
        "REPRODUCE.md": render_reproduce(data),
        "MATRIX.csv": render_csv(data),
    }
    assert_render_coverage(data, views)
    return views


def assert_render_coverage(data: dict, views: dict[str, str]) -> None:
    expected = Counter(row["id"] for row in data["invariants"])
    grouped = ("BY_FAMILY.md", "BY_STATUS.md", "BY_LAYER.md")
    headings = ("TRUST_BOUNDARIES.md", "ASSUMPTIONS.md", "REPRODUCE.md")
    for name in grouped:
        actual = Counter(
            value
            for value in re.findall(
                r"^\| ([A-Z][A-Z0-9-]*) \|", views[name], re.MULTILINE
            )
            if value != "ID"
        )
        require(actual == expected, f"{name}: rendered ID coverage differs")
    for name in headings:
        actual = Counter(re.findall(r"^## ([A-Z][A-Z0-9-]*)$", views[name], re.MULTILINE))
        require(actual == expected, f"{name}: rendered ID coverage differs")
    matrix = csv.DictReader(io.StringIO(views["MATRIX.csv"]))
    require(matrix.fieldnames == CSV_FIELDS, "MATRIX.csv: invalid CSV header")
    actual = Counter(row["id"] for row in matrix)
    require(actual == expected, "MATRIX.csv: rendered ID coverage differs")


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


def find_proof_escapes(sources: list[tuple[str, str]]) -> list[str]:
    patterns = re.compile(r"(^|[^A-Za-z])(sorry|admit|axiom|constant|unsafe)([^A-Za-z]|$)")
    violations = []
    for name, source in sources:
        block_depth = 0
        in_string = False
        escaped = False
        for number, line in enumerate(source.splitlines(), 1):
            code_parts = []
            cursor = 0
            while cursor < len(line):
                if in_string:
                    character = line[cursor]
                    if escaped:
                        escaped = False
                    elif character == "\\":
                        escaped = True
                    elif character == '"':
                        in_string = False
                    cursor += 1
                elif block_depth:
                    if line.startswith("/-", cursor):
                        block_depth += 1
                        cursor += 2
                    elif line.startswith("-/", cursor):
                        block_depth -= 1
                        cursor += 2
                    else:
                        cursor += 1
                elif line.startswith("--", cursor):
                    break
                elif line.startswith("/-", cursor):
                    block_depth = 1
                    cursor += 2
                elif line[cursor] == '"':
                    in_string = True
                    escaped = False
                    cursor += 1
                else:
                    code_parts.append(line[cursor])
                    cursor += 1
            escaped = False
            code = "".join(code_parts)
            if patterns.search(code):
                violations.append(f"{name}:{number}:{line.strip()}")
    return violations


def proof_escape_scan() -> None:
    tracked = subprocess.run(
        ["git", "ls-files", "*.lean"], cwd=ROOT, check=True, text=True, capture_output=True
    ).stdout.splitlines()
    violations = find_proof_escapes([
        (name, (ROOT / name).read_text(encoding="utf-8")) for name in tracked
    ])
    require(not violations, "proof escape(s):\n" + "\n".join(violations))


def expect_failure(label: str, action: Callable[[], object], expected: str) -> None:
    try:
        action()
    except RegistryError as error:
        require(expected in str(error),
                f"{label}: wrong failure: expected {expected!r}, got {str(error)!r}")
    else:
        raise RegistryError(f"{label}: unexpectedly passed")


def require_fixture(name: str) -> Path:
    path = AUDIT / "fixtures" / name
    require(path.is_file(), f"negative fixture missing: audit/fixtures/{name}")
    return path


def write_mutant(data: object, suffix: str = ".json") -> Path:
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=suffix, encoding="utf-8", dir=AUDIT, delete=False
    ) as mutant_file:
        json.dump(data, mutant_file)
        return Path(mutant_file.name)


def negative_tests() -> None:
    invalid_entry = require_fixture("invalid-entry.yaml")
    expect_failure(
        "invalid registry fixture",
        lambda: validate(invalid_entry),
        "registry.invariants[0].layer: value is not in schema enum",
    )
    data = validate()
    mutant = json.loads(json.dumps(data))
    next(row for row in mutant["invariants"] if row["status"] == "PROVED")["theorem"] = "No.Such.Theorem"
    mutant_path = write_mutant(mutant)
    try:
        expect_failure(
            "nonexistent theorem mutant",
            lambda: validate(mutant_path),
            "registry theorem does not exist in LidoSRv3 build surface",
        )
    finally:
        mutant_path.unlink()
    regression_mutant = json.loads(json.dumps(data))
    next(row for row in regression_mutant["invariants"]
         if row["status"] == "REGRESSION")["theorem"] = "No.Such.RegressionTheorem"
    regression_path = write_mutant(regression_mutant)
    try:
        expect_failure(
            "nonexistent REGRESSION theorem mutant",
            lambda: validate(regression_path),
            "registry theorem does not exist in LidoSRv3 build surface",
        )
    finally:
        regression_path.unlink()
    artifact_cases = (
        ("empty-artifacts.json", "artifacts must be a nonempty array"),
        ("missing-required-artifact.json", "artifact inventory differs"),
    )
    for fixture, expected in artifact_cases:
        path = require_fixture(fixture)
        expect_failure(fixture, lambda path=path: validate_artifacts(path), expected)
    artifact_mutant = load_json(ARTIFACTS)
    artifact_mutant = json.loads(json.dumps(artifact_mutant))
    arithmetic = next(
        artifact for artifact in artifact_mutant["artifacts"]
        if artifact["id"] == "proof-arithmetic"
    )
    arithmetic["path"] = "LidoSRv3/Model.lean"
    arithmetic["trust"] = "REGRESSION"
    arithmetic["sha256"] = hashlib.sha256(
        (ROOT / arithmetic["path"]).read_bytes()
    ).hexdigest()
    artifact_path = write_mutant(artifact_mutant)
    try:
        expect_failure(
            "artifact identity binding mutant",
            lambda: validate_artifacts(artifact_path),
            "proof-arithmetic: path must be LidoSRv3/Audit/Arithmetic.lean",
        )
    finally:
        artifact_path.unlink()

    scanner_mutant = 'def bait := "escaped quote: \\\\\\" and /-"\naxiom hidden : True\n'
    violations = find_proof_escapes([("scanner-mutant.lean", scanner_mutant)])
    require(
        any(":2:axiom hidden : True" in violation for violation in violations),
        "scanner string-delimiter mutant: unexpectedly passed",
    )
    safe_strings = 'def safe := "sorry admit axiom unsafe /- -- \\\\\\""\n'
    require(
        not find_proof_escapes([("safe-strings.lean", safe_strings)]),
        "scanner safe-string fixture: unexpectedly rejected",
    )
    constant_mutant = "constant bogus : False\n"
    require(
        any(":1:constant bogus : False" in violation for violation in
            find_proof_escapes([("constant-mutant.lean", constant_mutant)])),
        "scanner constant-declaration mutant: unexpectedly passed",
    )

    strategy_mutant = load_json(ARTIFACTS)
    strategy_mutant = json.loads(json.dumps(strategy_mutant))
    strategy_model = next(
        artifact for artifact in strategy_mutant["artifacts"]
        if artifact["id"] == "proof-strategy-model"
    )
    strategy_model["sha256"] = "0" * 64
    strategy_path = write_mutant(strategy_mutant)
    try:
        expect_failure(
            "MinFirst model digest mutant",
            lambda: validate_artifacts(strategy_path),
            "proof-strategy-model: sha256 mismatch",
        )
    finally:
        strategy_path.unlink()

    schema = load_json(SCHEMA)
    decorative_schema = {"title": "x"}
    decorative_path = write_mutant(decorative_schema)
    try:
        expect_failure(
            "decorative schema mutant",
            lambda: validate(REGISTRY, decorative_path),
            "schema.json: registry root schema must be object",
        )
    finally:
        decorative_path.unlink()
    missing_required_schema = json.loads(json.dumps(schema))
    missing_required_schema["properties"]["invariants"]["items"]["required"].remove("status")
    missing_required_path = write_mutant(missing_required_schema)
    try:
        expect_failure(
            "schema required-field drift mutant",
            lambda: validate(REGISTRY, missing_required_path),
            "schema.json: invariant required must equal properties",
        )
    finally:
        missing_required_path.unlink()
    inverted_enum_schema = json.loads(json.dumps(schema))
    inverted_enum_schema["properties"]["invariants"]["items"]["properties"]["status"]["enum"] = ["DISPROVED"]
    inverted_enum_path = write_mutant(inverted_enum_schema)
    try:
        expect_failure(
            "schema enum drift mutant",
            lambda: validate(REGISTRY, inverted_enum_path),
            "registry.invariants[0].status: value is not in schema enum",
        )
    finally:
        inverted_enum_path.unlink()

    coverage_mutant = json.loads(json.dumps(data))
    coverage_mutant["invariants"][0]["status"] = "DISPROVED"
    coverage_schema = json.loads(json.dumps(schema))
    coverage_schema["properties"]["invariants"]["items"]["properties"]["status"]["enum"].append("DISPROVED")
    coverage_schema_path = write_mutant(coverage_schema)
    coverage_registry_path = write_mutant(coverage_mutant)
    try:
        coverage_data = validate(coverage_registry_path, coverage_schema_path)
        rendered(coverage_data, coverage_schema)
        incomplete = {
            "BY_STATUS.md": render_grouped(
                coverage_data, "status", "Invariants by status",
                schema_values(schema, "status"),
            )
        }
        expect_failure(
            "generated status coverage mutant",
            lambda: assert_render_coverage(
                coverage_data,
                {**rendered(data), **incomplete},
            ),
            "BY_STATUS.md: rendered ID coverage differs",
        )
    finally:
        coverage_registry_path.unlink()
        coverage_schema_path.unlink()

    with tempfile.TemporaryDirectory() as directory:
        stale = Path(directory) / "BY_STATUS.md"
        stale.write_text("stale\n", encoding="utf-8")
        expect_failure(
            "stale generated fixture",
            lambda: assert_fresh(stale, rendered(data)["BY_STATUS.md"], "negative fixture"),
            "stale generated view: negative fixture",
        )

    csv_mutant = dict(rendered(data))
    csv_mutant["MATRIX.csv"] = "# generated metadata\n" + csv_mutant["MATRIX.csv"]
    expect_failure(
        "comment-prefixed CSV mutant",
        lambda: assert_render_coverage(data, csv_mutant),
        "MATRIX.csv: invalid CSV header",
    )


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
