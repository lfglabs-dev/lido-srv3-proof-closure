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
EXTERNAL_TARGETS = AUDIT / "external-source-targets.json"
TARGET = AUDIT / "target-4.31"
TARGET_SOURCE = TARGET / "SOURCE.json"
TRUSTED_AXIOMS = AUDIT / "trusted-axioms.json"
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


def json_values_equal(left: object, right: object) -> bool:
    if type(left) is not type(right):
        return False
    if isinstance(left, list):
        return len(left) == len(right) and all(
            json_values_equal(left_item, right_item)
            for left_item, right_item in zip(left, right)
        )
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(
            json_values_equal(left[key], right[key]) for key in left
        )
    return left == right


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
        require(
            json_values_equal(value, schema["const"]),
            f"{location}: does not match schema const",
        )
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


def source_pins() -> dict[str, str]:
    lock = load_json(LOCK)
    require(isinstance(lock, dict), "dependencies.lock.json: root must be an object")
    pins = {}
    for component, key in (
        ("verity", "verity"),
        ("evmyullean", "evmyullean"),
        ("lido-core", "lido_core"),
    ):
        entry = lock.get(key)
        require(isinstance(entry, dict), f"dependencies.lock.json: missing {key}")
        commit = entry.get("commit")
        require(
            isinstance(commit, str) and re.fullmatch(r"[0-9a-f]{40}", commit) is not None,
            f"dependencies.lock.json: invalid {key} commit",
        )
        pins[component] = commit
    return pins


def source_repositories() -> dict[str, tuple[str, str | None]]:
    lock = load_json(LOCK)
    repositories = {}
    for component, key in (
        ("verity", "verity"),
        ("evmyullean", "evmyullean"),
        ("lido-core", "lido_core"),
    ):
        repository = lock[key].get("repository")
        require(
            isinstance(repository, str)
            and re.fullmatch(r"https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git",
                             repository) is not None,
            f"dependencies.lock.json: invalid {key} repository",
        )
        ref = lock[key].get("ref")
        require(ref is None or isinstance(ref, str),
                f"dependencies.lock.json: invalid {key} ref")
        repositories[component] = (repository, ref)
    return repositories


def resolve_git_targets(
    component: str, repository: str, pinned_ref: str | None, commit: str, targets: dict
) -> None:
    with tempfile.TemporaryDirectory() as directory:
        git_dir = Path(directory) / "inventory.git"
        init = subprocess.run(
            ["git", "init", "--bare", str(git_dir)], text=True, capture_output=True
        )
        require(init.returncode == 0, f"{component}: cannot initialize Git inventory")
        fetch = subprocess.run(
            ["git", "--git-dir", str(git_dir), "fetch", "--quiet", "--depth=1",
             repository, commit],
            text=True, capture_output=True,
        )
        require(
            fetch.returncode == 0,
            f"{component}: pinned commit is unavailable from trusted repository: "
            + (fetch.stderr or fetch.stdout).strip(),
        )
        fetched = subprocess.run(
            ["git", "--git-dir", str(git_dir), "rev-parse", "FETCH_HEAD^{commit}"],
            text=True, capture_output=True,
        )
        require(
            fetched.returncode == 0 and fetched.stdout.strip() == commit,
            f"{component}: fetched commit identity differs from dependency pin",
        )
        for target, identity in targets.items():
            if identity["kind"] == "ref":
                require(
                    target == pinned_ref
                    and commit == identity["object"],
                    f"external-source-targets.json: {component}:{target} ref identity "
                    "does not match pinned repository ref",
                )
                continue
            result = subprocess.run(
                ["git", "--git-dir", str(git_dir), "ls-tree", commit, "--", target],
                text=True, capture_output=True,
            )
            require(result.returncode == 0, f"{component}:{target}: Git lookup failed")
            fields = result.stdout.strip().split(maxsplit=3)
            expected_type = "blob" if identity["kind"] == "file" else "tree"
            require(
                len(fields) == 4
                and fields[1] == expected_type
                and fields[2] == identity["object"]
                and fields[3] == target,
                f"external-source-targets.json: {component}:{target} identity "
                "does not match pinned repository object",
            )


def external_source_targets(
    pins: dict[str, str], inventory_path: Path = EXTERNAL_TARGETS
) -> dict[str, set[str]]:
    inventory = load_json(inventory_path)
    require(
        isinstance(inventory, dict)
        and inventory.get("schema") == "external-source-target-inventory-v1",
        "external-source-targets.json: invalid schema",
    )
    components = inventory.get("components")
    require(
        isinstance(components, dict) and set(components) == set(pins),
        "external-source-targets.json: component inventory differs from dependency pins",
    )
    targets_by_component = {}
    repositories = source_repositories()
    for component, commit in pins.items():
        entry = components[component]
        require(
            isinstance(entry, dict) and set(entry) == {"commit", "targets"},
            f"external-source-targets.json: invalid {component} inventory",
        )
        require(
            entry["commit"] == commit,
            f"external-source-targets.json: {component} commit is not exactly pinned",
        )
        targets = entry["targets"]
        require(
            isinstance(targets, dict),
            f"external-source-targets.json: invalid {component} targets",
        )
        for target, identity in targets.items():
            require(
                isinstance(target, str)
                and target
                and not target.startswith("/")
                and ".." not in Path(target).parts
                and "//" not in target,
                f"external-source-targets.json: invalid {component} target",
            )
            require(
                isinstance(identity, dict)
                and set(identity) == {"kind", "object"}
                and identity["kind"] in {"file", "directory", "ref"}
                and isinstance(identity["object"], str)
                and re.fullmatch(r"[0-9a-f]{40}", identity["object"]) is not None,
                f"external-source-targets.json: invalid {component} target identity",
            )
        targets_by_component[component] = set(targets)
    return targets_by_component


def refresh_external_provenance(
    pins: dict[str, str], inventory_path: Path = EXTERNAL_TARGETS
) -> None:
    inventory = load_json(inventory_path)
    repositories = source_repositories()
    for component, commit in pins.items():
        repository, pinned_ref = repositories[component]
        resolve_git_targets(
            component, repository, pinned_ref, commit,
            inventory["components"][component]["targets"],
        )


def validate_source_inventory(path: Path = TARGET_SOURCE, online: bool = False) -> None:
    inventory = load_json(path)
    require(
        isinstance(inventory, dict)
        and set(inventory) == {"schema", "sources"}
        and inventory["schema"] == "immutable-git-source-inventory-v1"
        and isinstance(inventory["sources"], list)
        and inventory["sources"],
        "target SOURCE.json: invalid committed provenance",
    )
    expected_paths = {"lakefile.lean", "lake-manifest.json", "lean-toolchain"}
    seen = set()
    for source in inventory["sources"]:
        require(
            isinstance(source, dict)
            and set(source) == {"repository", "commit", "path", "blob", "sha256"},
            "target SOURCE.json: invalid source identity",
        )
        require(source["repository"] == "https://github.com/lfglabs-dev/verity.git",
                "target SOURCE.json: repository mismatch")
        require(source["commit"] == "68f560e66c5de6123061ce5ed60261be162673d1",
                "target SOURCE.json: commit mismatch")
        require(source["path"] in expected_paths and source["path"] not in seen,
                "target SOURCE.json: path mismatch")
        require(re.fullmatch(r"[0-9a-f]{40}", source["blob"]) is not None,
                "target SOURCE.json: blob mismatch")
        require(re.fullmatch(r"[0-9a-f]{64}", source["sha256"]) is not None,
                "target SOURCE.json: SHA-256 mismatch")
        seen.add(source["path"])
        if online:
            with tempfile.TemporaryDirectory() as directory:
                git_dir = Path(directory) / "source.git"
                subprocess.run(["git", "init", "--bare", str(git_dir)],
                               check=True, capture_output=True)
                fetch = subprocess.run(
                    ["git", "--git-dir", str(git_dir), "fetch", "--quiet", "--depth=1",
                     source["repository"], source["commit"]],
                    text=True, capture_output=True,
                )
                require(fetch.returncode == 0,
                        "target SOURCE.json: pinned commit unavailable")
                tree = subprocess.run(
                    ["git", "--git-dir", str(git_dir), "ls-tree", source["commit"],
                     "--", source["path"]],
                    text=True, capture_output=True,
                )
                fields = tree.stdout.strip().split(maxsplit=3)
                require(
                    tree.returncode == 0 and len(fields) == 4
                    and fields[1] == "blob" and fields[2] == source["blob"]
                    and fields[3] == source["path"],
                    "target SOURCE.json: remote blob identity mismatch",
                )
                content = subprocess.run(
                    ["git", "--git-dir", str(git_dir), "cat-file", "blob", source["blob"]],
                    capture_output=True,
                )
                require(
                    content.returncode == 0
                    and hashlib.sha256(content.stdout).hexdigest() == source["sha256"],
                    "target SOURCE.json: remote SHA-256 mismatch",
                )
    require(seen == expected_paths, "target SOURCE.json: missing committed provenance")


def validate_source_anchor(
    anchor: str, pins: dict[str, str], targets: dict[str, set[str]]
) -> None:
    external = re.fullmatch(
        r"([a-z][a-z0-9-]*)@([0-9a-f]{40})(?::([A-Za-z0-9._/-]+))?", anchor
    )
    if external is not None:
        component, commit, suffix = external.groups()
        require(component in pins, f"unknown external source component: {component}")
        require(
            commit == pins[component],
            f"external source anchor is not exactly pinned: {anchor}",
        )
        require(
            suffix is None or (
                not suffix.startswith("/")
                and ".." not in Path(suffix).parts
                and "//" not in suffix
            ),
            f"invalid external source anchor suffix: {anchor}",
        )
        require(
            suffix is None or suffix in targets[component],
            f"external source anchor target does not exist at pinned commit: {anchor}",
        )
        return
    path = (ROOT / anchor).resolve()
    require(
        path.is_relative_to(ROOT) and path.is_file(),
        f"local source anchor does not exist: {anchor}",
    )


def trusted_axioms() -> set[str]:
    policy = load_json(TRUSTED_AXIOMS)
    require(
        isinstance(policy, dict)
        and set(policy) == {"schema", "allowed"}
        and policy["schema"] == "lean-trusted-axioms-v1"
        and isinstance(policy["allowed"], list)
        and len(policy["allowed"]) == len(set(policy["allowed"]))
        and all(isinstance(name, str) and name for name in policy["allowed"]),
        "trusted-axioms.json: invalid explicit trust allowlist",
    )
    return set(policy["allowed"])


def parse_axiom_report(output: str, theorems: list[str]) -> dict[str, set[str]]:
    reports: dict[str, set[str]] = {}
    pattern = re.compile(
        r"'([^']+)' depends on axioms:\s*\[(.*?)\]", re.DOTALL
    )
    for theorem, body in pattern.findall(output):
        reports[theorem] = {
            name.strip() for name in body.split(",") if name.strip()
        }
    for theorem in theorems:
        if theorem not in reports:
            no_axioms = re.search(
                rf"'{re.escape(theorem)}' does not depend on any axioms", output
            )
            require(no_axioms is not None, f"missing #print axioms evidence for {theorem}")
            reports[theorem] = set()
    return reports


def run_theorem_checks(
    theorems: list[str], proved: list[str], declarations: str = ""
) -> None:
    source = (
        "import LidoSRv3\n"
        + declarations
        + "".join(f"#check {theorem}\n" for theorem in theorems)
        + "".join(f"#print axioms {theorem}\n" for theorem in proved)
    )
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".lean", encoding="utf-8", dir=ROOT, delete=False
    ) as check_file:
        check_file.write(source)
        check_path = Path(check_file.name)
    check_path.chmod(0o644)
    try:
        lean_sysroot = subprocess.run(
            ["lake", "env", "printenv", "LEAN_SYSROOT"],
            cwd=ROOT, text=True, capture_output=True,
        )
        lean_executable = Path(lean_sysroot.stdout.strip()) / "bin" / "lean"
        require(
            lean_sysroot.returncode == 0 and lean_executable.is_file(),
            "cannot resolve pinned Lean executable",
        )
        result = subprocess.run(
            ["lake", "env", str(lean_executable), str(check_path.relative_to(ROOT))],
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
    reports = parse_axiom_report(result.stdout + "\n" + result.stderr, proved)
    allowed = trusted_axioms()
    for theorem in proved:
        undeclared = reports[theorem] - allowed
        require(
            not undeclared,
            f"{theorem}: undeclared transitive axioms: {sorted(undeclared)}",
        )


def validate_theorems(data: dict) -> None:
    theorems = sorted(
        row["theorem"] for row in data["invariants"] if row["theorem"] is not None
    )
    proved = sorted(
        row["theorem"] for row in data["invariants"] if row["status"] == "PROVED"
    )
    for theorem in theorems:
        require(
            re.fullmatch(r"[A-Za-z_][A-Za-z0-9_']*(?:\.[A-Za-z_][A-Za-z0-9_']*)+", theorem) is not None,
            f"invalid fully qualified theorem name: {theorem}",
        )
    build = subprocess.run(
        ["lake", "build", "LidoSRv3"], cwd=ROOT, text=True, capture_output=True
    )
    require(
        build.returncode == 0,
        "cannot build LidoSRv3 theorem surface:\n"
        + (build.stderr or build.stdout).strip(),
    )
    run_theorem_checks(theorems, proved)


def validate(path: Path = REGISTRY, schema_path: Path = SCHEMA) -> dict:
    data = load_json(path)
    schema = validate_schema_definition(load_json(schema_path))
    validate_against_schema(data, schema)
    layers = schema_values(schema, "layer")
    pins = source_pins()
    targets = external_source_targets(pins)

    ids: set[str] = set()
    theorem_owners: dict[str, str] = {}
    for row in data["invariants"]:
        invariant_id = row["id"]
        require(invariant_id not in ids, f"duplicate id: {invariant_id}")
        ids.add(invariant_id)
        for name in ("source_anchors", "runtime_anchors", "assumptions", "trust_boundary", "dependencies"):
            value = row[name]
            require(len(value) == len(set(value)), f"{invariant_id}: duplicate {name}")
        for anchor in row["source_anchors"]:
            validate_source_anchor(anchor, pins, targets)
        theorem = row["theorem"]
        if theorem is not None:
            require(theorem not in theorem_owners, f"theorem {theorem} duplicated by {theorem_owners.get(theorem)}")
            theorem_owners[theorem] = invariant_id
        if row["status"] == "PROVED":
            require(theorem is not None, f"{invariant_id}: PROVED requires theorem")
        if row["layer"] in set(layers) & {"EVM", "E2E"} and row["status"] in {"PROVED", "REGRESSION"}:
            require(
                any(not anchor.startswith("MISSING:") for anchor in row["runtime_anchors"]),
                f"{invariant_id}: runtime assurance requires non-missing anchors",
            )

    rows = {row["id"]: row for row in data["invariants"]}
    graph = {row_id: row["dependencies"] for row_id, row in rows.items()}
    for node, dependencies in graph.items():
        for dependency in dependencies:
            require(dependency in graph, f"{node}: unknown dependency {dependency}")
            require(dependency != node, f"{node}: self dependency")
            if rows[node]["status"] in {"PROVED", "REGRESSION"}:
                require(
                    rows[dependency]["status"] in {"PROVED", "REGRESSION"},
                    f"{node}: assured status {rows[node]['status']} requires assured "
                    f"dependency {dependency}, got {rows[dependency]['status']}",
                )
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
    require(lock["target_root"]["direct_dependencies"] == ["verity"],
            "target root must depend exactly once on Verity")
    require("transitive" in lock["evmyullean"]["resolution"], "EVMYulLean must be transitive")
    require(
        lock["target_root"]["status"] == "DEV-431-READY"
        and lock["target_root"]["print_axioms"] == "FAIL"
        and lock["target_root"]["audit_cert"] is False,
        "target status must be DEV-431-READY, PrintAxioms FAIL, AUDIT-CERT=false",
    )


def dependency_entries(manifest: object, label: str) -> list[dict]:
    require(isinstance(manifest, dict) and isinstance(manifest.get("packages"), list),
            f"{label}: packages must be an array")
    entries = manifest["packages"]
    require(all(isinstance(entry, dict) for entry in entries),
            f"{label}: package entries must be objects")
    names = [entry.get("name") for entry in entries]
    require(len(names) == len(set(names)), f"{label}: duplicate package instances")
    return entries


def require_package(
    entries: list[dict], label: str, name: str, url: str, rev: str, inherited: bool
) -> dict:
    matches = [entry for entry in entries if entry.get("name") == name]
    require(len(matches) == 1, f"{label}: expected exactly one {name} package")
    entry = matches[0]
    require(entry.get("url") == url, f"{label}: {name} URL mismatch")
    require(entry.get("rev") == rev, f"{label}: {name} rev mismatch")
    require(entry.get("inputRev") == rev, f"{label}: {name} inputRev mismatch")
    require(entry.get("inherited") is inherited, f"{label}: {name} inherited mismatch")
    return entry


def validate_dependency_planes(
    root_lakefile: Path = ROOT / "lakefile.lean",
    root_manifest: Path = ROOT / "lake-manifest.json",
    root_toolchain: Path = ROOT / "lean-toolchain",
    target_lakefile: Path = TARGET / "lakefile.lean",
    target_manifest: Path = TARGET / "lake-manifest.json",
    target_toolchain: Path = TARGET / "lean-toolchain",
    verity_metadata: Path = TARGET / "verity.json",
) -> None:
    lock = load_json(LOCK)
    current = lock["current_root"]
    require(root_toolchain.read_text(encoding="utf-8").strip() == current["lean_toolchain"],
            "current plane: Lean toolchain mismatch")
    current_lake = root_lakefile.read_text(encoding="utf-8")
    require(current_lake.count("require verity from git") == 1,
            "current plane: expected exactly one direct Verity")
    require("require evmyul" not in current_lake.lower(),
            "current plane: direct EVMYulLean forbidden")
    require(current["verity"] in current_lake, "current plane: Verity lakefile pin mismatch")
    current_entries = dependency_entries(load_json(root_manifest), "current plane")
    require_package(current_entries, "current plane", "verity",
                    "https://github.com/lfglabs-dev/verity.git",
                    current["verity"], False)
    require_package(current_entries, "current plane", "evmyul",
                    "https://github.com/lfglabs-dev/EVMYulLean.git",
                    current["evmyullean"], True)

    target = lock["target_root"]
    require(target["plane"] == "audit-only" and target["path"] == "audit/target-4.31",
            "target plane must remain audit-only")
    require(target_toolchain.read_text(encoding="utf-8").strip() == target["lean_toolchain"],
            "target plane: Lean toolchain mismatch")
    target_lake = target_lakefile.read_text(encoding="utf-8")
    require(target_lake.count("require verity from git") == 1,
            "target plane: expected exactly one direct Verity")
    require("require evmyul" not in target_lake.lower(),
            "target plane: direct EVMYulLean forbidden")
    require(lock["verity"]["commit"] in target_lake,
            "target plane: Verity lakefile pin mismatch")
    target_entries = dependency_entries(load_json(target_manifest), "target plane")
    require_package(target_entries, "target plane", "verity",
                    lock["verity"]["repository"], lock["verity"]["commit"], False)
    require_package(target_entries, "target plane", "evmyul",
                    lock["evmyullean"]["repository"], lock["evmyullean"]["commit"], True)
    verity = load_json(verity_metadata)
    require(verity["commit"] == lock["verity"]["commit"],
            "target plane: Verity metadata commit mismatch")
    require(verity["lean_toolchain"] == target["lean_toolchain"],
            "target plane: Verity toolchain mismatch")
    deps = verity["direct_dependencies"]
    require(isinstance(deps, list) and len(deps) == 1 and deps[0]["name"] == "evmyul",
            "target plane: Verity must have sole inherited EVMYulLean")
    require(
        deps[0]["url"] == lock["evmyullean"]["repository"]
        and deps[0]["rev"] == lock["evmyullean"]["commit"]
        and deps[0]["inputRev"] == lock["evmyullean"]["commit"],
        "target plane: Verity EVMYulLean metadata mismatch",
    )
    receipt = verity["print_axioms"]
    require(
        receipt["status"] == "FAIL" and receipt["audit_cert"] is False
        and receipt["command"] and receipt["location"],
        "target plane: AUDIT-CERT requires passing PrintAxioms evidence",
    )
    validate_source_inventory()


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
    patterns = re.compile(
        r"(?<![\w'])(sorryAx|sorry|admit|axiom|constant|unsafe|native_decide|"
        r"implemented_by|extern)(?![\w'])"
    )
    violations = []
    interpolated_prefix = re.compile(
        r"(?:[sfmv]!|Macro\.trace\[[^\]]*\]|trace(?:_goal)?\[[^\]]*\]|println!|"
        r"throwError|throwErrorAt\b.+|report(?:Dbg|EMatch)?Issue!)\s*$"
    )
    for name, source in sources:
        block_depth = 0
        contexts: list[tuple[str, object]] = [("code", None)]
        sanitized_lines = []
        for number, line in enumerate(source.splitlines(), 1):
            code_parts = []
            cursor = 0
            while cursor < len(line):
                context, state = contexts[-1]
                if context == "raw":
                    raw_hashes = int(state)
                    terminator = '"' + "#" * raw_hashes
                    end = line.find(terminator, cursor)
                    if end == -1:
                        cursor = len(line)
                    else:
                        contexts.pop()
                        cursor = end + len(terminator)
                elif context == "string":
                    interpolated, escaped = state
                    character = line[cursor]
                    if escaped:
                        contexts[-1] = ("string", (interpolated, False))
                    elif character == "\\":
                        contexts[-1] = ("string", (interpolated, True))
                    elif interpolated and character == "{":
                        contexts.append(("interpolation", 1))
                        code_parts.append(" ")
                    elif character == '"':
                        contexts.pop()
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
                elif context == "interpolation" and line[cursor] == "{":
                    contexts[-1] = ("interpolation", int(state) + 1)
                    code_parts.append("{")
                    cursor += 1
                elif context == "interpolation" and line[cursor] == "}":
                    if int(state) == 1:
                        contexts.pop()
                        code_parts.append(" ")
                    else:
                        contexts[-1] = ("interpolation", int(state) - 1)
                        code_parts.append("}")
                    cursor += 1
                elif line[cursor] == "r":
                    delimiter = cursor + 1
                    while delimiter < len(line) and line[delimiter] == "#":
                        delimiter += 1
                    if delimiter < len(line) and line[delimiter] == '"':
                        contexts.append(("raw", delimiter - cursor - 1))
                        cursor = delimiter + 1
                    else:
                        code_parts.append(line[cursor])
                        cursor += 1
                elif line[cursor] == "'":
                    end = cursor + 1
                    if end < len(line) and line[end] == "\\":
                        end += 2
                    else:
                        end += 1
                    if end < len(line) and line[end] == "'":
                        cursor = end + 1
                    else:
                        code_parts.append(line[cursor])
                        cursor += 1
                elif line[cursor] == '"' and interpolated_prefix.search(line[:cursor]):
                    code_parts.append("!")
                    contexts.append(("string", (True, False)))
                    cursor += 1
                elif line[cursor] == '"':
                    contexts.append(("string", (False, False)))
                    cursor += 1
                else:
                    code_parts.append(line[cursor])
                    cursor += 1
            if contexts[-1][0] == "string":
                interpolated, _ = contexts[-1][1]
                contexts[-1] = ("string", (interpolated, False))
            code = "".join(code_parts)
            sanitized_lines.append(code)
            if patterns.search(code):
                violations.append(f"{name}:{number}:{line.strip()}")
        sanitized = "\n".join(sanitized_lines)
        opaque_start = re.compile(
            r"(?m)^[ \t]*(?:@\[[^\n]*\][ \t]*)*"
            r"(?:(?:private|protected)[ \t]+)*opaque[ \t]+"
        )
        declaration_start = re.compile(
            r"(?m)^[ \t]*(?:@\[[^\n]*\][ \t]*)*"
            r"(?:(?:private|protected)[ \t]+)*"
            r"(?:opaque|def|theorem|lemma|axiom|constant|inductive|structure|class|instance)\b"
        )
        opaque_matches = list(opaque_start.finditer(sanitized))
        for match in opaque_matches:
            following = declaration_start.search(sanitized, match.end())
            end = following.start() if following is not None else len(sanitized)
            declaration = sanitized[match.start():end]
            if ":=" not in declaration and re.search(r"(?m)^[ \t]*where\b", declaration) is None:
                line_number = sanitized.count("\n", 0, match.start()) + 1
                original = source.splitlines()[line_number - 1].strip()
                violations.append(f"{name}:{line_number}:{original}")
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
        print(f"mutant rejected: {label}")
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


def write_text_mutant(text: str, suffix: str) -> Path:
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=suffix, encoding="utf-8", dir=AUDIT, delete=False
    ) as mutant_file:
        mutant_file.write(text)
        return Path(mutant_file.name)


def negative_tests() -> None:
    invalid_entry = require_fixture("invalid-entry.yaml")
    expect_failure(
        "invalid registry fixture",
        lambda: validate(invalid_entry),
        "registry.invariants[0].layer: value is not in schema enum",
    )
    data = validate()
    pins = source_pins()
    targets = external_source_targets(pins)
    source_anchor_positive = load_json(require_fixture("source-anchors-safe-positive.json"))
    for anchor in source_anchor_positive:
        validate_source_anchor(anchor, pins, targets)
    for fixture, expected in (
        ("nonexistent-local-anchor-negative.json", "local source anchor does not exist"),
        ("invalid-external-anchor-negative.json", "external source anchor is not exactly pinned"),
        ("nonexistent-external-anchor-negative.json",
         "external source anchor target does not exist at pinned commit"),
        ("mistyped-external-anchor-negative.json",
         "external source anchor target does not exist at pinned commit"),
    ):
        anchor = load_json(require_fixture(fixture))
        expect_failure(
            fixture,
            lambda anchor=anchor: validate_source_anchor(anchor, pins, targets),
            expected,
        )
    const_negative = load_json(require_fixture("const-one-negative.json"))
    expect_failure(
        "boolean schema const fixture",
        lambda: validate_against_schema(const_negative, {"const": 1}, "fixture"),
        "fixture: does not match schema const",
    )
    const_positive = load_json(require_fixture("const-one-safe-positive.json"))
    validate_against_schema(const_positive, {"const": 1}, "fixture")
    for unresolved_status in ("BLOCKED", "STRETCH"):
        dependency_mutant = json.loads(json.dumps(data))
        next(
            row for row in dependency_mutant["invariants"]
            if row["id"] == "SRV3-ARITH-CHECKED"
        )["status"] = unresolved_status
        dependency_path = write_mutant(dependency_mutant)
        try:
            expect_failure(
                f"assured dependency {unresolved_status} mutant",
                lambda dependency_path=dependency_path: validate(dependency_path),
                "SRV3-TX-REVERT: assured status PROVED requires assured dependency "
                f"SRV3-ARITH-CHECKED, got {unresolved_status}",
            )
        finally:
            dependency_path.unlink()
    for assured_status in ("REGRESSION", "PROVED"):
        runtime_mutant = json.loads(json.dumps(data))
        runtime_row = next(
            row for row in runtime_mutant["invariants"]
            if row["id"] == "SRV3-EVM-RUNTIME"
        )
        runtime_row["status"] = assured_status
        if assured_status == "PROVED":
            theorem_row = next(
                row for row in runtime_mutant["invariants"]
                if row["theorem"] == "LidoSRv3.P1_reserve_separation"
            )
            theorem_row["status"] = "REGRESSION"
            theorem_row["theorem"] = None
            runtime_row["theorem"] = "LidoSRv3.P1_reserve_separation"
        runtime_path = write_mutant(runtime_mutant)
        try:
            expect_failure(
                f"sentinel-only runtime {assured_status} mutant",
                lambda runtime_path=runtime_path: validate(runtime_path),
                "SRV3-EVM-RUNTIME: runtime assurance requires non-missing anchors",
            )
        finally:
            runtime_path.unlink()
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
    literal_mutants = (
        ("character", "def quote : Char := '\\\"'\naxiom hidden : True\n"),
        ("raw string", 'def raw := r#"sorry /- \\""#\nunsafe def hidden := 0\n'),
        ("multi-hash raw string", 'def raw := r##"constant -- \\""##\nsorry\n'),
    )
    for label, source in literal_mutants:
        require(
            any(":2:" in violation for violation in
                find_proof_escapes([(f"{label}-mutant.lean", source)])),
            f"scanner {label} mutant: unexpectedly passed",
        )
    safe_literals = (
        "def quote : Char := '\\\"'\n"
        "def apostrophe : Char := '\\''\n"
        'def raw := r#"sorry admit axiom constant unsafe /- -- \\""#\n'
        'def rawHashes := r##"sorry \\"# still raw"##\n'
    )
    require(
        not find_proof_escapes([("safe-literals.lean", safe_literals)]),
        "scanner safe-literal fixture: unexpectedly rejected",
    )
    constant_mutant = "constant bogus : False\n"
    require(
        any(":1:constant bogus : False" in violation for violation in
            find_proof_escapes([("constant-mutant.lean", constant_mutant)])),
        "scanner constant-declaration mutant: unexpectedly passed",
    )
    sorryax_mutant = require_fixture("sorryax-negative.txt")
    require(
        any(":1:theorem bogus : False := sorryAx False true" in violation
            for violation in find_proof_escapes([
                (sorryax_mutant.name, sorryax_mutant.read_text(encoding="utf-8"))
            ])),
        "scanner sorryAx fixture: unexpectedly passed",
    )
    safe_scanner = require_fixture("proof-escape-safe-positive.txt")
    require(
        not find_proof_escapes([
            (safe_scanner.name, safe_scanner.read_text(encoding="utf-8"))
        ]),
        "scanner safe-positive fixture: unexpectedly rejected",
    )
    interpolation_mutant = require_fixture("interpolation-negative.txt")
    require(
        any(":1:" in violation for violation in find_proof_escapes([
            (interpolation_mutant.name, interpolation_mutant.read_text(encoding="utf-8"))
        ])),
        "scanner interpolation fixture: unexpectedly passed",
    )
    print("mutant rejected: direct interpolated-string proof escape")
    nested_interpolation_mutant = require_fixture("interpolation-nested-negative.txt")
    require(
        len(find_proof_escapes([
            (nested_interpolation_mutant.name,
             nested_interpolation_mutant.read_text(encoding="utf-8"))
        ])) == 2,
        "scanner direct/nested interpolation fixture: expected both escapes rejected",
    )
    print("mutant rejected: direct/nested interpolated-string proof escapes")
    interpolation_safe = require_fixture("interpolation-safe-positive.txt")
    require(
        not find_proof_escapes([
            (interpolation_safe.name, interpolation_safe.read_text(encoding="utf-8"))
        ]),
        "scanner interpolation safe-positive fixture: unexpectedly rejected",
    )
    interpolation_forms = require_fixture("interpolation-forms-negative.txt")
    form_violations = find_proof_escapes([
        (interpolation_forms.name, interpolation_forms.read_text(encoding="utf-8"))
    ])
    require(
        len(form_violations) == 13,
        "scanner interpolated forms fixture: expected all forms to be rejected",
    )
    interpolation_forms_safe = require_fixture("interpolation-forms-safe-positive.txt")
    require(
        not find_proof_escapes([
            (interpolation_forms_safe.name,
             interpolation_forms_safe.read_text(encoding="utf-8"))
        ]),
        "scanner interpolated forms safe-positive fixture: unexpectedly rejected",
    )
    bodyless_opaque = (
        '@[extern "bad"]\nprivate protected opaque\n'
        '  bad :\n  False\n'
    )
    require(
        find_proof_escapes([("bodyless-opaque.lean", bodyless_opaque)]),
        "scanner bodyless attributed/multiline/private/protected opaque mutant passed",
    )
    legitimate_opaque = "private opaque good (n : Nat) : Nat := n + 1\n"
    require(
        not find_proof_escapes([("opaque-body.lean", legitimate_opaque)]),
        "scanner legitimate opaque body was rejected",
    )

    current_lake = (ROOT / "lakefile.lean").read_text(encoding="utf-8")
    target_lake = (TARGET / "lakefile.lean").read_text(encoding="utf-8")
    for label, base, is_target in (
        ("current direct EVMYulLean", current_lake, False),
        ("target direct EVMYulLean", target_lake, True),
    ):
        path = write_text_mutant(
            base + '\nrequire evmyul from git "https://github.com/lfglabs-dev/EVMYulLean.git"@'
            '"f7e4ee0dc8f8d5265ce822a937ab5be771f182e9"\n',
            ".lean",
        )
        try:
            kwargs = {"target_lakefile": path} if is_target else {"root_lakefile": path}
            expect_failure(label, lambda kwargs=kwargs: validate_dependency_planes(**kwargs),
                           "direct EVMYulLean forbidden")
        finally:
            path.unlink()
    for count, replacement in (
        (0, target_lake.replace("require verity from git", "-- removed")),
        (2, target_lake + "\nrequire verity from git\n  "
         '"https://github.com/lfglabs-dev/verity.git"@'
         '"68f560e66c5de6123061ce5ed60261be162673d1"\n'),
    ):
        path = write_text_mutant(replacement, ".lean")
        try:
            expect_failure(f"target {count} Verity mutant",
                           lambda path=path: validate_dependency_planes(target_lakefile=path),
                           "expected exactly one direct Verity")
        finally:
            path.unlink()
    target_manifest_data = load_json(TARGET / "lake-manifest.json")
    manifest_mutants = []
    duplicate = json.loads(json.dumps(target_manifest_data))
    duplicate["packages"].append(json.loads(json.dumps(duplicate["packages"][0])))
    manifest_mutants.append(("duplicate package instances", duplicate,
                             "duplicate package instances"))
    for field, value, expected in (
        ("rev", "0" * 40, "verity rev mismatch"),
        ("inputRev", "0" * 40, "verity inputRev mismatch"),
        ("url", "https://example.invalid/verity.git", "verity URL mismatch"),
        ("inherited", True, "verity inherited mismatch"),
    ):
        mutant = json.loads(json.dumps(target_manifest_data))
        next(p for p in mutant["packages"] if p["name"] == "verity")[field] = value
        manifest_mutants.append((f"target wrong Verity {field}", mutant, expected))
    for label, mutant, expected in manifest_mutants:
        path = write_mutant(mutant)
        try:
            expect_failure(label,
                           lambda path=path: validate_dependency_planes(target_manifest=path),
                           expected)
        finally:
            path.unlink()
    source_mutant = load_json(TARGET_SOURCE)
    source_mutant = json.loads(json.dumps(source_mutant))
    source_mutant["sources"][0]["commit"] = "0" * 40
    source_path = write_mutant(source_mutant)
    try:
        expect_failure("snapshot identity mismatch",
                       lambda: validate_source_inventory(source_path),
                       "commit mismatch")
    finally:
        source_path.unlink()
    missing_source = load_json(TARGET_SOURCE)
    missing_source = json.loads(json.dumps(missing_source))
    missing_source["sources"].pop()
    missing_source_path = write_mutant(missing_source)
    try:
        expect_failure("missing committed provenance",
                       lambda: validate_source_inventory(missing_source_path),
                       "missing committed provenance")
    finally:
        missing_source_path.unlink()
    receipt_mutant = load_json(TARGET / "verity.json")
    receipt_mutant = json.loads(json.dumps(receipt_mutant))
    receipt_mutant["print_axioms"]["audit_cert"] = True
    receipt_path = write_mutant(receipt_mutant)
    try:
        expect_failure("AUDIT-CERT with failing PrintAxioms",
                       lambda: validate_dependency_planes(verity_metadata=receipt_path),
                       "AUDIT-CERT requires passing PrintAxioms evidence")
    finally:
        receipt_path.unlink()

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


def refresh_negative_tests() -> None:
    pins = source_pins()
    fabricated_inventory = load_json(EXTERNAL_TARGETS)
    fabricated_inventory = json.loads(json.dumps(fabricated_inventory))
    fabricated_inventory["components"]["lido-core"]["targets"][
        "contracts/0.8.25/sr/Fabricated.sol"
    ] = {"kind": "file", "object": "f" * 40}
    path = write_mutant(fabricated_inventory)
    try:
        expect_failure(
            "refresh fabricated external path/blob",
            lambda: refresh_external_provenance(pins, path),
            "identity does not match pinned repository object",
        )
    finally:
        path.unlink()
    for label, field, value, expected in (
        ("refresh fabricated commit", "commit", "0" * 40, "commit mismatch"),
        ("refresh fabricated path", "path", "Fabricated.lean", "path mismatch"),
        ("refresh fabricated blob", "blob", "f" * 40, "remote blob identity mismatch"),
    ):
        mutant = load_json(TARGET_SOURCE)
        mutant = json.loads(json.dumps(mutant))
        mutant["sources"][0][field] = value
        path = write_mutant(mutant)
        try:
            expect_failure(
                label, lambda path=path: validate_source_inventory(path, online=True), expected
            )
        finally:
            path.unlink()


def check() -> None:
    data = validate()
    validate_lock()
    validate_dependency_planes()
    validate_artifacts()
    check_fresh(data)
    proof_escape_scan()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "command", choices=(
            "check", "check-lean", "generate", "test-negative",
            "refresh-provenance", "test-refresh-negative"
        )
    )
    args = parser.parse_args()
    try:
        if args.command == "refresh-provenance":
            pins = source_pins()
            external_source_targets(pins)
            refresh_external_provenance(pins)
            validate_source_inventory(online=True)
        elif args.command == "test-refresh-negative":
            refresh_negative_tests()
        elif args.command == "check-lean":
            validate_theorems(validate())
        elif args.command == "generate":
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
