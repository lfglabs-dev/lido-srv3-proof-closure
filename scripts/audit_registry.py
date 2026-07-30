#!/usr/bin/env python3
"""Validate and deterministically render the SRv3 audit-control registry."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import io
import json
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass
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
EXPECTED_ARTIFACT_TRUST_LEVELS = {
    "AUDIT-CERT": (
        "Certified evidence with all declared correspondence and trust "
        "obligations closed."
    ),
    "DEV-431-READY": (
        "Development scaffold pinned for future Lean 4.31 work; never "
        "certification."
    ),
    "LEAN-CHECKED": "Kernel-checked theorem at the declared model layer only.",
    "REGRESSION": (
        "Legacy or fixture evidence retained to detect change; not "
        "correspondence or deployment assurance."
    ),
    "PROVENANCE-BLOCKED": (
        "Required canonical source/runtime identity evidence is absent."
    ),
}
EXPECTED_INVARIANT_THEOREMS = {
    "SRV3-LEGACY-ECON": "LidoSRv3.P1_reserve_separation",
    "SRV3-ARITH-CHECKED": "LidoSRv3.Audit.Quantity.checkedDiv_zero",
    "SRV3-TX-REVERT": "LidoSRv3.Audit.revert_restores_state_value_and_logs",
    "SRV3-ALLOC-ORDER": "LidoSRv3.Audit.valid_result_preserves_router_order",
    "SRV3-MINFIRST-BOUND": "LidoSRv3.Audit.MinFirst.totalAllocated_le_requested",
}
EXPECTED_INVARIANT_SOURCE_ANCHORS = {
    "SRV3-LEGACY-ECON": {
        "LidoSRv3/Model.lean",
        "LidoSRv3/SpecProofs.lean",
        "verity/targets/source-map.json",
    },
    "SRV3-ARITH-CHECKED": {"LidoSRv3/Audit/Arithmetic.lean"},
    "SRV3-TX-REVERT": {"LidoSRv3/Audit/Trace.lean"},
    "SRV3-ALLOC-ORDER": {"LidoSRv3/Audit/Allocation.lean"},
    "SRV3-MINFIRST-BOUND": {
        "LidoSRv3/Audit/Strategy.lean",
        "LidoSRv3/Audit/StrategyProofs.lean",
        "LidoSRv3/Audit/Vectors.lean",
    },
    "SRV3-SOLIDITY-CORR": {
        "lido-core@af095e48bbc1c3841c2c9936219c8461af01056b:"
        "contracts/0.8.25/sr/StakingRouter.sol",
        "verity/targets/solidity-correspondence.md",
    },
    "SRV3-VERITY-431": {
        "verity@68f560e66c5de6123061ce5ed60261be162673d1:"
        "dev/lean-4.31-scaffolding",
    },
    "SRV3-YUL-COMP": {
        "evmyullean@f7e4ee0dc8f8d5265ce822a937ab5be771f182e9",
    },
    "SRV3-EVM-RUNTIME": {
        "lido-core@af095e48bbc1c3841c2c9936219c8461af01056b",
    },
    "SRV3-SHA256-PRECOMPILE": {
        "evmyullean@f7e4ee0dc8f8d5265ce822a937ab5be771f182e9",
    },
    "SRV3-CONSOLIDATION-E2E": {
        "lido-core@af095e48bbc1c3841c2c9936219c8461af01056b",
    },
}
EXPECTED_INVARIANT_RUNTIME_ANCHORS = {
    "SRV3-LEGACY-ECON": set(),
    "SRV3-ARITH-CHECKED": set(),
    "SRV3-TX-REVERT": set(),
    "SRV3-ALLOC-ORDER": set(),
    "SRV3-MINFIRST-BOUND": set(),
    "SRV3-SOLIDITY-CORR": set(),
    "SRV3-VERITY-431": set(),
    "SRV3-YUL-COMP": set(),
    "SRV3-EVM-RUNTIME": {
        "MISSING: independently sourced canonical EIP-7251 production "
        "consolidation runtime/hash/address/fork provenance",
    },
    "SRV3-SHA256-PRECOMPILE": {"EVM SHA-256 precompile"},
    "SRV3-CONSOLIDATION-E2E": {
        "MISSING: canonical EIP-7251 production "
        "consolidation runtime/hash/address/fork provenance",
    },
}
EXPECTED_INVARIANT_FAMILIES = {
    "SRV3-LEGACY-ECON": "economic-accounting",
    "SRV3-ARITH-CHECKED": "checked-arithmetic",
    "SRV3-TX-REVERT": "transaction-semantics",
    "SRV3-ALLOC-ORDER": "allocation",
    "SRV3-MINFIRST-BOUND": "allocation",
    "SRV3-SOLIDITY-CORR": "source-correspondence",
    "SRV3-VERITY-431": "toolchain-readiness",
    "SRV3-YUL-COMP": "yul-interface",
    "SRV3-EVM-RUNTIME": "runtime-correspondence",
    "SRV3-SHA256-PRECOMPILE": "cryptography",
    "SRV3-CONSOLIDATION-E2E": "consolidation",
}
EXPECTED_INVARIANT_LIMITATIONS = {
    "SRV3-LEGACY-ECON": (
        {"Legacy pure model is not a Solidity or deployed-bytecode correspondence proof."},
        {"Lean 4.24 kernel", "Pinned Verity dependency", "Manual source mapping"},
    ),
    "SRV3-ARITH-CHECKED": (
        {"Quantity bounds and units are model inputs; Solidity correspondence remains unproved."},
        {"Lean 4.24 kernel", "Pinned Verity dependency"},
    ),
    "SRV3-TX-REVERT": (
        {"TxObservation is an abstract transaction model, not an EVM execution trace."},
        {"Lean 4.24 kernel", "Abstract trace model"},
    ),
    "SRV3-ALLOC-ORDER": (
        {"Allocation inputs are source-shaped data, not extracted Solidity state."},
        {"Lean 4.24 kernel", "Manual source correspondence"},
    ),
    "SRV3-MINFIRST-BOUND": (
        {"The handwritten MinFirst model has no established Solidity/EVM equivalence in M0."},
        {"Lean 4.24 kernel", "Handwritten algorithm model"},
    ),
    "SRV3-SOLIDITY-CORR": (
        {
            "Verity 4.31 is a non-certified development scaffold.",
            "Verity applies only to applicable Solidity/model components.",
        },
        {
            "Future Verity source translation",
            "Compiler/source provenance",
            "Manual interface composition for non-Solidity components",
        },
    ),
    "SRV3-VERITY-431": (
        {
            "Pinned target is explicitly non-certified and is not used by this "
            "Lean 4.24 M0 branch."
        },
        {"Development scaffold", "Future Lean 4.31 migration"},
    ),
    "SRV3-YUL-COMP": (
        {"Handwritten Yul/direct bytecode must not receive a fabricated Verity projection."},
        {"EVMYulLean Yul semantics", "Explicit Solidity/Yul interface composition"},
    ),
    "SRV3-EVM-RUNTIME": (
        {
            "Current consolidation helper uses a Mock build and cannot establish "
            "production runtime identity."
        },
        {
            "Canonical bytecode acquisition",
            "Fork configuration",
            "Address and code-hash provenance",
        },
    ),
    "SRV3-SHA256-PRECOMPILE": (
        {"SHA-256 precompile hashing currently relies on opaque native FFI."},
        {"Native FFI implementation", "Host SHA-256 library", "Precompile specification"},
    ),
    "SRV3-CONSOLIDATION-E2E": (
        {"Mock-derived helper evidence is non-production evidence."},
        {
            "Solidity/Yul interface composition",
            "EVM execution",
            "Canonical production deployment provenance",
        },
    ),
}
EXPECTED_INVARIANT_CLASSIFICATIONS = {
    "SRV3-LEGACY-ECON": ("P0", "REGRESSION", "LEAN", "MODEL"),
    "SRV3-ARITH-CHECKED": ("P0", "PROVED", "LEAN", "ALG"),
    "SRV3-TX-REVERT": ("P0", "PROVED", "LEAN", "TX"),
    "SRV3-ALLOC-ORDER": ("P0", "PROVED", "LEAN", "REL"),
    "SRV3-MINFIRST-BOUND": ("P0", "PROVED", "LEAN", "ALG"),
    "SRV3-SOLIDITY-CORR": ("P0", "OPEN", "VERITY", "SRC"),
    "SRV3-VERITY-431": ("P1", "DEV-431-READY", "VERITY", "SRC"),
    "SRV3-YUL-COMP": ("P1", "OPEN", "EVMYULLEAN", "YUL"),
    "SRV3-EVM-RUNTIME": ("P0", "BLOCKED", "EVMYULLEAN", "EVM"),
    "SRV3-SHA256-PRECOMPILE": ("STRETCH", "STRETCH", "NATIVE-FFI", "CRYPTO"),
    "SRV3-CONSOLIDATION-E2E": ("P0", "BLOCKED", "INTERFACE", "E2E"),
}
EXPECTED_INVARIANT_DEPENDENCIES = {
    "SRV3-LEGACY-ECON": set(),
    "SRV3-ARITH-CHECKED": set(),
    "SRV3-TX-REVERT": {"SRV3-ARITH-CHECKED"},
    "SRV3-ALLOC-ORDER": {"SRV3-ARITH-CHECKED"},
    "SRV3-MINFIRST-BOUND": {"SRV3-ALLOC-ORDER"},
    "SRV3-SOLIDITY-CORR": {"SRV3-LEGACY-ECON", "SRV3-MINFIRST-BOUND"},
    "SRV3-VERITY-431": set(),
    "SRV3-YUL-COMP": {"SRV3-VERITY-431"},
    "SRV3-EVM-RUNTIME": {"SRV3-YUL-COMP", "SRV3-SOLIDITY-CORR"},
    "SRV3-SHA256-PRECOMPILE": {"SRV3-YUL-COMP"},
    "SRV3-CONSOLIDATION-E2E": {
        "SRV3-EVM-RUNTIME",
        "SRV3-SHA256-PRECOMPILE",
    },
}
EXPECTED_INVARIANT_REPRODUCTIONS = {
    "SRV3-LEGACY-ECON": "lake build LidoSRv3",
    "SRV3-ARITH-CHECKED": "lake env lean LidoSRv3/Audit/Trust.lean",
    "SRV3-TX-REVERT": "lake env lean LidoSRv3/Audit/Trust.lean",
    "SRV3-ALLOC-ORDER": "lake env lean LidoSRv3/Audit/Trust.lean",
    "SRV3-MINFIRST-BOUND": "lake build LidoSRv3.Audit.Vectors",
    "SRV3-SOLIDITY-CORR": "python3 scripts/audit_registry.py check",
    "SRV3-VERITY-431": "python3 scripts/audit_registry.py check",
    "SRV3-YUL-COMP": "python3 scripts/audit_registry.py check",
    "SRV3-EVM-RUNTIME": "python3 scripts/audit_registry.py check",
    "SRV3-SHA256-PRECOMPILE": "python3 scripts/audit_registry.py check",
    "SRV3-CONSOLIDATION-E2E": "python3 scripts/audit_registry.py check",
}
EXPECTED_INVARIANT_FALSIFIERS = {
    "SRV3-LEGACY-ECON": "Existing Lean theorem compilation and Solidity reference fixtures; no source-level mutant is claimed.",
    "SRV3-ARITH-CHECKED": "Change checkedDiv zero handling; the theorem/build must fail.",
    "SRV3-TX-REVERT": "Retain committed state or logs on revert; the theorem/build must fail.",
    "SRV3-ALLOC-ORDER": "Permute a valid result row; the relation or theorem must reject it.",
    "SRV3-MINFIRST-BOUND": "LidoSRv3/Audit/Vectors.lean executable counterexample vectors.",
    "SRV3-SOLIDITY-CORR": "A source mutant must falsify the corresponding translated property; no such M0 harness exists.",
    "SRV3-VERITY-431": "Duplicate EVMYulLean package instances or a mismatched exact Verity pin must fail dependency gates.",
    "SRV3-YUL-COMP": "A Yul mutant must violate an interface postcondition; no M0 semantic harness exists.",
    "SRV3-EVM-RUNTIME": "Runtime bytecode or fork mismatch must fail an EVM trace; canonical artifact prerequisite is absent.",
    "SRV3-SHA256-PRECOMPILE": "Differential hash vectors can detect disagreement but do not close the opaque FFI trust boundary.",
    "SRV3-CONSOLIDATION-E2E": "An end-to-end production trace must reject a wrong runtime hash/address/fork; canonical inputs are absent.",
}
EXPECTED_UNAVAILABLE_ARTIFACT_BLOCKERS = {
    "consolidation-runtime": (
        "No independently sourced canonical EIP-7251 production "
        "runtime/hash/address/fork provenance; current helper uses a Mock build."
    ),
}
EXPECTED_THEOREM_TYPES = {
    "LidoSRv3.P1_reserve_separation": (
        "∀ (s : LidoSRv3.State), "
        "LidoSRv3.depositableEther s + LidoSRv3.withdrawalReserveUsed s = "
        "s.bufferedEther"
    ),
    "LidoSRv3.Audit.Quantity.checkedDiv_zero": (
        "∀ {unit : Type} (a : LidoSRv3.Audit.Quantity unit), "
        "a.checkedDiv 0 = none"
    ),
    "LidoSRv3.Audit.revert_restores_state_value_and_logs": (
        "∀ {State : Type} (tx : LidoSRv3.Audit.TxObservation State), "
        "tx.result = LidoSRv3.Audit.TxResult.reverted → "
        "tx.committedState = tx.before ∧ "
        "tx.committedTrace.ethMoves = [] ∧ tx.committedTrace.logs = []"
    ),
    "LidoSRv3.Audit.valid_result_preserves_router_order": (
        "∀ {snapshot : LidoSRv3.Audit.AllocationSnapshot} "
        "{result : LidoSRv3.Audit.AllocationResult}, "
        "LidoSRv3.Audit.validAllocationResult snapshot result → "
        "List.map LidoSRv3.Audit.AllocationResultRow.moduleId result.rows = "
        "List.map LidoSRv3.Audit.AllocationRow.moduleId snapshot.rows"
    ),
    "LidoSRv3.Audit.MinFirst.totalAllocated_le_requested": (
        "∀ (requested : Nat) "
        "(rows : List LidoSRv3.Audit.MinFirst.Bucket), "
        "LidoSRv3.Audit.MinFirst.totalAllocated requested rows ≤ requested"
    ),
}
EXPECTED_INVARIANT_IDS = {
    "SRV3-LEGACY-ECON",
    "SRV3-ARITH-CHECKED",
    "SRV3-TX-REVERT",
    "SRV3-ALLOC-ORDER",
    "SRV3-MINFIRST-BOUND",
    "SRV3-SOLIDITY-CORR",
    "SRV3-VERITY-431",
    "SRV3-YUL-COMP",
    "SRV3-EVM-RUNTIME",
    "SRV3-SHA256-PRECOMPILE",
    "SRV3-CONSOLIDATION-E2E",
}
EXPECTED_CURRENT_PACKAGES = {
    "verity", "evmyul", "mathlib", "plausible", "LeanSearchClient",
    "importGraph", "proofwidgets", "aesop", "Qq", "batteries", "Cli",
}
EXPECTED_TARGET_PACKAGES = {"verity", "evmyul"}
EXPECTED_CURRENT_INHERITED_PACKAGES = {
    "mathlib": (
        "https://github.com/leanprover-community/mathlib4.git",
        "f897ebcf72cd16f89ab4577d0c826cd14afaafc7", "v4.24.0",
    ),
    "plausible": (
        "https://github.com/leanprover-community/plausible",
        "dfd06ebfe8d0e8fa7faba9cb5e5a2e74e7bd2805", "main",
    ),
    "LeanSearchClient": (
        "https://github.com/leanprover-community/LeanSearchClient",
        "99657ad92e23804e279f77ea6dbdeebaa1317b98", "main",
    ),
    "importGraph": (
        "https://github.com/leanprover-community/import-graph",
        "d768126816be17600904726ca7976b185786e6b9", "main",
    ),
    "proofwidgets": (
        "https://github.com/leanprover-community/ProofWidgets4",
        "556caed0eadb7901e068131d1be208dd907d07a2", "v0.0.74",
    ),
    "aesop": (
        "https://github.com/leanprover-community/aesop",
        "725ac8cd67acd70a7beaf47c3725e23484c1ef50", "master",
    ),
    "Qq": (
        "https://github.com/leanprover-community/quote4",
        "dea6a3361fa36d5a13f87333dc506ada582e025c", "master",
    ),
    "batteries": (
        "https://github.com/leanprover-community/batteries",
        "8da40b72fece29b7d3fe3d768bac4c8910ce9bee", "main",
    ),
    "Cli": (
        "https://github.com/leanprover/lean4-cli",
        "91c18fa62838ad0ab7384c03c9684d99d306e1da", "main",
    ),
}
GENERATED = (
    "BY_FAMILY.md", "BY_STATUS.md", "BY_LAYER.md", "TRUST_BOUNDARIES.md",
    "ASSUMPTIONS.md", "REPRODUCE.md", "MATRIX.csv",
)
MD_HEADER = "<!-- GENERATED from audit/invariants.yaml; NOT EDITABLE TRUTH. -->\n"
CSV_FIELDS = ["id", "family", "priority", "status", "layer", "engine", "theorem",
              "source_anchors", "runtime_anchors", "dependencies"]
EXPECTED_ENUMS = {
    "priority": ["P0", "P1", "P2", "STRETCH"],
    "status": ["PROVED", "REGRESSION", "DEV-431-READY", "OPEN", "BLOCKED", "STRETCH"],
    "layer": ["MODEL", "ALG", "TX", "REL", "TRACE", "SRC", "YUL", "EVM", "CRYPTO", "E2E"],
    "engine": ["LEAN", "VERITY", "EVMYULLEAN", "INTERFACE", "NATIVE-FFI", "NONE"],
}


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


def is_missing_runtime_anchor(anchor: str) -> bool:
    return anchor.lstrip().casefold().startswith("missing:")


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
        require(values == EXPECTED_ENUMS[field],
                f"schema.json: {field} enum differs from the executable format")
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


def source_pins(path: Path = LOCK) -> dict[str, str]:
    lock = load_json(path)
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


def source_repositories(path: Path = LOCK) -> dict[str, tuple[str, str | None]]:
    lock = load_json(path)
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
    pins: dict[str, str], inventory_path: Path = EXTERNAL_TARGETS,
    lock_path: Path = LOCK,
) -> None:
    inventory = load_json(inventory_path)
    repositories = source_repositories(lock_path)
    for component, commit in pins.items():
        repository, pinned_ref = repositories[component]
        resolve_git_targets(
            component, repository, pinned_ref, commit,
            inventory["components"][component]["targets"],
        )


def validate_source_inventory(
    path: Path = TARGET_SOURCE, online: bool = False, target: Path = TARGET
) -> None:
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
            and set(source) == {
                "repository", "commit", "path", "blob", "upstream_sha256", "sha256"
            },
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
        require(
            re.fullmatch(r"[0-9a-f]{64}", source["upstream_sha256"]) is not None,
            "target SOURCE.json: upstream SHA-256 mismatch",
        )
        snapshot = target / source["path"]
        require(snapshot.is_file(),
                f"target snapshot missing: {source['path']}")
        require(
            hashlib.sha256(snapshot.read_bytes()).hexdigest() == source["sha256"],
            f"target snapshot digest mismatch: {source['path']}",
        )
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
                    and hashlib.sha256(content.stdout).hexdigest()
                    == source["upstream_sha256"],
                    "target SOURCE.json: remote SHA-256 mismatch",
                )
    require(seen == expected_paths, "target SOURCE.json: missing committed provenance")


def refresh_provenance(lock_path: Path = LOCK) -> None:
    validate_lock(lock_path)
    pins = source_pins(lock_path)
    external_source_targets(pins)
    refresh_external_provenance(pins, lock_path=lock_path)
    validate_source_inventory(online=True)


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


EXPECTED_TRUSTED_AXIOMS = {"propext", "Quot.sound"}


def trusted_axioms(policy_path: Path = TRUSTED_AXIOMS) -> set[str]:
    policy = load_json(policy_path)
    require(
        isinstance(policy, dict)
        and set(policy) == {"schema", "allowed"}
        and policy["schema"] == "lean-trusted-axioms-v1"
        and isinstance(policy["allowed"], list)
        and len(policy["allowed"]) == len(set(policy["allowed"]))
        and all(isinstance(name, str) and name for name in policy["allowed"]),
        "trusted-axioms.json: invalid explicit trust allowlist",
    )
    allowed = set(policy["allowed"])
    require(
        allowed == EXPECTED_TRUSTED_AXIOMS,
        "trusted-axioms.json: allowed axioms differ from fixed foundation",
    )
    return allowed


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
    theorems: list[str], proved: list[str], declarations: str = "",
    expected_types: dict[str, str] | None = None,
) -> None:
    expected_types = EXPECTED_THEOREM_TYPES if expected_types is None else expected_types
    source = (
        "import LidoSRv3\n"
        + "def auditRequireProof {P : Prop} (_ : P) : True := True.intro\n"
        + declarations
        + "".join(f"#check {theorem}\n" for theorem in theorems)
        + "".join(
            f"#check (@{theorem} : {expected_types[theorem]})\n"
            for theorem in theorems if theorem in expected_types
        )
        + "".join(f"#check auditRequireProof {theorem}\n" for theorem in proved)
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
        "registry theorem does not exist or assured reference is not a proof "
        "in LidoSRv3 build surface:\n"
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
        row["theorem"] for row in data["invariants"]
        if row["theorem"] is not None
        and row["status"] in {"PROVED", "REGRESSION"}
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
    expect_failure(
        "non-proposition PROVED reference",
        lambda: run_theorem_checks(
            ["LidoSRv3.Audit.Quantity.zero"],
            ["LidoSRv3.Audit.Quantity.zero"],
        ),
        "assured reference is not a proof",
    )
    expect_failure(
        "non-proposition REGRESSION reference",
        lambda: run_theorem_checks(
            ["LidoSRv3.Audit.Quantity.zero"],
            ["LidoSRv3.Audit.Quantity.zero"],
        ),
        "assured reference is not a proof",
    )
    wrong_type = dict(EXPECTED_THEOREM_TYPES)
    wrong_type["LidoSRv3.Audit.MinFirst.totalAllocated_le_requested"] = (
        "∀ (_requested : Nat) "
        "(_rows : List LidoSRv3.Audit.MinFirst.Bucket), True"
    )
    expect_failure(
        "theorem proposition substitution",
        lambda: run_theorem_checks(
            ["LidoSRv3.Audit.MinFirst.totalAllocated_le_requested"],
            ["LidoSRv3.Audit.MinFirst.totalAllocated_le_requested"],
            expected_types=wrong_type,
        ),
        "registry theorem does not exist or assured reference is not a proof",
    )


def validate(path: Path = REGISTRY, schema_path: Path = SCHEMA) -> dict:
    data = load_json(path)
    schema = validate_schema_definition(load_json(schema_path))
    validate_against_schema(data, schema)
    layers = schema_values(schema, "layer")
    pins = source_pins()
    targets = external_source_targets(pins)
    present_ids = {row["id"] for row in data["invariants"]}
    require(present_ids == EXPECTED_INVARIANT_IDS,
            "invariant ID inventory differs from expected obligations")

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
        expected_theorem = EXPECTED_INVARIANT_THEOREMS.get(invariant_id)
        if expected_theorem is not None:
            require(
                theorem == expected_theorem,
                f"{invariant_id}: theorem must be {expected_theorem}",
            )
        require(
            set(row["source_anchors"])
            == EXPECTED_INVARIANT_SOURCE_ANCHORS[invariant_id],
            f"{invariant_id}: source anchors differ from expected obligation evidence",
        )
        require(
            set(row["runtime_anchors"])
            == EXPECTED_INVARIANT_RUNTIME_ANCHORS[invariant_id],
            f"{invariant_id}: runtime anchors differ from expected obligation provenance",
        )
        require(
            row["family"] == EXPECTED_INVARIANT_FAMILIES[invariant_id],
            f"{invariant_id}: family differs from expected obligation family",
        )
        expected_assumptions, expected_trust_boundary = (
            EXPECTED_INVARIANT_LIMITATIONS[invariant_id]
        )
        require(
            set(row["assumptions"]) == expected_assumptions,
            f"{invariant_id}: assumptions differ from expected obligation limitations",
        )
        require(
            set(row["trust_boundary"]) == expected_trust_boundary,
            f"{invariant_id}: trust boundary differs from expected obligation limitations",
        )
        require(
            (row["priority"], row["status"], row["engine"], row["layer"])
            == EXPECTED_INVARIANT_CLASSIFICATIONS[invariant_id],
            f"{invariant_id}: priority/status/engine/layer differ from expected classification",
        )
        require(
            row["reproduction"] == EXPECTED_INVARIANT_REPRODUCTIONS[invariant_id],
            f"{invariant_id}: reproduction differs from expected verification command",
        )
        require(
            row["falsifier"] == EXPECTED_INVARIANT_FALSIFIERS[invariant_id],
            f"{invariant_id}: falsifier differs from expected obligation claim",
        )
        if row["status"] == "PROVED":
            require(theorem is not None, f"{invariant_id}: PROVED requires theorem")
        if row["layer"] in set(layers) & {"EVM", "E2E"} and row["status"] in {"PROVED", "REGRESSION"}:
            require(
                any(not is_missing_runtime_anchor(anchor) for anchor in row["runtime_anchors"]),
                f"{invariant_id}: runtime assurance requires non-missing anchors",
            )
        if row["status"] == "REGRESSION":
            require(theorem is not None, f"{invariant_id}: REGRESSION requires theorem")

    require(
        set(theorem_owners.values()) == set(EXPECTED_INVARIANT_THEOREMS),
        "theorem-bearing invariant ID inventory differs from expected bindings",
    )
    rows = {row["id"]: row for row in data["invariants"]}
    graph = {row_id: row["dependencies"] for row_id, row in rows.items()}
    for node, dependencies in graph.items():
        require(
            set(dependencies) == EXPECTED_INVARIANT_DEPENDENCIES[node],
            f"{node}: dependencies differ from expected graph",
        )
    for node, dependencies in graph.items():
        for dependency in dependencies:
            require(dependency in graph, f"{node}: unknown dependency {dependency}")
            require(dependency != node, f"{node}: self dependency")
            if rows[node]["status"] in {"PROVED", "REGRESSION"}:
                allowed_dependency_statuses = (
                    {"PROVED"}
                    if rows[node]["status"] == "PROVED"
                    else {"PROVED", "REGRESSION"}
                )
                require(
                    rows[dependency]["status"] in allowed_dependency_statuses,
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


def validate_lock(path: Path = LOCK) -> None:
    lock = load_json(path)
    expected = {
        "proof": "ee2e65cd807e913ea245ae6fd7987a7f1d962800",
        "verity": "68f560e66c5de6123061ce5ed60261be162673d1",
        "evmyullean": "f7e4ee0dc8f8d5265ce822a937ab5be771f182e9",
        "lido_core": "af095e48bbc1c3841c2c9936219c8461af01056b",
    }
    for component, commit in expected.items():
        require(lock[component]["commit"] == commit, f"{component}: exact pin mismatch")
    require(
        lock["proof"]["repository"]
        == "https://github.com/lfglabs-dev/lido-srv3-proof-closure.git",
        "proof: exact repository mismatch",
    )
    require(lock["proof"]["ref"] == "main", "proof: exact ref mismatch")
    require(
        lock["verity"]["repository"] == "https://github.com/lfglabs-dev/verity.git",
        "Verity: exact repository mismatch",
    )
    require(
        lock["verity"]["ref"] == "dev/lean-4.31-scaffolding",
        "Verity: exact ref mismatch",
    )
    require(
        lock["evmyullean"]["repository"]
        == "https://github.com/lfglabs-dev/EVMYulLean.git",
        "EVMYulLean: exact repository mismatch",
    )
    require(
        lock["lido_core"]["repository"] == "https://github.com/lidofinance/core.git",
        "lido_core: exact repository mismatch",
    )
    require(lock["evmyullean"]["ref"] == "main", "EVMYulLean: exact ref mismatch")
    require(lock["current_root"]["plane"] == "active",
            "current root plane must remain active")
    require(lock["current_root"]["verity"] == "538c4a9ce2baa25b56062bdc727eb0191ad9e67f",
            "current root Verity exact pin mismatch")
    require(lock["current_root"]["evmyullean"] == "38d53df8b4488d5322894619ea8385fcbb2e6f5d",
            "current root EVMYulLean exact pin mismatch")
    require(lock["current_root"]["lean_toolchain"] == "leanprover/lean4:v4.24.0",
            "current root Lean toolchain exact pin mismatch")
    require(lock["current_root"]["direct_dependencies"] == ["verity"],
            "current root must depend exactly once on Verity")
    require(lock["target_root"]["lean_toolchain"] == "leanprover/lean4:v4.31.0",
            "target root Lean toolchain exact pin mismatch")
    require(lock["target_root"]["direct_dependencies"] == ["verity"],
            "target root must depend exactly once on Verity")
    require("transitive" in lock["evmyullean"]["resolution"], "EVMYulLean must be transitive")
    require(
        lock["target_root"]["status"] == "DEV-431-READY"
        and lock["target_root"]["print_axioms"] == "FAIL"
        and lock["target_root"]["audit_cert"] is False,
        "target status must be DEV-431-READY, PrintAxioms FAIL, AUDIT-CERT=false",
    )
    require(
        lock["verity"]["certification"]
        == "target DEV-431-READY; target PrintAxioms FAIL; AUDIT-CERT=false",
        "Verity certification summary differs from fixed non-certified state",
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


def require_package_inventory(
    entries: list[dict], label: str, expected: set[str]
) -> None:
    require(
        {entry.get("name") for entry in entries} == expected,
        f"{label}: complete package inventory mismatch",
    )


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


def require_inherited_package(
    entries: list[dict], label: str, name: str, url: str, rev: str, input_rev: str
) -> None:
    matches = [entry for entry in entries if entry.get("name") == name]
    require(len(matches) == 1, f"{label}: expected exactly one {name} package")
    entry = matches[0]
    require(entry.get("url") == url, f"{label}: {name} URL mismatch")
    require(entry.get("rev") == rev, f"{label}: {name} rev mismatch")
    require(entry.get("inputRev") == input_rev, f"{label}: {name} inputRev mismatch")
    require(entry.get("inherited") is True, f"{label}: {name} inherited mismatch")


@dataclass(frozen=True)
class LakeToken:
    kind: str
    value: str
    line: int


@dataclass(frozen=True)
class LakeRequire:
    name: str
    repository: str | None
    revision: str | None
    line: int


def lake_tokens(source: str, label: str) -> list[LakeToken]:
    """Lex the Lake syntax needed for dependency declarations."""
    tokens: list[LakeToken] = []
    cursor = 0
    line = 1
    block_depth = 0
    while cursor < len(source):
        if source[cursor] == "\n":
            line += 1
            cursor += 1
        elif block_depth:
            if source.startswith("/-", cursor):
                block_depth += 1
                cursor += 2
            elif source.startswith("-/", cursor):
                block_depth -= 1
                cursor += 2
            else:
                cursor += 1
        elif source.startswith("--", cursor):
            newline = source.find("\n", cursor)
            cursor = len(source) if newline == -1 else newline
        elif source.startswith("/-", cursor):
            block_depth = 1
            cursor += 2
        elif source[cursor].isspace():
            cursor += 1
        elif source[cursor] == "r":
            delimiter = cursor + 1
            while delimiter < len(source) and source[delimiter] == "#":
                delimiter += 1
            if delimiter < len(source) and source[delimiter] == '"':
                hashes = delimiter - cursor - 1
                terminator = '"' + "#" * hashes
                end = source.find(terminator, delimiter + 1)
                require(end != -1, f"{label}:{line}: unterminated raw string")
                raw = source[delimiter + 1:end]
                tokens.append(LakeToken("raw", raw, line))
                line += raw.count("\n")
                cursor = end + len(terminator)
                continue
            start = cursor
            while cursor < len(source) and (
                source[cursor].isalnum() or source[cursor] in "_'-"
            ):
                cursor += 1
            tokens.append(LakeToken("identifier", source[start:cursor], line))
        elif source[cursor] == '"':
            token_line = line
            cursor += 1
            value = []
            while cursor < len(source) and source[cursor] != '"':
                if source[cursor] == "\\":
                    cursor += 1
                    require(cursor < len(source), f"{label}:{token_line}: unterminated string")
                    value.append({
                        "n": "\n", "r": "\r", "t": "\t", '"': '"', "\\": "\\",
                    }.get(source[cursor], source[cursor]))
                else:
                    if source[cursor] == "\n":
                        line += 1
                    value.append(source[cursor])
                cursor += 1
            require(cursor < len(source), f"{label}:{token_line}: unterminated string")
            cursor += 1
            tokens.append(LakeToken("string", "".join(value), token_line))
        elif source[cursor] == "«":
            end = source.find("»", cursor + 1)
            require(end != -1, f"{label}:{line}: unterminated escaped identifier")
            tokens.append(LakeToken("identifier", source[cursor + 1:end], line))
            cursor = end + 1
        elif source[cursor].isalpha() or source[cursor] == "_":
            start = cursor
            while cursor < len(source) and (
                source[cursor].isalnum() or source[cursor] in "_'-"
            ):
                cursor += 1
            tokens.append(LakeToken("identifier", source[start:cursor], line))
        else:
            tokens.append(LakeToken("symbol", source[cursor], line))
            cursor += 1
    require(block_depth == 0, f"{label}: unterminated block comment")
    return tokens


def parse_lake_requires(source: str, label: str) -> list[LakeRequire]:
    tokens = lake_tokens(source, label)
    declarations = []
    cursor = 0
    while cursor < len(tokens):
        token = tokens[cursor]
        if token.kind != "identifier" or token.value != "require":
            cursor += 1
            continue
        require(
            cursor + 1 < len(tokens) and tokens[cursor + 1].kind == "identifier",
            f"{label}:{token.line}: malformed require declaration",
        )
        name = tokens[cursor + 1].value
        repository = revision = None
        if (
            cursor + 6 < len(tokens)
            and tokens[cursor + 2] == LakeToken("identifier", "from", tokens[cursor + 2].line)
            and tokens[cursor + 3] == LakeToken("identifier", "git", tokens[cursor + 3].line)
            and tokens[cursor + 4].kind == "string"
            and tokens[cursor + 5].kind == "symbol"
            and tokens[cursor + 5].value == "@"
            and tokens[cursor + 6].kind == "string"
        ):
            repository = tokens[cursor + 4].value
            revision = tokens[cursor + 6].value
            cursor += 7
        else:
            cursor += 2
        declarations.append(LakeRequire(name, repository, revision, token.line))
    return declarations


def require_direct_dependencies(
    declarations: list[LakeRequire], entries: list[dict], declared: list[str], label: str
) -> None:
    lake_names = [declaration.name for declaration in declarations]
    manifest_names = [
        entry.get("name") for entry in entries if entry.get("inherited") is False
    ]
    require(lake_names == declared,
            f"{label}: direct lakefile dependencies differ from lock declaration")
    require(manifest_names == declared,
            f"{label}: direct manifest dependencies differ from lock declaration")


def validate_dependency_planes(
    root_lakefile: Path = ROOT / "lakefile.lean",
    root_manifest: Path = ROOT / "lake-manifest.json",
    root_toolchain: Path = ROOT / "lean-toolchain",
    target_lakefile: Path = TARGET / "lakefile.lean",
    target_manifest: Path = TARGET / "lake-manifest.json",
    target_toolchain: Path = TARGET / "lean-toolchain",
    verity_metadata: Path = TARGET / "verity.json",
    lock_path: Path = LOCK,
) -> None:
    lock = load_json(lock_path)
    current = lock["current_root"]
    require(root_toolchain.read_text(encoding="utf-8").strip() == current["lean_toolchain"],
            "current plane: Lean toolchain mismatch")
    current_lake = root_lakefile.read_text(encoding="utf-8")
    current_requires = parse_lake_requires(current_lake, "current plane")
    current_verity = [declaration for declaration in current_requires
                      if declaration.name == "verity"]
    require(len(current_verity) == 1,
            "current plane: expected exactly one direct Verity")
    require(not any(declaration.name.lower().startswith("evmyul")
                    for declaration in current_requires),
            "current plane: direct EVMYulLean forbidden")
    require(
        (current_verity[0].repository, current_verity[0].revision)
        == (lock["verity"]["repository"], current["verity"]),
        "current plane: Verity lakefile repository/revision mismatch",
    )
    current_entries = dependency_entries(load_json(root_manifest), "current plane")
    require_package_inventory(
        current_entries, "current plane", EXPECTED_CURRENT_PACKAGES
    )
    require_package(current_entries, "current plane", "verity",
                    "https://github.com/lfglabs-dev/verity.git",
                    current["verity"], False)
    require_package(current_entries, "current plane", "evmyul",
                    "https://github.com/lfglabs-dev/EVMYulLean.git",
                    current["evmyullean"], True)
    for name, (url, rev, input_rev) in EXPECTED_CURRENT_INHERITED_PACKAGES.items():
        require_inherited_package(
            current_entries, "current plane", name, url, rev, input_rev
        )
    require_direct_dependencies(
        current_requires, current_entries, current["direct_dependencies"], "current plane"
    )

    target = lock["target_root"]
    require(target["plane"] == "audit-only" and target["path"] == "audit/target-4.31",
            "target plane must remain audit-only")
    require(target_toolchain.read_text(encoding="utf-8").strip() == target["lean_toolchain"],
            "target plane: Lean toolchain mismatch")
    target_lake = target_lakefile.read_text(encoding="utf-8")
    target_requires = parse_lake_requires(target_lake, "target plane")
    target_verity = [declaration for declaration in target_requires
                     if declaration.name == "verity"]
    require(len(target_verity) == 1,
            "target plane: expected exactly one direct Verity")
    require(not any(declaration.name.lower().startswith("evmyul")
                    for declaration in target_requires),
            "target plane: direct EVMYulLean forbidden")
    require(
        (target_verity[0].repository, target_verity[0].revision)
        == (lock["verity"]["repository"], lock["verity"]["commit"]),
        "target plane: Verity lakefile repository/revision mismatch",
    )
    target_entries = dependency_entries(load_json(target_manifest), "target plane")
    require_package_inventory(
        target_entries, "target plane", EXPECTED_TARGET_PACKAGES
    )
    require_package(target_entries, "target plane", "verity",
                    lock["verity"]["repository"], lock["verity"]["commit"], False)
    require_package(target_entries, "target plane", "evmyul",
                    lock["evmyullean"]["repository"], lock["evmyullean"]["commit"], True)
    require_direct_dependencies(
        target_requires, target_entries, target["direct_dependencies"], "target plane"
    )
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
    expected_receipt = {
        "status": "FAIL",
        "audit_cert": False,
        "command": "lake build PrintAxioms && lake env lean PrintAxioms.lean",
        "location": "Verity 68f560e66c5de6123061ce5ed60261be162673d1",
        "observation": (
            "Previously observed upstream failure; not freshly independently "
            "reproduced by this M0 repair."
        ),
    }
    require(
        receipt == expected_receipt,
        "target plane: PrintAxioms receipt differs from fixed non-certified evidence",
    )
    assert_fresh(
        TARGET / "VALIDATION.md",
        "# Target 4.31 validation receipt\n\n"
        "This directory is immutable audit metadata for a proposed future root. It is\n"
        "not the repository's active Lake configuration.\n\n"
        "- Target readiness: `DEV-431-READY`\n"
        "- Target `PrintAxioms`: `FAIL`\n"
        "- `AUDIT-CERT=false`\n"
        "- Exact command: `lake build PrintAxioms && lake env lean PrintAxioms.lean`\n"
        "- Location: Verity `68f560e66c5de6123061ce5ed60261be162673d1`\n"
        "- Reproduction status: previously observed upstream failure; not freshly\n"
        "  independently reproduced by this M0 repair.\n\n"
        "An owner-authorized isolated target checkout must make the target\n"
        "`PrintAxioms` gate pass before any future certification claim.\n",
        "audit/target-4.31/VALIDATION.md",
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
    unavailable_blockers: dict[str, object] = {}
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
            unavailable_blockers[artifact_id] = artifact.get("blocker")
            continue
        file_path = ROOT / path
        require(file_path.is_file(), f"{artifact_id}: missing {path}")
        actual = hashlib.sha256(file_path.read_bytes()).hexdigest()
        require(digest == actual, f"{artifact_id}: sha256 mismatch: expected {digest}, got {actual}")
    require(seen == set(EXPECTED_ARTIFACTS),
            f"artifact inventory differs: {sorted(seen ^ set(EXPECTED_ARTIFACTS))}")
    for artifact_id, expected_blocker in EXPECTED_UNAVAILABLE_ARTIFACT_BLOCKERS.items():
        require(
            unavailable_blockers.get(artifact_id) == expected_blocker,
            f"{artifact_id}: blocker differs from expected unavailable-artifact provenance",
        )
    require(
        trust_levels == EXPECTED_ARTIFACT_TRUST_LEVELS,
        "artifact trust-level meanings differ from expected semantics",
    )


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
    return "".join(out).rstrip("\n") + "\n"


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
    return "".join(out).rstrip("\n") + "\n"


def render_reproduce(data: dict) -> str:
    out = [MD_HEADER, "# Reproduction commands\n\n"]
    for row in sorted(data["invariants"], key=lambda item: item["id"]):
        out.append(f"## {row['id']}\n\n```sh\n{row['reproduction']}\n```\n\n")
    return "".join(out).rstrip("\n") + "\n"


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
    expected_status = Counter(
        (row["status"], row["id"]) for row in data["invariants"]
    )
    actual_status: Counter[tuple[str, str]] = Counter()
    current_status: str | None = None
    for line in views["BY_STATUS.md"].splitlines():
        if line.startswith("## "):
            current_status = line[3:]
        match = re.match(r"^\| ([A-Z][A-Z0-9-]*) \|", line)
        if match and match.group(1) != "ID":
            require(current_status is not None,
                    "BY_STATUS.md: invariant row appears before status heading")
            actual_status[(current_status, match.group(1))] += 1
    require(actual_status == expected_status,
            "BY_STATUS.md: rendered status classification differs")
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


def layout_command_spans(source: str, commands: tuple[str, ...]) -> list[str]:
    """Collect complete layout-delimited commands, including trivia lines."""
    lines = source.splitlines(keepends=True)
    spans = []
    index = 0
    starter = re.compile(
        r"^([ \t]*)(?:@\[[\s\S]*?\][ \t\r\n]*)*"
        r"(?:(?:private|protected|local|noncomputable|public|"
        r"scoped(?:[ \t]*\[[^\]\n]*\])?)[ \t\r\n]+)*"
        r"(?:" + "|".join(re.escape(command) for command in commands) + r")\b"
    )

    def after_leading_block_comment_trivia(text: str) -> str | None:
        """Return code after whitespace/block-comment trivia, preserving its indent."""
        cursor = 0
        block_depth = 0
        initial_indent_end = 0
        while initial_indent_end < len(text) and text[initial_indent_end] in " \t":
            initial_indent_end += 1
        initial_indent = text[:initial_indent_end]
        while cursor < len(text):
            if block_depth:
                if text.startswith("/-", cursor):
                    block_depth += 1
                    cursor += 2
                elif text.startswith("-/", cursor):
                    block_depth -= 1
                    cursor += 2
                else:
                    cursor += 1
            elif text.startswith("/-", cursor):
                block_depth = 1
                cursor += 2
            elif text[cursor] in " \t\r\n":
                cursor += 1
            else:
                return initial_indent + text[cursor:]
        return None

    def starter_match(text: str) -> re.Match[str] | None:
        candidate = after_leading_block_comment_trivia(text)
        if candidate is None:
            return None
        cursor = 0
        block_depth = 0
        uncommented = []
        while cursor < len(candidate):
            if block_depth:
                if candidate.startswith("/-", cursor):
                    block_depth += 1
                    uncommented.extend("  ")
                    cursor += 2
                elif candidate.startswith("-/", cursor):
                    block_depth -= 1
                    uncommented.extend("  ")
                    cursor += 2
                else:
                    uncommented.append(
                        candidate[cursor]
                        if candidate[cursor] in "\r\n"
                        else " "
                    )
                    cursor += 1
            elif candidate.startswith("/-", cursor):
                block_depth = 1
                uncommented.extend("  ")
                cursor += 2
            elif candidate.startswith("--", cursor):
                line_end = candidate.find("\n", cursor)
                if line_end == -1:
                    uncommented.extend(" " * (len(candidate) - cursor))
                    cursor = len(candidate)
                else:
                    uncommented.extend(" " * (line_end - cursor))
                    cursor = line_end
            else:
                uncommented.append(candidate[cursor])
                cursor += 1
        return starter.match("".join(uncommented))

    def line_layout(
        line: str, block_depth: int, delimiter_depth: int
    ) -> tuple[bool, int | None, int, int]:
        """Return code presence/indent and lexical state after one line."""
        cursor = 0
        first_code = None
        leading_indent = 0
        leading_comment = bool(block_depth)
        string = False
        escaped = False
        while cursor < len(line):
            if block_depth:
                if line.startswith("/-", cursor):
                    block_depth += 1
                    cursor += 2
                elif line.startswith("-/", cursor):
                    block_depth -= 1
                    cursor += 2
                else:
                    cursor += 1
            elif string:
                if escaped:
                    escaped = False
                elif line[cursor] == "\\":
                    escaped = True
                elif line[cursor] == '"':
                    string = False
                cursor += 1
            elif line.startswith("--", cursor):
                break
            elif line.startswith("/-", cursor):
                if first_code is None:
                    leading_comment = True
                block_depth = 1
                cursor += 2
            elif line[cursor] in " \t\r\n":
                if first_code is None and not leading_comment:
                    if line[cursor] == "\t":
                        leading_indent = (leading_indent // 8 + 1) * 8
                    elif line[cursor] == " ":
                        leading_indent += 1
                cursor += 1
            else:
                if first_code is None:
                    first_code = cursor
                if line[cursor] == '"':
                    string = True
                elif line[cursor] in "([{":
                    delimiter_depth += 1
                elif line[cursor] in ")]}" and delimiter_depth:
                    delimiter_depth -= 1
                cursor += 1
        indent = leading_indent if first_code is not None else None
        return first_code is not None, indent, block_depth, delimiter_depth

    while index < len(lines):
        candidate = lines[index]
        match = starter_match(candidate)
        starter_end = index + 1
        leading = after_leading_block_comment_trivia(candidate)
        if match is None and (
            leading is None or re.match(r"^[ \t]*@\[", leading)
        ):
            attribute_block_depth = 0
            attribute_delimiter_depth = 0
            _, _, attribute_block_depth, attribute_delimiter_depth = line_layout(
                lines[index], 0, 0
            )
            probe = index + 1
            while probe < len(lines):
                candidate += lines[probe]
                _, _, attribute_block_depth, attribute_delimiter_depth = line_layout(
                    lines[probe],
                    attribute_block_depth,
                    attribute_delimiter_depth,
                )
                probe += 1
                if not attribute_block_depth and not attribute_delimiter_depth:
                    match = starter_match(candidate)
                    if match is not None:
                        starter_end = probe
                    break
        if match is None:
            index += 1
            continue
        indent = len(match.group(1).expandtabs(8))
        block_depth = delimiter_depth = 0
        for starter_line in lines[index:starter_end]:
            _, _, block_depth, delimiter_depth = line_layout(
                starter_line, block_depth, delimiter_depth
            )
        end = starter_end
        while end < len(lines):
            line = lines[end]
            has_code, line_indent, next_block_depth, next_delimiter_depth = line_layout(
                line, block_depth, delimiter_depth
            )
            if not has_code or (block_depth and next_block_depth) or delimiter_depth:
                block_depth = next_block_depth
                delimiter_depth = next_delimiter_depth
                end += 1
                continue
            if line_indent is not None and line_indent <= indent:
                break
            block_depth = next_block_depth
            delimiter_depth = next_delimiter_depth
            end += 1
        spans.append("".join(lines[index:end]))
        index = end
    return spans


def find_proof_escapes(sources: list[tuple[str, str]]) -> list[str]:
    patterns = re.compile(
        r"(?<![\w'])(sorryAx|sorry|admit|axiom|constant|unsafe|native_decide|"
        r"implemented_by|extern|addDecl|addAndCompile|addDeclCore|mkDecl|"
        r"axiomDecl|opaqueDecl|thmDecl)(?![\w'])"
    )
    violations = []
    source_by_name = dict(sources)
    own_literal_free_prefix_categories: dict[
        str, list[tuple[tuple[str, str], int, tuple[int, ...] | None]]
    ] = defaultdict(list)
    exported_literal_free_prefix_categories: dict[
        str, set[tuple[str, str]]
    ] = defaultdict(set)
    scoped_literal_free_prefix_categories: dict[
        str, dict[str, list[tuple[tuple[str, str], int]]]
    ] = defaultdict(lambda: defaultdict(list))
    own_interpolated_prefixes: dict[
        str, list[tuple[tuple[str, bool], int, tuple[int, ...] | None]]
    ] = defaultdict(list)
    exported_interpolated_prefixes: dict[
        str, set[tuple[str, bool]]
    ] = defaultdict(set)
    scoped_interpolated_prefixes: dict[
        str, dict[str, list[tuple[tuple[str, bool], int]]]
    ] = defaultdict(lambda: defaultdict(list))
    syntax_interpolation = re.compile(
        r'\b(?:syntax(?:\s*\([^)]*\))?|macro)\b'
        r'[\s\S]*?"((?:\\.|[^"\\])*)"\s+'
        r'(.*?)\binterpolatedStr(?:\([^)]*\))?',
        re.DOTALL,
    )
    interpolation_declaration = re.compile(
        r'\b(?:syntax(?:\s*\([^)]*\))?|macro)\b'
        r'(?P<parser>[\s\S]*?)\binterpolatedStr(?:\([^)]*\))?',
        re.DOTALL,
    )

    def without_lean_comments(text: str) -> str:
        """Replace nested block and line comments with whitespace."""
        uncommented = []
        cursor = 0
        block_depth = 0
        string_escaped = False
        in_string = False
        while cursor < len(text):
            if in_string:
                character = text[cursor]
                uncommented.append(character)
                cursor += 1
                if string_escaped:
                    string_escaped = False
                elif character == "\\":
                    string_escaped = True
                elif character == '"':
                    in_string = False
            elif block_depth:
                if text.startswith("/-", cursor):
                    block_depth += 1
                    uncommented.extend("  ")
                    cursor += 2
                elif text.startswith("-/", cursor):
                    block_depth -= 1
                    uncommented.extend("  ")
                    cursor += 2
                else:
                    uncommented.append(
                        text[cursor] if text[cursor] in "\r\n" else " "
                    )
                    cursor += 1
            elif text.startswith("/-", cursor):
                block_depth = 1
                uncommented.extend("  ")
                cursor += 2
            elif text.startswith("--", cursor):
                line_end = text.find("\n", cursor)
                if line_end == -1:
                    uncommented.extend(" " * (len(text) - cursor))
                    cursor = len(text)
                else:
                    uncommented.extend(" " * (line_end - cursor))
                    cursor = line_end
            elif text[cursor] == '"':
                in_string = True
                uncommented.append(text[cursor])
                cursor += 1
            else:
                uncommented.append(text[cursor])
                cursor += 1
        return "".join(uncommented)

    def structural_code(text: str) -> str:
        """Mask comments and literals while preserving offsets and newlines."""
        masked = list(without_lean_comments(text))
        cursor = 0
        while cursor < len(masked):
            if masked[cursor] == '"':
                masked[cursor] = " "
                cursor += 1
                escaped = False
                while cursor < len(masked):
                    character = masked[cursor]
                    if character not in "\r\n":
                        masked[cursor] = " "
                    cursor += 1
                    if escaped:
                        escaped = False
                    elif character == "\\":
                        escaped = True
                    elif character == '"':
                        break
            elif masked[cursor] == "'":
                end = cursor + 1
                if end < len(masked) and masked[end] == "\\":
                    end += 2
                else:
                    end += 1
                if end < len(masked) and masked[end] == "'":
                    for index in range(cursor, end + 1):
                        if masked[index] not in "\r\n":
                            masked[index] = " "
                    cursor = end + 1
                else:
                    cursor += 1
            else:
                cursor += 1
        return "".join(masked)

    @dataclass(frozen=True)
    class ScopeFrame:
        identity: int
        kind: str
        name: str | None

    @dataclass(frozen=True)
    class ScopedActivation:
        name: str
        owner_frames: tuple[int, ...]

    @dataclass(frozen=True)
    class ScannerScopeState:
        namespace: str
        active_scopes: frozenset[str]
        frames: tuple[int, ...]

    def scope_state_at(source: str, offset: int) -> ScannerScopeState:
        """Replay Lean namespace/section and scoped activation commands."""
        scopes: list[ScopeFrame] = []
        activations: list[ScopedActivation] = []
        next_identity = 0
        for line in structural_code(source[:offset]).splitlines():
            namespace_match = re.match(
                r"^[ \t]*namespace[ \t]+"
                r"((?:[A-Za-z_][\w']*|«[^»\r\n]+»)"
                r"(?:\.(?:[A-Za-z_][\w']*|«[^»\r\n]+»))*)[ \t]*$",
                line,
            )
            if namespace_match is not None:
                scopes.append(
                    ScopeFrame(next_identity, "namespace", namespace_match.group(1))
                )
                next_identity += 1
                continue
            section_match = re.match(
                r"^[ \t]*section(?:[ \t]+"
                r"((?:[A-Za-z_][\w']*|«[^»\r\n]+»)))?[ \t]*$",
                line,
            )
            if section_match is not None:
                scopes.append(
                    ScopeFrame(next_identity, "section", section_match.group(1))
                )
                next_identity += 1
                continue
            open_match = re.match(
                r"^[ \t]*open[ \t]+scoped[ \t]+(.+?)[ \t]*$", line
            )
            if open_match is not None:
                owner_frames = tuple(frame.identity for frame in scopes)
                activations.extend(
                    ScopedActivation(name, owner_frames)
                    for name in re.findall(
                        r"(?:[A-Za-z_][\w']*|«[^»\r\n]+»)"
                        r"(?:\.(?:[A-Za-z_][\w']*|«[^»\r\n]+»))*",
                        open_match.group(1),
                    )
                )
                continue
            end_match = re.match(
                r"^[ \t]*end(?:[ \t]+"
                r"((?:[A-Za-z_][\w']*|«[^»\r\n]+»)"
                r"(?:\.(?:[A-Za-z_][\w']*|«[^»\r\n]+»))*))?[ \t]*$",
                line,
            )
            if end_match is None or not scopes:
                continue
            close_name = end_match.group(1)
            if close_name is None or scopes[-1].name == close_name:
                scopes.pop()
        current_frames = tuple(frame.identity for frame in scopes)
        namespace = ".".join(
            frame.name or ""
            for frame in scopes
            if frame.kind == "namespace"
        )
        active_scopes = frozenset(
            activation.name
            for activation in activations
            if current_frames[:len(activation.owner_frames)]
            == activation.owner_frames
        )
        return ScannerScopeState(namespace, active_scopes, current_frames)

    for source_name, source in sources:
        declaration_cursor = 0
        for declaration in layout_command_spans(
            source, ("syntax", "macro", "set_option")
        ):
            declaration_offset = source.find(declaration, declaration_cursor)
            if declaration_offset == -1:
                declaration_offset = source.find(declaration)
            declaration_cursor = declaration_offset + len(declaration)
            declaration_start = structural_code(declaration)
            local_declaration = re.match(
                r"^[ \t\r\n]*"
                r"(?:(?:set_option\b[\s\S]*?\bin[ \t\r\n]+)"
                r"(?:@\[[\s\S]*?\][ \t\r\n]*)*)*"
                r"(?:(?:private|protected|noncomputable)[ \t\r\n]+)*"
                r"local\b",
                declaration_start,
            )
            scoped_declaration = re.match(
                r"^[ \t\r\n]*"
                r"(?:(?:set_option\b[\s\S]*?\bin[ \t\r\n]+)"
                r"(?:@\[[\s\S]*?\][ \t\r\n]*)*)*"
                r"(?:(?:private|protected|noncomputable)[ \t\r\n]+)*"
                r"scoped\b",
                declaration_start,
            )
            interpolation_match = interpolation_declaration.search(declaration)
            if (
                interpolation_match is not None
                and re.search(
                    r'"(?:\\.|[^"\\])*"', interpolation_match.group("parser")
                ) is None
            ):
                parser = without_lean_comments(
                    interpolation_match.group("parser")
                )
                categories = re.findall(
                    r"(?:[A-Za-z_][\w']*|«[^»\r\n]+»)[ \t]*:[ \t]*"
                    r"\(?[ \t]*([A-Za-z_][\w']*)[ \t]*\)?[ \t]*"
                    r",?[ \t]*([*?+]?)",
                    parser,
                )
                category = categories[-1] if categories else ("unknown", "")
                if local_declaration is not None:
                    own_literal_free_prefix_categories[source_name].append(
                        (
                            category,
                            declaration_offset,
                            scope_state_at(source, declaration_offset).frames,
                        )
                    )
                else:
                    if scoped_declaration is None:
                        own_literal_free_prefix_categories[source_name].append(
                            (category, declaration_offset, None)
                        )
                        exported_literal_free_prefix_categories[source_name].add(
                            category
                        )
                    else:
                        scope = scope_state_at(source, declaration_offset).namespace
                        if scope:
                            scoped_literal_free_prefix_categories[source_name][
                                scope
                            ].append((category, declaration_offset))
            for match in syntax_interpolation.finditer(declaration):
                try:
                    prefix = json.loads(f'"{match.group(1)}"')
                except json.JSONDecodeError:
                    continue
                if prefix:
                    prefix_descriptor = (
                        prefix, bool(match.group(2).strip())
                    )
                    if local_declaration is not None:
                        own_interpolated_prefixes[source_name].append(
                            (
                                prefix_descriptor,
                                declaration_offset,
                                scope_state_at(
                                    source, declaration_offset
                                ).frames,
                            )
                        )
                    elif scoped_declaration is None:
                        own_interpolated_prefixes[source_name].append(
                            (prefix_descriptor, declaration_offset, None)
                        )
                        exported_interpolated_prefixes[source_name].add(
                            prefix_descriptor
                        )
                    else:
                        scope = scope_state_at(
                            source, declaration_offset
                        ).namespace
                        if scope:
                            scoped_interpolated_prefixes[source_name][
                                scope
                            ].append(
                                (prefix_descriptor, declaration_offset)
                            )
    literal_free_category_patterns = {
        "ident": r"(?:«[^»\r\n]+»|(?:[^\W\d]|_)[\w'.]*)",
        "num": r"\d[\w']*",
    }
    modules = {
        re.sub(r"\.lean$", "", source_name).replace("/", "."): source_name
        for source_name, _ in sources
        if source_name.endswith(".lean")
    }
    def command_offsets(source: str, commands: tuple[str, ...]) -> list[tuple[int, str]]:
        result = []
        cursor = 0
        for command in layout_command_spans(source, commands):
            offset = source.find(command, cursor)
            require(offset >= 0, "scanner internal command span mismatch")
            result.append((offset, command))
            cursor = offset + len(command)
        return result

    imports: dict[str, set[str]] = defaultdict(set)
    for source_name, source in sources:
        for command in layout_command_spans(structural_code(source), ("import",)):
            match = re.match(
                r"^[ \t\r\n]*(?:public[ \t]+)?import[ \t]+([\s\S]*)$",
                command,
            )
            if match is None:
                continue
            tokens = re.findall(
                r"[A-Za-z_][\w']*(?:\.[A-Za-z_][\w']*)*", match.group(1)
            )
            index = 0
            while index < len(tokens):
                if tokens[index] == "as":
                    index += 2
                    continue
                if tokens[index] in modules:
                    imports[source_name].add(tokens[index])
                index += 1
    def active_literal_free_categories(
        source_name: str, offset: int | None = None
    ) -> set[tuple[str, str]]:
        limit = sys.maxsize if offset is None else offset
        state = scope_state_at(
            source_by_name[source_name],
            len(source_by_name[source_name]) if offset is None else offset,
        )
        active = {
            category
            for category, declaration_offset, owner_frames
            in own_literal_free_prefix_categories[source_name]
            if declaration_offset < limit
            and (
                owner_frames is None
                or state.frames[:len(owner_frames)] == owner_frames
            )
        }
        active_scopes = state.active_scopes
        for scope in active_scopes:
            active.update(
                category
                for category, declaration_offset
                in scoped_literal_free_prefix_categories[source_name].get(scope, [])
                if declaration_offset < limit
            )
        pending = list(imports.get(source_name, set()))
        visited = set()
        while pending:
            imported = pending.pop()
            if imported in visited:
                continue
            visited.add(imported)
            imported_source = modules[imported]
            active.update(exported_literal_free_prefix_categories[imported_source])
            for scope in active_scopes:
                active.update(
                    category
                    for category, _ in
                    scoped_literal_free_prefix_categories[imported_source].get(
                        scope, []
                    )
                )
            pending.extend(imports.get(imported_source, set()))
        return active

    def active_interpolated_prefixes(
        source_name: str, offset: int
    ) -> set[tuple[str, bool]]:
        state = scope_state_at(source_by_name[source_name], offset)
        active = {
            prefix
            for prefix, declaration_offset, owner_frames
            in own_interpolated_prefixes[source_name]
            if declaration_offset < offset
            and (
                owner_frames is None
                or state.frames[:len(owner_frames)] == owner_frames
            )
        }
        for scope in state.active_scopes:
            active.update(
                prefix
                for prefix, declaration_offset
                in scoped_interpolated_prefixes[source_name].get(scope, [])
                if declaration_offset < offset
            )
        pending = list(imports.get(source_name, set()))
        visited = set()
        while pending:
            imported = pending.pop()
            if imported in visited:
                continue
            visited.add(imported)
            imported_source = modules[imported]
            active.update(exported_interpolated_prefixes[imported_source])
            for scope in state.active_scopes:
                active.update(
                    prefix
                    for prefix, _ in scoped_interpolated_prefixes[
                        imported_source
                    ].get(scope, [])
                )
            pending.extend(imports.get(imported_source, set()))
        return active

    builtin_interpolated_prefix = re.compile(
        r"(?:!|"
        r"Macro\.trace\[[^\]]*\]|trace(?:_goal)?\[[^\]]*\]|"
        r"dbg_trace|throwError|throwErrorAt\b.+|report(?:Dbg|EMatch)?Issue!)\s*$"
    )
    def is_interpolated_prefix(
        prefix_code: str, source_name: str, offset: int
    ) -> bool:
        if builtin_interpolated_prefix.search(prefix_code):
            return True
        for prefix, has_intermediate in active_interpolated_prefixes(
            source_name, offset
        ):
            suffix = (
                r"(?:\s+\S.*)?" if has_intermediate else ""
            )
            if re.search(
                r"(?<![\w'])" + re.escape(prefix) + suffix + r"\s*$",
                prefix_code,
            ):
                return True
        return any(
            re.search(
                literal_free_category_patterns.get(category, r"[^\s\"]+")
                + r"\s*$",
                prefix_code,
            )
            for category, _ in active_literal_free_categories(
                source_name, offset
            )
        )
    for name, source in sources:
        block_depth = 0
        contexts: list[tuple[str, object]] = [("code", None)]
        sanitized_lines = []
        layout_significant_code = ""
        layout_delimiters: list[str] = []
        source_offset = 0
        for number, raw_line in enumerate(source.splitlines(keepends=True), 1):
            line = raw_line.rstrip("\r\n")
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
                    prefix_code = " ".join(
                        [
                            layout_significant_code,
                            "".join(code_parts) + line[cursor:delimiter],
                        ]
                    )
                    if (
                        delimiter < len(line)
                        and line[delimiter] == '"'
                    ):
                        if is_interpolated_prefix(
                            prefix_code, name, source_offset + cursor
                        ):
                            code_parts.append("!")
                            contexts.append(("string", (True, False)))
                        else:
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
                elif line[cursor] == '"' and (
                    any(
                        cardinality in ("*", "?")
                        for _, cardinality in active_literal_free_categories(
                            name, source_offset + cursor
                        )
                    )
                    or is_interpolated_prefix(
                        " ".join([layout_significant_code, "".join(code_parts)]),
                        name,
                        source_offset + cursor,
                    )
                ):
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
            if code.strip():
                if (code[0].isspace() or layout_delimiters) and layout_significant_code:
                    layout_significant_code += " " + code.strip()
                else:
                    layout_significant_code = code.strip()
            for character in code:
                if character in "([{":
                    layout_delimiters.append(character)
                elif character in ")]}" and layout_delimiters:
                    layout_delimiters.pop()
            if patterns.search(code):
                violations.append(f"{name}:{number}:{line.strip()}")
            source_offset += len(raw_line)
        sanitized = "\n".join(sanitized_lines)
        for macro_opaque in re.finditer(
            r"`\([ \t\r\n]*(?:command[ \t\r\n]*\|[ \t\r\n]*)?"
            r"(?:@\[[\s\S]*?\][ \t\r\n]*)*"
            r"(?:(?:set_option\b[\s\S]*?\bin[ \t\r\n]+)"
            r"(?:@\[[\s\S]*?\][ \t\r\n]*)*)*"
            r"(?:(?:private|protected|noncomputable)[ \t\r\n]+)*opaque\b",
            sanitized,
        ):
            line_number = sanitized.count("\n", 0, macro_opaque.start()) + 1
            original = source.splitlines()[line_number - 1].strip()
            violations.append(f"{name}:{line_number}:{original}")
        custom_commands = set()
        for declaration in layout_command_spans(
            source, ("syntax", "macro", "elab", "set_option")
        ):
            for command_match in re.finditer(
                r'"((?:\\.|[^"\\])+)"[\s\S]*:[ \t]*command\b',
                declaration,
            ):
                try:
                    command = json.loads(f'"{command_match.group(1)}"')
                except json.JSONDecodeError:
                    continue
                if command and not any(character.isspace() for character in command):
                    custom_commands.add(command)
        opaque_start = re.compile(
            r"\A[ \t\r\n]*(?:@\[[\s\S]*?\][ \t\r\n]*)*"
            r"(?:(?:set_option\b[\s\S]*?\bin[ \t\r\n]+)"
            r"(?:@\[[\s\S]*?\][ \t\r\n]*)*)*"
            r"(?:(?:private|protected|noncomputable)[ \t\r\n]+)*opaque[ \t]+"
        )
        opaque_search_from = 0
        for source_declaration in layout_command_spans(
            source,
            ("opaque", "set_option", "private", "protected", "noncomputable"),
        ):
            declaration_start = source.find(source_declaration, opaque_search_from)
            require(declaration_start >= 0, "scanner internal opaque span mismatch")
            opaque_search_from = declaration_start + len(source_declaration)
            start_line = source.count("\n", 0, declaration_start)
            declaration_line_count = len(source_declaration.splitlines())
            declaration = "\n".join(
                sanitized_lines[start_line:start_line + declaration_line_count]
            )
            match = opaque_start.search(declaration)
            if match is None:
                continue
            body_delimiter = False
            delimiter_stack = []
            pending_type_assignments = 0
            cursor = match.end()
            while cursor < len(declaration):
                character = declaration[cursor]
                if character in "([{":
                    delimiter_stack.append(character)
                elif character in ")]}":
                    if delimiter_stack:
                        delimiter_stack.pop()
                elif not delimiter_stack:
                    assignment_match = re.match(
                        r"(?:let|have)(?![\w'])", declaration[cursor:]
                    )
                    if assignment_match is not None and (
                        cursor == 0 or not re.match(r"[\w']", declaration[cursor - 1])
                    ):
                        pending_type_assignments += 1
                        cursor += len(assignment_match.group(0))
                        continue
                    if declaration.startswith(":=", cursor):
                        if pending_type_assignments:
                            pending_type_assignments -= 1
                            cursor += 2
                            continue
                        body_delimiter = True
                        break
                cursor += 1
            if (
                not body_delimiter
                and re.search(r"(?m)^[ \t]*where\b", declaration) is None
            ):
                line_number = start_line + declaration.count(
                    "\n", 0, match.start()
                ) + 1
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
    try:
        mode = path.stat().st_mode
    except OSError as error:
        raise RegistryError(f"negative fixture unreadable: audit/fixtures/{name}: {error}") from error
    require(mode & 0o444 != 0, f"negative fixture unreadable: audit/fixtures/{name}")
    return path


def load_json_fixture(name: str) -> object:
    return load_json(require_fixture(name))


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
    def require_lean_elaboration(label: str, source: str) -> None:
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".lean", encoding="utf-8", dir=ROOT, delete=False
        ) as lean_file:
            lean_file.write(source)
            lean_path = Path(lean_file.name)
        try:
            elaborated = subprocess.run(
                ["lake", "env", "lean", str(lean_path.relative_to(ROOT))],
                cwd=ROOT, text=True, capture_output=True,
            )
        finally:
            lean_path.unlink()
        require(
            elaborated.returncode == 0,
            f"{label} must elaborate:\n"
            + (elaborated.stderr or elaborated.stdout).strip(),
        )

    def require_lean_module_elaboration(
        label: str, modules: list[tuple[str, str]]
    ) -> None:
        with tempfile.TemporaryDirectory(dir=ROOT) as directory:
            module_root = Path(directory)
            environment = dict(os.environ)
            environment["LEAN_PATH"] = (
                str(module_root)
                + os.pathsep
                + environment.get("LEAN_PATH", "")
            )
            for module_name, source in modules:
                module_path = module_root / f"{module_name}.lean"
                module_path.write_text(source, encoding="utf-8")
                elaborated = subprocess.run(
                    [
                        "lake", "env", "lean",
                        "-o", str(module_root / f"{module_name}.olean"),
                        str(module_path),
                    ],
                    cwd=ROOT, env=environment, text=True, capture_output=True,
                )
                require(
                    elaborated.returncode == 0,
                    f"{label} must elaborate module {module_name}:\n"
                    + (elaborated.stderr or elaborated.stdout).strip(),
                )

    invalid_entry = require_fixture("invalid-entry.yaml")
    expect_failure(
        "invalid registry fixture",
        lambda: validate(invalid_entry),
        "registry.invariants[0].layer: value is not in schema enum",
    )
    data = validate()
    pins = source_pins()
    targets = external_source_targets(pins)
    source_anchor_positive = load_json_fixture("source-anchors-safe-positive.json")
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
        anchor = load_json_fixture(fixture)
        expect_failure(
            fixture,
            lambda anchor=anchor: validate_source_anchor(anchor, pins, targets),
            expected,
        )
    const_negative = load_json_fixture("const-one-negative.json")
    expect_failure(
        "boolean schema const fixture",
        lambda: validate_against_schema(const_negative, {"const": 1}, "fixture"),
        "fixture: does not match schema const",
    )
    const_positive = load_json_fixture("const-one-safe-positive.json")
    validate_against_schema(const_positive, {"const": 1}, "fixture")
    axiom_policy_mutant = load_json(TRUSTED_AXIOMS)
    axiom_policy_mutant = json.loads(json.dumps(axiom_policy_mutant))
    axiom_policy_mutant["allowed"].append("Classical.choice")
    axiom_policy_path = write_mutant(axiom_policy_mutant)
    try:
        expect_failure(
            "expanded trusted axiom allowlist",
            lambda: trusted_axioms(axiom_policy_path),
            "allowed axioms differ from fixed foundation",
        )
    finally:
        axiom_policy_path.unlink()
    missing_obligation_mutant = json.loads(json.dumps(data))
    missing_obligation_mutant["invariants"] = [
        row for row in missing_obligation_mutant["invariants"]
        if row["id"] != "SRV3-SOLIDITY-CORR"
    ]
    missing_obligation_path = write_mutant(missing_obligation_mutant)
    try:
        expect_failure(
            "missing invariant obligation mutant",
            lambda: validate(missing_obligation_path),
            "invariant ID inventory differs from expected obligations",
        )
    finally:
        missing_obligation_path.unlink()
    evidence_free_regression_mutant = json.loads(json.dumps(data))
    next(
        row for row in evidence_free_regression_mutant["invariants"]
        if row["id"] == "SRV3-SOLIDITY-CORR"
    )["status"] = "REGRESSION"
    evidence_free_regression_path = write_mutant(evidence_free_regression_mutant)
    try:
        expect_failure(
            "evidence-free REGRESSION mutant",
            lambda: validate(evidence_free_regression_path),
            "SRV3-SOLIDITY-CORR: priority/status/engine/layer differ from expected classification",
        )
    finally:
        evidence_free_regression_path.unlink()
    theorem_swap_mutant = json.loads(json.dumps(data))
    theorem_rows = {
        row["id"]: row for row in theorem_swap_mutant["invariants"]
        if row["id"] in EXPECTED_INVARIANT_THEOREMS
    }
    theorem_rows["SRV3-ARITH-CHECKED"]["theorem"], theorem_rows["SRV3-TX-REVERT"]["theorem"] = (
        theorem_rows["SRV3-TX-REVERT"]["theorem"],
        theorem_rows["SRV3-ARITH-CHECKED"]["theorem"],
    )
    theorem_swap_path = write_mutant(theorem_swap_mutant)
    try:
        expect_failure(
            "invariant theorem swap mutant",
            lambda: validate(theorem_swap_path),
            "SRV3-ARITH-CHECKED: theorem must be "
            "LidoSRv3.Audit.Quantity.checkedDiv_zero",
        )
    finally:
        theorem_swap_path.unlink()
    source_swap_mutant = json.loads(json.dumps(data))
    source_swap_rows = {row["id"]: row for row in source_swap_mutant["invariants"]}
    (
        source_swap_rows["SRV3-ARITH-CHECKED"]["source_anchors"],
        source_swap_rows["SRV3-TX-REVERT"]["source_anchors"],
    ) = (
        source_swap_rows["SRV3-TX-REVERT"]["source_anchors"],
        source_swap_rows["SRV3-ARITH-CHECKED"]["source_anchors"],
    )
    source_swap_path = write_mutant(source_swap_mutant)
    try:
        expect_failure(
            "assured invariant source-anchor swap mutant",
            lambda: validate(source_swap_path),
            "source anchors differ from expected obligation evidence",
        )
    finally:
        source_swap_path.unlink()
    open_source_mutant = json.loads(json.dumps(data))
    next(
        row for row in open_source_mutant["invariants"]
        if row["id"] == "SRV3-SOLIDITY-CORR"
    )["source_anchors"] = ["Makefile"]
    open_source_path = write_mutant(open_source_mutant)
    try:
        expect_failure(
            "open invariant source-evidence substitution mutant",
            lambda: validate(open_source_path),
            "SRV3-SOLIDITY-CORR: source anchors differ from expected "
            "obligation evidence",
        )
    finally:
        open_source_path.unlink()
    fabricated_runtime_mutant = json.loads(json.dumps(data))
    next(
        row for row in fabricated_runtime_mutant["invariants"]
        if row["id"] == "SRV3-EVM-RUNTIME"
    )["runtime_anchors"] = [
        "runtime=0x5f5ffd; sha256="
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    ]
    fabricated_runtime_path = write_mutant(fabricated_runtime_mutant)
    try:
        expect_failure(
            "blocked invariant fabricated runtime provenance mutant",
            lambda: validate(fabricated_runtime_path),
            "SRV3-EVM-RUNTIME: runtime anchors differ from expected "
            "obligation provenance",
        )
    finally:
        fabricated_runtime_path.unlink()
    validate()
    print("safe positive accepted: pinned blocked runtime provenance")
    family_mutant = json.loads(json.dumps(data))
    next(
        row for row in family_mutant["invariants"]
        if row["id"] == "SRV3-ARITH-CHECKED"
    )["family"] = "allocation"
    family_path = write_mutant(family_mutant)
    try:
        expect_failure(
            "invariant family substitution mutant",
            lambda: validate(family_path),
            "SRV3-ARITH-CHECKED: family differs from expected obligation family",
        )
    finally:
        family_path.unlink()
    cleared_limitations_mutant = json.loads(json.dumps(data))
    for row in cleared_limitations_mutant["invariants"]:
        row["assumptions"] = []
        row["trust_boundary"] = []
    cleared_limitations_path = write_mutant(cleared_limitations_mutant)
    try:
        expect_failure(
            "all invariant assumptions/trust-boundaries cleared mutant",
            lambda: validate(cleared_limitations_path),
            "assumptions differ from expected obligation limitations",
        )
    finally:
        cleared_limitations_path.unlink()
    for field, replacement, expected_error in (
        (
            "assumptions",
            [],
            "SRV3-ARITH-CHECKED: assumptions differ from expected obligation limitations",
        ),
        (
            "assumptions",
            ["Substituted assumption."],
            "SRV3-ARITH-CHECKED: assumptions differ from expected obligation limitations",
        ),
        (
            "trust_boundary",
            [],
            "SRV3-ARITH-CHECKED: trust boundary differs from expected obligation limitations",
        ),
        (
            "trust_boundary",
            ["Substituted trust boundary."],
            "SRV3-ARITH-CHECKED: trust boundary differs from expected obligation limitations",
        ),
    ):
        limitation_mutant = json.loads(json.dumps(data))
        next(
            row for row in limitation_mutant["invariants"]
            if row["id"] == "SRV3-ARITH-CHECKED"
        )[field] = replacement
        limitation_path = write_mutant(limitation_mutant)
        try:
            expect_failure(
                f"invariant {field} removal/substitution mutant",
                lambda path=limitation_path: validate(path),
                expected_error,
            )
        finally:
            limitation_path.unlink()
    added_limitation_mutant = json.loads(json.dumps(data))
    added_row = next(
        row for row in added_limitation_mutant["invariants"]
        if row["id"] == "SRV3-ARITH-CHECKED"
    )
    added_row["assumptions"].append("Added assumption.")
    added_row["trust_boundary"].append("Added trust boundary.")
    added_limitation_path = write_mutant(added_limitation_mutant)
    try:
        expect_failure(
            "invariant assumption/trust-boundary addition mutant",
            lambda: validate(added_limitation_path),
            "SRV3-ARITH-CHECKED: assumptions differ from expected obligation limitations",
        )
    finally:
        added_limitation_path.unlink()
    validate()
    print("safe positive accepted: exact invariant assumptions and trust boundaries")
    classification_mutant = json.loads(json.dumps(data))
    arithmetic_row = next(
        row for row in classification_mutant["invariants"]
        if row["id"] == "SRV3-ARITH-CHECKED"
    )
    arithmetic_row["engine"] = "VERITY"
    arithmetic_row["layer"] = "SRC"
    classification_path = write_mutant(classification_mutant)
    try:
        expect_failure(
            "assured invariant engine/layer swap mutant",
            lambda: validate(classification_path),
            "priority/status/engine/layer differ from expected classification",
        )
    finally:
        classification_path.unlink()
    blocked_classification_mutant = json.loads(json.dumps(data))
    next(
        row for row in blocked_classification_mutant["invariants"]
        if row["id"] == "SRV3-EVM-RUNTIME"
    )["status"] = "DEV-431-READY"
    blocked_classification_path = write_mutant(blocked_classification_mutant)
    try:
        expect_failure(
            "blocked invariant classification promotion mutant",
            lambda: validate(blocked_classification_path),
            "SRV3-EVM-RUNTIME: priority/status/engine/layer differ from expected classification",
        )
    finally:
        blocked_classification_path.unlink()
    priority_mutant = json.loads(json.dumps(data))
    next(
        row for row in priority_mutant["invariants"]
        if row["id"] == "SRV3-CONSOLIDATION-E2E"
    )["priority"] = "STRETCH"
    priority_path = write_mutant(priority_mutant)
    try:
        expect_failure(
            "critical obligation priority downgrade mutant",
            lambda: validate(priority_path),
            "SRV3-CONSOLIDATION-E2E: priority/status/engine/layer differ "
            "from expected classification",
        )
    finally:
        priority_path.unlink()
    reproduction_mutant = json.loads(json.dumps(data))
    next(
        row for row in reproduction_mutant["invariants"]
        if row["id"] == "SRV3-ARITH-CHECKED"
    )["reproduction"] = "true"
    reproduction_path = write_mutant(reproduction_mutant)
    try:
        expect_failure(
            "trivially-true reproduction command mutant",
            lambda: validate(reproduction_path),
            "SRV3-ARITH-CHECKED: reproduction differs from expected verification command",
        )
    finally:
        reproduction_path.unlink()
    falsifier_mutant = json.loads(json.dumps(data))
    next(
        row for row in falsifier_mutant["invariants"]
        if row["id"] == "SRV3-ARITH-CHECKED"
    )["falsifier"] = "No mutation can falsify this."
    falsifier_path = write_mutant(falsifier_mutant)
    try:
        expect_failure(
            "invariant falsifier substitution mutant",
            lambda: validate(falsifier_path),
            "SRV3-ARITH-CHECKED: falsifier differs from expected obligation claim",
        )
    finally:
        falsifier_path.unlink()
    dependency_graph_mutant = json.loads(json.dumps(data))
    next(
        row for row in dependency_graph_mutant["invariants"]
        if row["id"] == "SRV3-CONSOLIDATION-E2E"
    )["dependencies"] = []
    dependency_graph_path = write_mutant(dependency_graph_mutant)
    try:
        expect_failure(
            "required invariant dependency deletion mutant",
            lambda: validate(dependency_graph_path),
            "SRV3-CONSOLIDATION-E2E: dependencies differ from expected graph",
        )
    finally:
        dependency_graph_path.unlink()
    promotion_mutant = json.loads(json.dumps(data))
    next(
        row for row in promotion_mutant["invariants"]
        if row["id"] == "SRV3-LEGACY-ECON"
    )["status"] = "PROVED"
    promotion_path = write_mutant(promotion_mutant)
    try:
        expect_failure(
            "regression evidence promotion mutant",
            lambda: validate(promotion_path),
            "priority/status/engine/layer differ from expected classification",
        )
    finally:
        promotion_path.unlink()
    theorem_swap_mutant = json.loads(json.dumps(data))
    theorem_rows = {
        row["id"]: row for row in theorem_swap_mutant["invariants"]
        if row["id"] in EXPECTED_INVARIANT_THEOREMS
    }
    theorem_rows["SRV3-ALLOC-ORDER"]["theorem"], theorem_rows["SRV3-MINFIRST-BOUND"]["theorem"] = (
        theorem_rows["SRV3-MINFIRST-BOUND"]["theorem"],
        theorem_rows["SRV3-ALLOC-ORDER"]["theorem"],
    )
    theorem_swap_path = write_mutant(theorem_swap_mutant)
    try:
        expect_failure(
            "allocation/min-first theorem swap mutant",
            lambda: validate(theorem_swap_path),
            "SRV3-ALLOC-ORDER: theorem must be "
            "LidoSRv3.Audit.valid_result_preserves_router_order",
        )
    finally:
        theorem_swap_path.unlink()
    renamed_theorem_swap_mutant = json.loads(json.dumps(data))
    renamed_ids = {
        "SRV3-ALLOC-ORDER": "SRV3-ALLOC-ORDER-RENAMED",
        "SRV3-MINFIRST-BOUND": "SRV3-MINFIRST-BOUND-RENAMED",
    }
    renamed_rows = {
        row["id"]: row for row in renamed_theorem_swap_mutant["invariants"]
    }
    for old_id, new_id in renamed_ids.items():
        renamed_rows[old_id]["id"] = new_id
    for row in renamed_theorem_swap_mutant["invariants"]:
        row["dependencies"] = [
            renamed_ids.get(dependency, dependency)
            for dependency in row["dependencies"]
        ]
    renamed_rows["SRV3-ALLOC-ORDER"]["theorem"], renamed_rows["SRV3-MINFIRST-BOUND"]["theorem"] = (
        renamed_rows["SRV3-MINFIRST-BOUND"]["theorem"],
        renamed_rows["SRV3-ALLOC-ORDER"]["theorem"],
    )
    renamed_theorem_swap_path = write_mutant(renamed_theorem_swap_mutant)
    try:
        expect_failure(
            "renamed invariant theorem swap mutant",
            lambda: validate(renamed_theorem_swap_path),
            "invariant ID inventory differs from expected obligations",
        )
    finally:
        renamed_theorem_swap_path.unlink()
    dependency_downgrade_mutant = json.loads(json.dumps(data))
    next(
        row for row in dependency_downgrade_mutant["invariants"]
        if row["id"] == "SRV3-ALLOC-ORDER"
    )["status"] = "REGRESSION"
    dependency_downgrade_path = write_mutant(dependency_downgrade_mutant)
    try:
        expect_failure(
            "PROVED dependency downgrade mutant",
            lambda: validate(dependency_downgrade_path),
            "SRV3-ALLOC-ORDER: priority/status/engine/layer differ from expected classification",
        )
    finally:
        dependency_downgrade_path.unlink()
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
                "SRV3-ARITH-CHECKED: priority/status/engine/layer differ from expected classification",
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
            runtime_row["theorem"] = "LidoSRv3.Audit.revert_may_retain_attempts"
        runtime_path = write_mutant(runtime_mutant)
        try:
            expect_failure(
                f"sentinel-only runtime {assured_status} mutant",
                lambda runtime_path=runtime_path: validate(runtime_path),
                "SRV3-EVM-RUNTIME: priority/status/engine/layer differ from expected classification",
            )
        finally:
            runtime_path.unlink()
    for label, sentinel in (
        ("leading-whitespace", "  MISSING: canonical runtime"),
        ("lowercase", "missing: canonical runtime"),
    ):
        runtime_mutant = json.loads(json.dumps(data))
        runtime_row = next(
            row for row in runtime_mutant["invariants"]
            if row["id"] == "SRV3-EVM-RUNTIME"
        )
        runtime_row["status"] = "REGRESSION"
        runtime_row["runtime_anchors"] = [sentinel]
        runtime_row["dependencies"] = []
        runtime_path = write_mutant(runtime_mutant)
        try:
            expect_failure(
                f"{label} missing runtime sentinel mutant",
                lambda runtime_path=runtime_path: validate(runtime_path),
                "SRV3-EVM-RUNTIME: runtime anchors differ from expected "
                "obligation provenance",
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
    trust_meaning_mutant = load_json(ARTIFACTS)
    trust_meaning_mutant = json.loads(json.dumps(trust_meaning_mutant))
    trust_meaning_mutant["trust_levels"]["LEAN-CHECKED"] = (
        "Full certified Solidity and runtime correspondence."
    )
    trust_meaning_path = write_mutant(trust_meaning_mutant)
    try:
        expect_failure(
            "artifact trust-level meaning substitution mutant",
            lambda: validate_artifacts(trust_meaning_path),
            "artifact trust-level meanings differ from expected semantics",
        )
    finally:
        trust_meaning_path.unlink()
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
    blocker_mutant = load_json(ARTIFACTS)
    blocker_mutant = json.loads(json.dumps(blocker_mutant))
    next(
        artifact for artifact in blocker_mutant["artifacts"]
        if artifact["id"] == "consolidation-runtime"
    )["blocker"] = "Canonical runtime verified and production-ready"
    blocker_path = write_mutant(blocker_mutant)
    try:
        expect_failure(
            "contradictory unavailable-runtime blocker mutant",
            lambda: validate_artifacts(blocker_path),
            "consolidation-runtime: blocker differs from expected unavailable-artifact provenance",
        )
    finally:
        blocker_path.unlink()

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
    dbg_trace_mutant = require_fixture("dbg-trace-interpolation-negative.txt")
    require(
        any(":1:" in violation for violation in find_proof_escapes([
            (dbg_trace_mutant.name,
             dbg_trace_mutant.read_text(encoding="utf-8"))
        ])),
        "scanner dbg_trace interpolation fixture: unexpectedly passed",
    )
    print("mutant rejected: dbg_trace interpolated proof escape")
    multiline_dbg_trace_mutant = 'def bait : Nat := dbg_trace\n  "{(sorry : Nat)}"; 0\n'
    require(
        any(":2:" in violation for violation in find_proof_escapes([
            ("multiline-dbg-trace-mutant.lean", multiline_dbg_trace_mutant)
        ])),
        "scanner multiline dbg_trace interpolation mutant: unexpectedly passed",
    )
    print("mutant rejected: multiline dbg_trace interpolated proof escape")
    spaced_dbg_trace_mutant = (
        "def bait : Nat := dbg_trace\n"
        "  -- comment-only spacer\n"
        "\n"
        '  "{(sorry : Nat)}"; 0\n'
    )
    require(
        any(":4:" in violation for violation in find_proof_escapes([
            ("spaced-dbg-trace-mutant.lean", spaced_dbg_trace_mutant)
        ])),
        "scanner spaced dbg_trace interpolation mutant: unexpectedly passed",
    )
    print("mutant rejected: dbg_trace interpolation across blank/comment-only lines")
    custom_interpolation_mutant = (
        'syntax "x!" interpolatedStr(term) : term\n'
        'macro_rules | `(x! $s:interpolatedStr) => `(s! $s)\n'
        'def bait : String := x!"{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("custom-interpolation-mutant.lean", custom_interpolation_mutant)
        ]),
        "scanner custom interpolated-string macro mutant: unexpectedly passed",
    )
    print("mutant rejected: custom interpolated-string macro proof escape")
    unicode_interpolation_mutant = (
        'syntax "λ!" interpolatedStr(term) : term\n'
        'macro_rules | `(λ! $s:interpolatedStr) => `(s! $s)\n'
        'def bait : String := λ!"{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("unicode-interpolation-mutant.lean", unicode_interpolation_mutant)
        ]),
        "scanner Unicode interpolated-string macro mutant: unexpectedly passed",
    )
    print("mutant rejected: Unicode interpolated-string macro proof escape")
    non_bang_interpolation_mutant = (
        'syntax "x" interpolatedStr(term) : term\n'
        'macro_rules | `(x $s:interpolatedStr) => `(s! $s)\n'
        'def bait : String := x"{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("non-bang-interpolation-mutant.lean", non_bang_interpolation_mutant)
        ]),
        "scanner non-bang interpolated-string macro mutant: unexpectedly passed",
    )
    print("mutant rejected: non-bang interpolated-string macro proof escape")
    r_suffix_interpolation_mutant = require_fixture(
        "interpolation-r-suffix-negative.txt"
    )
    require(
        any(":2:" in violation for violation in find_proof_escapes([
            (r_suffix_interpolation_mutant.name,
             r_suffix_interpolation_mutant.read_text(encoding="utf-8"))
        ])),
        "scanner r-suffix interpolated-string macro mutant: unexpectedly passed",
    )
    print("mutant rejected: r-suffix custom interpolated-string proof escape")
    r_suffix_interpolation_safe = require_fixture(
        "interpolation-r-suffix-safe-positive.txt"
    )
    require(
        not find_proof_escapes([
            (r_suffix_interpolation_safe.name,
             r_suffix_interpolation_safe.read_text(encoding="utf-8"))
        ]),
        "scanner r-suffix interpolation safe-positive: unexpectedly rejected",
    )
    intermediate_interpolation_mutant = (
        'syntax "x" ident interpolatedStr(term) : term\n'
        'macro_rules | `(x $name:ident $s:interpolatedStr) => `(s! $s)\n'
        'def bait : String := x foo "{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("intermediate-interpolation-mutant.lean",
             intermediate_interpolation_mutant)
        ]),
        "scanner intermediate-parser interpolated-string mutant: unexpectedly passed",
    )
    print("mutant rejected: intermediate-parser interpolated-string macro proof escape")
    leading_parser_interpolation_mutant = (
        'syntax ident "x" interpolatedStr(term) : term\n'
        'macro_rules | `($name:ident x$s:interpolatedStr) => `(s! $s)\n'
        'def bait : String := foo x"{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("leading-parser-interpolation-mutant.lean",
             leading_parser_interpolation_mutant)
        ]),
        "scanner leading-parser interpolated-string mutant passed",
    )
    print("mutant rejected: interpolation after leading parser descriptor")
    wrapped_interpolation_mutant = (
        'set_option hygiene false in syntax "x" interpolatedStr(term) : term\n'
        'macro_rules | `(x $s:interpolatedStr) => `(s! $s)\n'
        'def bait : String := x"{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("set-option-wrapped-interpolation-mutant.lean",
             wrapped_interpolation_mutant)
        ]),
        "scanner set_option-wrapped interpolation declaration passed",
    )
    print("mutant rejected: set_option-wrapped interpolation declaration")
    multiline_interpolation_mutant = (
        'syntax "x" ident\n'
        '-- declaration continuation after trivia\n'
        '\n'
        '  interpolatedStr(term) : term\n'
        'macro_rules | `(x $name:ident $s:interpolatedStr) => `(s! $s)\n'
        'def bait : String := x foo "{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("multiline-interpolation-mutant.lean",
             multiline_interpolation_mutant)
        ]),
        "scanner multiline interpolated-string syntax mutant: unexpectedly passed",
    )
    print("mutant rejected: multiline interpolated-string syntax proof escape")
    block_comment_interpolation_mutant = (
        'local syntax "x" ident\n'
        '/- declaration continuation\n'
        '   after multiline block-comment trivia -/\n'
        '  interpolatedStr(term) : term\n'
        'macro_rules | `(x $name:ident $s:interpolatedStr) => `(s! $s)\n'
        'def bait : String := x foo "{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("block-comment-interpolation-mutant.lean",
             block_comment_interpolation_mutant)
        ]),
        "scanner local multiline interpolation with block-comment trivia passed",
    )
    print("mutant rejected: local multiline interpolation across block-comment trivia")
    nested_layout_interpolation_mutant = (
        'local syntax "nested" (\n'
        '  ident\n'
        ') interpolatedStr(term) : term\n'
        'macro_rules | `(nested $name:ident $s:interpolatedStr) => `(s! $s)\n'
        'def bait : String := nested foo "{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("nested-layout-interpolation-mutant.lean",
             nested_layout_interpolation_mutant)
        ]),
        "scanner interpolation with nested multiline parser construct passed",
    )
    print("mutant rejected: interpolation after nested multiline parser construct")
    macro_interpolation_mutant = (
        'local macro "x" s:interpolatedStr : term => `(s! $s)\n'
        'def bait : String := x"{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("macro-interpolation-mutant.lean", macro_interpolation_mutant)
        ]),
        "scanner direct macro interpolation declaration passed",
    )
    print("mutant rejected: direct macro interpolation declaration")
    multiline_invocation_mutant = (
        'syntax "x" ident interpolatedStr(term) : term\n'
        'macro_rules | `(x $name:ident $s:interpolatedStr) => `(s! $s)\n'
        'def bait : String := x\n'
        '  foo\n'
        '  "{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("multiline-invocation-mutant.lean", multiline_invocation_mutant)
        ]),
        "scanner multiline custom interpolation invocation passed",
    )
    print("mutant rejected: multiline custom interpolation invocation")
    delimiter_contained_interpolation_mutant = (
        'syntax ident ident interpolatedStr(term) : term\n'
        'macro_rules | `($x:ident $name:ident $s:interpolatedStr) => `(s! $s)\n'
        '#check (x\n'
        'foo\n'
        '"{(sorry : Nat)}")\n'
    )
    require_lean_elaboration(
        "scanner delimiter-contained multiline interpolation",
        delimiter_contained_interpolation_mutant,
    )
    require(
        find_proof_escapes([
            ("delimiter-contained-interpolation.lean",
             delimiter_contained_interpolation_mutant)
        ]),
        "scanner delimiter-contained multiline interpolation mutant passed",
    )
    print("mutant rejected: delimiter-contained multiline interpolation context")
    safe_dbg_trace = 'def safe : Nat := dbg_trace "ordinary sorry text {1 + 1}"; 0\n'
    require(
        not find_proof_escapes([("safe-dbg-trace.lean", safe_dbg_trace)]),
        "scanner dbg_trace safe-positive: unexpectedly rejected",
    )
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
    hash_prefix = require_fixture("interpolation-hash-prefix-negative.txt")
    hash_prefix_source = hash_prefix.read_text(encoding="utf-8")
    require_lean_elaboration("scanner hash-suffixed interpolation prefix",
                             hash_prefix_source)
    hash_prefix_violations = find_proof_escapes(
        [(hash_prefix.name, hash_prefix_source)]
    )
    require(
        any(":3:" in violation for violation in hash_prefix_violations),
        "scanner hash-suffixed interpolation prefix mutant passed",
    )
    print("mutant rejected: hash-suffixed interpolation prefix")
    hash_r_prefix = require_fixture("interpolation-hash-r-prefix-negative.txt")
    hash_r_prefix_source = hash_r_prefix.read_text(encoding="utf-8")
    require_lean_elaboration("scanner combined hash/r interpolation prefix",
                             hash_r_prefix_source)
    hash_r_prefix_violations = find_proof_escapes(
        [(hash_r_prefix.name, hash_r_prefix_source)]
    )
    require(
        any(":3:" in violation for violation in hash_r_prefix_violations),
        "scanner combined hash/r interpolation prefix mutant passed",
    )
    print("mutant rejected: combined hash/r interpolation prefix")
    token_boundary = require_fixture(
        "interpolation-token-boundary-safe-positive.txt"
    )
    token_boundary_source = token_boundary.read_text(encoding="utf-8")
    require_lean_elaboration("scanner interpolation token-boundary safe positive",
                             token_boundary_source)
    require(
        not find_proof_escapes([(token_boundary.name, token_boundary_source)]),
        "scanner interpolation token-boundary safe positive was rejected",
    )
    print("safe positive accepted: interpolation prefix token boundary")
    bodyless_opaque = (
        '@[extern "bad"]\nprivate protected opaque\n'
        '  bad :\n  False\n'
    )
    require(
        find_proof_escapes([("bodyless-opaque.lean", bodyless_opaque)]),
        "scanner bodyless attributed/multiline/private/protected opaque mutant passed",
    )
    multiline_attribute_opaque = (
        "@[extern\n"
        '  "bad"] opaque hidden : False\n'
    )
    require(
        find_proof_escapes([
            ("multiline-attribute-bodyless-opaque.lean",
             multiline_attribute_opaque)
        ]),
        "scanner multiline-attribute bodyless opaque mutant passed",
    )
    print("mutant rejected: multiline-attribute bodyless opaque")
    for label, following_command in (
        ("example", "example : True := by trivial"),
        ("eval", "#eval (let x := 1; x)"),
    ):
        opaque_boundary_mutant = (
            "opaque hidden : False\n"
            f"{following_command}\n"
        )
        require(
            find_proof_escapes([
                (f"bodyless-opaque-before-{label}.lean", opaque_boundary_mutant)
            ]),
            f"scanner bodyless opaque before {label} command mutant passed",
        )
        print(f"mutant rejected: bodyless opaque before {label} command")
    wrapped_opaque_mutant = (
        "set_option autoImplicit false in opaque hidden : False\n"
    )
    require(
        find_proof_escapes([
            ("set-option-wrapped-bodyless-opaque.lean", wrapped_opaque_mutant)
        ]),
        "scanner set_option-wrapped bodyless opaque mutant passed",
    )
    print("mutant rejected: set_option-wrapped bodyless opaque")
    attributed_wrapped_opaque_mutant = (
        "set_option autoImplicit false in @[inline] opaque hidden : Nat\n"
    )
    require(
        find_proof_escapes([
            ("attributed-set-option-bodyless-opaque.lean",
             attributed_wrapped_opaque_mutant)
        ]),
        "scanner attributed set_option-wrapped bodyless opaque mutant passed",
    )
    print("mutant rejected: attributed set_option-wrapped bodyless opaque")
    multiline_wrapped_opaque_mutant = (
        "set_option autoImplicit false in\n"
        "  /- wrapper trivia\n"
        "     across lines -/\n"
        "  opaque hidden : False\n"
    )
    require(
        find_proof_escapes([
            ("multiline-set-option-wrapped-bodyless-opaque.lean",
             multiline_wrapped_opaque_mutant)
        ]),
        "scanner multiline set_option-wrapped bodyless opaque mutant passed",
    )
    print("mutant rejected: multiline set_option-wrapped bodyless opaque")
    for modifier, following in (
        ("local", "local def innocent := 1"),
        ("scoped", 'scoped macro "innocent" : command => '
                   '`(example : True := by trivial)'),
    ):
        modified_boundary_mutant = (
            "opaque hidden : False\n"
            "-- comment-only boundary trivia\n"
            "\n"
            f"{following}\n"
        )
        require(
            find_proof_escapes([
                (f"bodyless-opaque-before-{modifier}-command.lean",
                 modified_boundary_mutant)
            ]),
            f"scanner bodyless opaque before {modifier} command mutant passed",
        )
        print(f"mutant rejected: bodyless opaque before {modifier} command")
    for label, source in (
        (
            "indented-same-line-leading-block-comment",
            "namespace ScannerMutant\n"
            "  /- leading command trivia -/ opaque hidden : Nat\n"
            "  def innocent := 1\n"
            "end ScannerMutant\n",
        ),
        (
            "same-line-leading-block-comment",
            "/- leading command trivia -/ opaque hidden : Nat\n",
        ),
        (
            "same-line-leading-nested-block-comment",
            "/- outer /- nested -/ trivia -/ opaque hidden : Nat\n",
        ),
        (
            "leading-multiline-block-comment",
            "/- leading command\n"
            "   trivia -/ opaque hidden : Nat\n",
        ),
        (
            "leading-block-comment",
            "opaque hidden : False\n"
            "/- command-boundary trivia -/ def innocent := 1\n",
        ),
        (
            "multiline-block-comment",
            "opaque hidden : False /- command-boundary trivia\n"
            "-/ def innocent := 1\n",
        ),
        (
            "nested-multiline-block-comment",
            "opaque hidden : False /- outer /- nested -/ trivia\n"
            "-/ def innocent := 1\n",
        ),
    ):
        require(
            find_proof_escapes([(f"bodyless-opaque-{label}.lean", source)]),
            f"scanner bodyless opaque before {label} trivia mutant passed",
        )
        print(f"mutant rejected: bodyless opaque before {label} trivia")
    custom_command_mutant = (
        'syntax "audit-cmd" ":=" term : command\n'
        "macro_rules | `(audit-cmd := $term) => `(example : True := $term)\n"
        "opaque hidden : Nat\n"
        "audit-cmd := by trivial\n"
    )
    require(
        find_proof_escapes([
            ("bodyless-opaque-before-custom-command.lean", custom_command_mutant)
        ]),
        "scanner bodyless opaque before custom command mutant passed",
    )
    print("mutant rejected: bodyless opaque before custom command")
    multiline_custom_command_mutant = (
        'syntax "audit-cmd"\n'
        '-- declaration continuation after trivia\n'
        '\n'
        '  ":=" term : command\n'
        "macro_rules | `(audit-cmd := $term) => `(example : True := $term)\n"
        "opaque hidden : Nat\n"
        "audit-cmd := by trivial\n"
    )
    require(
        find_proof_escapes([
            ("bodyless-opaque-before-multiline-custom-command.lean",
             multiline_custom_command_mutant)
        ]),
        "scanner bodyless opaque before multiline custom command mutant passed",
    )
    print("mutant rejected: bodyless opaque before multiline custom command")
    scoped_custom_command_mutant = (
        "namespace AuditScannerMutant\n"
        'scoped syntax "audit-cmd"\n'
        '/- declaration continuation\n'
        '   after multiline block-comment trivia -/\n'
        '  ":=" term : command\n'
        "scoped macro_rules | `(audit-cmd := $term) => `(example : True := $term)\n"
        "end AuditScannerMutant\n"
        "open scoped AuditScannerMutant\n"
        "opaque hidden : Nat\n"
        "audit-cmd := by trivial\n"
    )
    require(
        find_proof_escapes([
            ("bodyless-opaque-before-scoped-custom-command.lean",
             scoped_custom_command_mutant)
        ]),
        "scanner bodyless opaque before scoped multiline custom command passed",
    )
    print("mutant rejected: bodyless opaque before scoped multiline custom command")
    wrapped_custom_command_mutant = (
        'set_option hygiene false in syntax "audit-cmd" ":=" term : command\n'
        "macro_rules | `(audit-cmd := $term) => `(example : True := $term)\n"
        "opaque hidden : Nat\n"
        "audit-cmd := by trivial\n"
    )
    require(
        find_proof_escapes([
            ("bodyless-opaque-before-wrapped-custom-command.lean",
             wrapped_custom_command_mutant)
        ]),
        "scanner bodyless opaque before set_option-wrapped custom command passed",
    )
    print("mutant rejected: bodyless opaque before set_option-wrapped custom command")
    macro_generated_opaque_mutant = (
        'macro "mkBad " n:ident : command => `(opaque $n : False)\n'
        "mkBad hidden\n"
    )
    require(
        find_proof_escapes([
            ("macro-generated-bodyless-opaque.lean",
             macro_generated_opaque_mutant)
        ]),
        "scanner macro-generated bodyless opaque mutant passed",
    )
    print("mutant rejected: macro-generated bodyless opaque")
    wrapped_macro_generated_opaque_mutant = (
        'macro "mkBad " n:ident : command => `(\n'
        "  set_option autoImplicit false in\n"
        "  set_option pp.universes true in\n"
        "  @[deprecated \"hidden\"] private opaque $n : False)\n"
        "mkBad hidden\n"
    )
    require(
        find_proof_escapes([
            ("wrapped-macro-generated-bodyless-opaque.lean",
             wrapped_macro_generated_opaque_mutant)
        ]),
        "scanner wrapped macro-generated bodyless opaque mutant passed",
    )
    print("mutant rejected: wrapped macro-generated bodyless opaque")
    category_qualified_macro_opaque_mutant = (
        'macro "mkBad" : command => `(\n'
        "  command| set_option autoImplicit false in opaque hidden : False)\n"
        "mkBad\n"
    )
    require(
        find_proof_escapes([
            ("category-qualified-macro-bodyless-opaque.lean",
             category_qualified_macro_opaque_mutant)
        ]),
        "scanner category-qualified macro-generated bodyless opaque mutant passed",
    )
    print("mutant rejected: category-qualified macro-generated bodyless opaque")
    literal_free_interpolation_mutant = (
        "macro name:ident value:interpolatedStr(term) : term => `(s!$value)\n"
        '#check foo"{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("literal-free-interpolation.lean",
             literal_free_interpolation_mutant)
        ]),
        "scanner literal-free interpolation mutant passed",
    )
    print("mutant rejected: literal-free interpolation syntax")
    numeral_interpolation_mutant = (
        "macro n:num value:interpolatedStr(term) : term => `(s!$value)\n"
        '#check 1 "{(sorry : Nat)}"\n'
    )
    require_lean_elaboration(
        "scanner numeral interpolation mutant",
        numeral_interpolation_mutant,
    )
    require(
        find_proof_escapes([
            ("numeral-literal-free-interpolation.lean",
             numeral_interpolation_mutant)
        ]),
        "scanner numeral literal-free interpolation mutant passed",
    )
    print("mutant rejected: elaborated numeral literal-free interpolation syntax")
    adjacent_parser_mutant = (
        "macro n:num x:ident value:interpolatedStr(term) : command => "
        "`(#check s!$value)\n"
        '123 foo"{(sorry : Nat)}"\n'
    )
    require_lean_elaboration(
        "scanner adjacent interpolation parser mutant",
        adjacent_parser_mutant,
    )
    require(
        find_proof_escapes([
            ("adjacent-interpolation-parser.lean", adjacent_parser_mutant)
        ]),
        "scanner ignored the parser adjacent to interpolatedStr",
    )
    print("mutant rejected: adjacent interpolation parser descriptor")
    for cardinality in ("*", "?"):
        parser = (
            f"xs:ident{cardinality}"
            if cardinality == "*"
            else "xs:ident ?"
        )
        if cardinality == "*":
            nullable_interpolation_mutant = (
                f"macro {parser} "
                "value:interpolatedStr(term) : command => `(#check s!$value)\n"
                '"{(sorry : Nat)}"\n'
            )
        else:
            nullable_interpolation_mutant = (
                f"macro:10000 {parser} "
                "value:interpolatedStr(term) : term => `(s!$value)\n"
                '#check "{(sorry : Nat)}"\n'
            )
        require_lean_elaboration(
            f"scanner nullable {cardinality} interpolation mutant",
            nullable_interpolation_mutant,
        )
        require(
            find_proof_escapes([
                (f"nullable-{cardinality}-interpolation.lean",
                 nullable_interpolation_mutant)
            ]),
            f"scanner nullable {cardinality} interpolation mutant passed",
        )
        print(
            f"mutant rejected: elaborated nullable {cardinality} "
            "interpolation syntax"
        )
    commented_nullable_interpolation_mutant = (
        "macro xs:ident /- outer /- nested -/ trivia -/ * "
        "value:interpolatedStr(term) : command => `(#check s!$value)\n"
        '"{(sorry : Nat)}"\n'
    )
    require_lean_elaboration(
        "scanner commented nullable interpolation mutant",
        commented_nullable_interpolation_mutant,
    )
    require(
        find_proof_escapes([
            ("commented-nullable-interpolation.lean",
             commented_nullable_interpolation_mutant)
        ]),
        "scanner commented nullable interpolation mutant passed",
    )
    print("mutant rejected: elaborated commented nullable interpolation syntax")
    repository_global_nullable_safe = (
        (
            "local-nullable.lean",
            'local macro xs:ident* value:interpolatedStr(term) : command => '
            '`(example : True := by trivial)\n',
        ),
        ("unrelated.lean", 'def inert : String := "{sorry}"\n'),
    )
    require(
        not find_proof_escapes(list(repository_global_nullable_safe)),
        "scanner repository-global nullable interpolation safe-positive was rejected",
    )
    print("safe positive accepted: nullable interpolation remains source-scoped")
    imported_nullable_declaration = require_fixture(
        "imported-nullable-declaration-negative.txt"
    ).read_text(encoding="utf-8")
    imported_nullable_consumer = require_fixture(
        "imported-nullable-consumer-negative.txt"
    ).read_text(encoding="utf-8")
    require_lean_module_elaboration(
        "scanner imported nullable interpolation mutant",
        [
            ("ImportedNullableDeclaration", imported_nullable_declaration),
            ("ImportedNullableConsumer", imported_nullable_consumer),
        ],
    )
    require(
        find_proof_escapes([
            ("ImportedNullableDeclaration.lean", imported_nullable_declaration),
            ("ImportedNullableConsumer.lean", imported_nullable_consumer),
        ]),
        "scanner imported nullable interpolation mutant passed",
    )
    print("mutant rejected: elaborated imported nullable interpolation syntax")
    unimported_nullable_safe_positive = (
        imported_nullable_declaration,
        'def inertUnimportedNullable : String := "{sorry}"\n',
    )
    require_lean_module_elaboration(
        "scanner unimported nullable interpolation safe positive",
        [
            ("ImportedNullableDeclaration", unimported_nullable_safe_positive[0]),
            ("UnimportedNullableSafe", unimported_nullable_safe_positive[1]),
        ],
    )
    require(
        not find_proof_escapes([
            ("ImportedNullableDeclaration.lean",
             unimported_nullable_safe_positive[0]),
            ("UnimportedNullableSafe.lean", unimported_nullable_safe_positive[1]),
        ]),
        "scanner unimported nullable interpolation safe positive was rejected",
    )
    print("safe positive accepted: nullable syntax remains import-scoped")
    wrapped_local_safe_positive = (
        "set_option hygiene false in local macro "
        "xs:ident* value:interpolatedStr(term) : command => "
        "`(example : True := by trivial)\n"
    )
    wrapped_local_consumer = (
        'import WrappedLocal\n'
        'def inert : String := "{sorry}"\n'
    )
    require_lean_module_elaboration(
        "scanner set_option-wrapped local interpolation safe positive",
        [
            ("WrappedLocal", wrapped_local_safe_positive),
            ("WrappedLocalConsumer", wrapped_local_consumer),
        ],
    )
    require(
        not find_proof_escapes([
            ("WrappedLocal.lean", wrapped_local_safe_positive),
            ("WrappedLocalConsumer.lean", wrapped_local_consumer),
        ]),
        "scanner set_option-wrapped local interpolation leaked through import",
    )
    print("safe positive accepted: set_option-wrapped local syntax is not exported")
    scoped_declaration = require_fixture(
        "scoped-interpolation-declaration.txt"
    ).read_text(encoding="utf-8")
    scoped_consumer = require_fixture(
        "scoped-interpolation-consumer-safe-positive.txt"
    ).read_text(encoding="utf-8")
    scoped_open_consumer = require_fixture(
        "scoped-interpolation-consumer-negative.txt"
    ).read_text(encoding="utf-8")
    require_lean_module_elaboration(
        "scanner scoped interpolation activation",
        [
            ("ScopedDecl", scoped_declaration),
            ("ScopedConsumer", scoped_consumer),
            ("ScopedOpenConsumer", scoped_open_consumer),
        ],
    )
    require(
        not find_proof_escapes([
            ("ScopedDecl.lean", scoped_declaration),
            ("ScopedConsumer.lean", scoped_consumer),
        ]),
        "scanner activated scoped interpolation without open scoped",
    )
    require(
        find_proof_escapes([
            ("ScopedDecl.lean", scoped_declaration),
            ("ScopedOpenConsumer.lean", scoped_open_consumer),
        ]),
        "scanner missed open-scoped interpolation proof escape",
    )
    print("mutant rejected: scoped interpolation activates only after open scoped")
    namespace_section_scoped_mutant = require_fixture(
        "namespace-section-scoped-nullable-negative.txt"
    ).read_text(encoding="utf-8")
    require_lean_elaboration(
        "scanner namespace/section scoped nullable interpolation mutant",
        namespace_section_scoped_mutant,
    )
    require(
        find_proof_escapes(
            [
                (
                    "namespace-section-scoped-nullable-negative.lean",
                    namespace_section_scoped_mutant,
                ),
            ]
        ),
        "scanner namespace/section scoped nullable interpolation mutant passed",
    )
    print("mutant rejected: section end preserves namespace-scoped activation")
    scope_state_attack_corpus = (
        (
            "named-section-preserves-namespace",
            "namespace ScopeFamily\n"
            "section First\n"
            "end First\n"
            "open scoped ScopeFamily\n"
            "scoped macro xs:ident* value:interpolatedStr(term) : command => "
            "`(#check s!$value)\n"
            '"{(sorry : Nat)}"\n'
            "end ScopeFamily\n",
            True,
        ),
        (
            "anonymous-section-preserves-namespace",
            "namespace ScopeFamily\n"
            "section\n"
            "end\n"
            "open scoped ScopeFamily\n"
            "scoped macro xs:ident* value:interpolatedStr(term) : command => "
            "`(#check s!$value)\n"
            '"{(sorry : Nat)}"\n'
            "end ScopeFamily\n",
            True,
        ),
        (
            "section-activation-does-not-leak",
            "namespace ScopeFamily\n"
            "scoped macro xs:ident* value:interpolatedStr(term) : command => "
            "`(#check s!$value)\n"
            "section Inner\n"
            "open scoped ScopeFamily\n"
            "end Inner\n"
            'def inertAfterSection : String := "{sorry}"\n'
            "end ScopeFamily\n",
            False,
        ),
        (
            "outer-activation-survives-inner-section",
            "namespace ScopeFamily\n"
            "open scoped ScopeFamily\n"
            "section Inner\n"
            "end Inner\n"
            "scoped macro xs:ident* value:interpolatedStr(term) : command => "
            "`(#check s!$value)\n"
            '"{(sorry : Nat)}"\n'
            "end ScopeFamily\n",
            True,
        ),
        (
            "nested-namespace-pop-is-typed",
            "namespace ScopeFamily\n"
            "namespace Nested\n"
            "section Inner\n"
            "end Inner\n"
            "end Nested\n"
            "open scoped ScopeFamily\n"
            "scoped macro xs:ident* value:interpolatedStr(term) : command => "
            "`(#check s!$value)\n"
            '"{(sorry : Nat)}"\n'
            "end ScopeFamily\n",
            True,
        ),
        (
            "literal-comment-delimiters-do-not-hide-state",
            'def openMarker : String := "/-"\n'
            'def closeMarker : String := "-/"\n'
            "namespace ScopeFamily\n"
            "section Inner\n"
            "end Inner\n"
            "open scoped ScopeFamily\n"
            "scoped macro xs:ident* value:interpolatedStr(term) : command => "
            "`(#check s!$value)\n"
            '"{(sorry : Nat)}"\n'
            "end ScopeFamily\n",
            True,
        ),
    )
    for label, attack_source, should_reject in scope_state_attack_corpus:
        require_lean_elaboration(f"scanner scope-state family {label}", attack_source)
        rejected = bool(
            find_proof_escapes([(f"scope-state-{label}.lean", attack_source)])
        )
        require(
            rejected == should_reject,
            f"scanner scope-state family {label}: wrong activation result",
        )
    print("attack family rejected: typed namespace/section activation corpus")
    qualified_end_negative = require_fixture(
        "qualified-end-scoped-interpolation-negative.txt"
    ).read_text(encoding="utf-8")
    qualified_end_safe = require_fixture(
        "qualified-end-scoped-interpolation-safe-positive.txt"
    ).read_text(encoding="utf-8")
    require_lean_elaboration(
        "scanner qualified end scoped interpolation mutant",
        qualified_end_negative,
    )
    require_lean_elaboration(
        "scanner qualified end scoped interpolation safe positive",
        qualified_end_safe,
    )
    require(
        find_proof_escapes([
            ("qualified-end-scoped-negative.lean", qualified_end_negative)
        ]),
        "scanner qualified end left stale namespace state",
    )
    require(
        not find_proof_escapes([
            ("qualified-end-scoped-safe.lean", qualified_end_safe)
        ]),
        "scanner qualified end activated an unopened scoped parser",
    )
    print("mutant rejected: qualified end restores scoped namespace state")
    ordered_activation_safe = (
        'def inertBeforeDeclaration : String := "{sorry}"\n'
        "macro xs:ident* value:interpolatedStr(term) : command => "
        "`(#check s!$value)\n"
    )
    require_lean_elaboration(
        "scanner declaration-order safe positive", ordered_activation_safe
    )
    require(
        not find_proof_escapes([
            ("declaration-order-safe.lean", ordered_activation_safe)
        ]),
        "scanner applied nullable syntax before its declaration",
    )
    print("safe positive accepted: nullable syntax activates in source order")
    expired_local_safe = (
        "section LocalSyntax\n"
        "local macro xs:ident* value:interpolatedStr(term) : command => "
        "`(#check s!$value)\n"
        "end LocalSyntax\n"
        'def inertAfterLocal : String := "{sorry}"\n'
    )
    require_lean_elaboration(
        "scanner expired local syntax safe positive",
        expired_local_safe,
    )
    require(
        not find_proof_escapes([
            ("expired-local-syntax-safe.lean", expired_local_safe)
        ]),
        "scanner kept local interpolation active after section end",
    )
    print("safe positive accepted: local syntax expires at section end")
    literal_prefix_declaration = require_fixture(
        "literal-prefix-declaration-negative.txt"
    ).read_text(encoding="utf-8")
    literal_prefix_consumer = require_fixture(
        "literal-prefix-consumer-negative.txt"
    ).read_text(encoding="utf-8")
    literal_prefix_nonleak_safe = require_fixture(
        "literal-prefix-nonleak-safe-positive.txt"
    ).read_text(encoding="utf-8")
    literal_prefix_before_safe = require_fixture(
        "literal-prefix-before-declaration-safe-positive.txt"
    ).read_text(encoding="utf-8")
    require_lean_module_elaboration(
        "scanner literal-prefix module activation",
        [
            ("LiteralPrefixDeclaration", literal_prefix_declaration),
            ("LiteralPrefixConsumer", literal_prefix_consumer),
            ("LiteralPrefixNonleak", literal_prefix_nonleak_safe),
            ("LiteralPrefixBefore", literal_prefix_before_safe),
        ],
    )
    require(
        find_proof_escapes([
            ("LiteralPrefixDeclaration.lean", literal_prefix_declaration),
            ("LiteralPrefixConsumer.lean", literal_prefix_consumer),
        ]),
        "scanner missed imported literal-prefix interpolation proof escape",
    )
    require(
        not find_proof_escapes([
            ("LiteralPrefixDeclaration.lean", literal_prefix_declaration),
            ("LiteralPrefixNonleak.lean", literal_prefix_nonleak_safe),
        ]),
        "scanner leaked literal-prefix interpolation across modules",
    )
    require(
        not find_proof_escapes([
            ("LiteralPrefixBefore.lean", literal_prefix_before_safe)
        ]),
        "scanner activated literal-prefix interpolation before declaration",
    )
    print("mutant rejected: literal prefixes obey module and source order")
    public_import_declaration = (
        "macro xs:ident* value:interpolatedStr(term) : command => "
        "`(#check s!$value)\n"
    )
    public_import_bridge = "module\npublic import PublicNullableDeclaration\n"
    public_import_consumer = (
        "import PublicNullableBridge\n"
        '"{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("PublicNullableDeclaration.lean", public_import_declaration),
            ("PublicNullableBridge.lean", public_import_bridge),
            ("PublicNullableConsumer.lean", public_import_consumer),
        ]),
        "scanner public-import nullable interpolation mutant passed",
    )
    print("mutant rejected: public imports propagate nullable syntax")
    multiline_import_consumer = (
        "import Base /- comment\n"
        "-/ PublicNullableDeclaration\n"
        '"{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("Base.lean", "def base : Nat := 0\n"),
            ("PublicNullableDeclaration.lean", public_import_declaration),
            ("MultilineImportConsumer.lean", multiline_import_consumer),
        ]),
        "scanner multiline-import nullable interpolation mutant passed",
    )
    print("mutant rejected: multiline imports preserve module activation")
    import_attack_declaration = (
        "macro xs:ident* value:interpolatedStr(term) : command => "
        "`(#check s!$value)\n"
    )
    import_attack_corpus = (
        (
            "transitive-public-import",
            [
                ("ImportAttackDecl.lean", import_attack_declaration),
                (
                    "ImportAttackBridge.lean",
                    "module\npublic import ImportAttackDecl\n",
                ),
                (
                    "ImportAttackConsumer.lean",
                    "import ImportAttackBridge\n"
                    '"{(sorry : Nat)}"\n',
                ),
            ],
            True,
        ),
        (
            "commented-alias-decoy",
            [
                ("ImportBase.lean", "def base : Nat := 0\n"),
                ("AliasDecoy.lean", import_attack_declaration),
                (
                    "ImportAliasSafe.lean",
                    "import ImportBase -- as AliasDecoy\n"
                    'def inertAliasDecoy : String := "{sorry}"\n',
                ),
            ],
            False,
        ),
        (
            "multiline-commented-alias-decoy",
            [
                ("ImportBase.lean", "def base : Nat := 0\n"),
                ("AliasDecoy.lean", import_attack_declaration),
                (
                    "ImportAliasMultilineSafe.lean",
                    "import ImportBase /- as\n AliasDecoy -/\n"
                    'def inertAliasDecoy : String := "{sorry}"\n',
                ),
            ],
            False,
        ),
    )
    for label, attack_sources, should_reject in import_attack_corpus:
        if label != "transitive-public-import":
            require_lean_module_elaboration(
                f"scanner import family {label}",
                [
                    (name.removesuffix(".lean"), text)
                    for name, text in attack_sources
                ],
            )
        rejected = bool(find_proof_escapes(attack_sources))
        require(
            rejected == should_reject,
            f"scanner import family {label}: wrong activation result",
        )
    print("attack family rejected: import/multiline/alias activation corpus")
    option_string_declaration = (
        'set_option customName "in local " in '
        "macro xs:ident* value:interpolatedStr(term) : command => "
        "`(#check s!$value)\n"
    )
    option_string_consumer = (
        "import OptionStringDeclaration\n"
        '"{(sorry : Nat)}"\n'
    )
    require(
        find_proof_escapes([
            ("OptionStringDeclaration.lean", option_string_declaration),
            ("OptionStringConsumer.lean", option_string_consumer),
        ]),
        "scanner option-string wrapper hid an exported nullable declaration",
    )
    print("mutant rejected: wrapper strings cannot spoof local activation")
    import_comment_safe_positive = (
        'import Base -- Decl\n'
        'def inert : String := "{sorry}"\n'
    )
    require_lean_module_elaboration(
        "scanner import-comment safe positive",
        [
            ("Base", "def base : Nat := 0\n"),
            (
                "Decl",
                "macro xs:ident* value:interpolatedStr(term) : command => "
                "`(example : True := by trivial)\n",
            ),
            ("ImportCommentConsumer", import_comment_safe_positive),
        ],
    )
    require(
        not find_proof_escapes([
            ("Base.lean", "def base : Nat := 0\n"),
            (
                "Decl.lean",
                "macro xs:ident* value:interpolatedStr(term) : command => "
                "`(example : True := by trivial)\n",
            ),
            ("ImportCommentConsumer.lean", import_comment_safe_positive),
        ]),
        "scanner parsed a Lean import comment as a module name",
    )
    print("safe positive accepted: Lean import comments do not add modules")
    separated_nullable_interpolation_mutant = (
        "macro xs:ident,* value:interpolatedStr(term) : command => "
        "`(#check s!$value)\n"
        '"{(sorry : Nat)}"\n'
    )
    require_lean_elaboration(
        "scanner separator-repetition interpolation mutant",
        separated_nullable_interpolation_mutant,
    )
    require(
        find_proof_escapes([
            ("separator-repetition-interpolation.lean",
             separated_nullable_interpolation_mutant)
        ]),
        "scanner separator-repetition interpolation mutant passed",
    )
    print("mutant rejected: elaborated separator-repetition interpolation syntax")
    nonnullable_interpolation_safe_positive = (
        "macro xs:ident+ "
        "value:interpolatedStr(term) : command => `(#check s!$value)\n"
        'def interpolationExample := "{(sorry : Nat)}"\n'
    )
    require_lean_elaboration(
        "scanner nonnullable interpolation safe positive",
        nonnullable_interpolation_safe_positive,
    )
    require(
        not find_proof_escapes([
            ("nonnullable-interpolation-safe.lean",
             nonnullable_interpolation_safe_positive)
        ]),
        "scanner nonnullable interpolation safe positive was rejected",
    )
    separated_nonnullable_interpolation_safe_positive = (
        "macro xs:ident,+ "
        "value:interpolatedStr(term) : command => `(#check s!$value)\n"
        'def separatedInterpolationExample := "{(sorry : Nat)}"\n'
    )
    require_lean_elaboration(
        "scanner separated nonnullable interpolation safe positive",
        separated_nonnullable_interpolation_safe_positive,
    )
    require(
        not find_proof_escapes([
            ("separated-nonnullable-interpolation-safe.lean",
             separated_nonnullable_interpolation_safe_positive)
        ]),
        "scanner separated nonnullable interpolation safe positive was rejected",
    )
    noncomputable_opaque_mutant = "noncomputable opaque hidden : False\n"
    require(
        find_proof_escapes([
            ("noncomputable-bodyless-opaque.lean",
             noncomputable_opaque_mutant)
        ]),
        "scanner noncomputable bodyless opaque mutant passed",
    )
    print("mutant rejected: noncomputable bodyless opaque")
    for label, comment in (
        ("block-comment", "/- trivia -/"),
        ("nested-block-comment", "/- outer /- nested -/ trivia -/"),
        ("line-comment", "-- trivia\n"),
    ):
        comment_opaque_mutant = (
            f"noncomputable {comment} opaque hidden : Nat\n"
        )
        require_lean_elaboration(
            f"scanner {label} modifier-trivia mutant",
            comment_opaque_mutant,
        )
        require(
            find_proof_escapes([
                (f"{label}-modifier-trivia.lean", comment_opaque_mutant)
            ]),
            f"scanner {label} modifier-trivia mutant passed",
        )
        print(f"mutant rejected: elaborated {label} modifier trivia")
    legitimate_commented_opaque = (
        "private /- modifier trivia -/ noncomputable "
        "/- outer /- nested -/ trivia -/ opaque good : Nat := 1\n"
    )
    require_lean_elaboration(
        "scanner legitimate commented modifier combination",
        legitimate_commented_opaque,
    )
    require(
        not find_proof_escapes([
            ("legitimate-commented-opaque.lean", legitimate_commented_opaque)
        ]),
        "scanner legitimate commented opaque body was rejected",
    )
    elaborator_generated_axiom_mutant = (
        "import Lean\n"
        "open Lean Elab Command\n"
        'syntax "injectBad" : command\n'
        "elab_rules : command\n"
        "  | `(injectBad) => do\n"
        "      liftCoreM <| addDecl <| Declaration.axiomDecl {\n"
        "        name := `hidden\n"
        "        levelParams := []\n"
        "        type := mkConst ``False\n"
        "        isUnsafe := false\n"
        "      }\n"
        "injectBad\n"
    )
    require(
        find_proof_escapes([
            ("elaborator-generated-axiom.lean",
             elaborator_generated_axiom_mutant)
        ]),
        "scanner elaborator-generated axiom mutant passed",
    )
    print("mutant rejected: elaborator-generated axiom")
    legitimate_opaque = "private opaque good (n : Nat) : Nat := n + 1\n"
    require(
        not find_proof_escapes([("opaque-body.lean", legitimate_opaque)]),
        "scanner legitimate opaque body was rejected",
    )
    type_let_opaque_mutant = "opaque hidden : (let p := False; p)\n"
    require(
        find_proof_escapes([
            ("type-let-bodyless-opaque.lean", type_let_opaque_mutant)
        ]),
        "scanner type-level let bodyless opaque mutant passed",
    )
    print("mutant rejected: type-level let bodyless opaque")
    type_have_opaque_mutant = (
        "opaque hidden : by have p : Prop := False; exact p\n"
    )
    require(
        find_proof_escapes([
            ("type-have-bodyless-opaque.lean", type_have_opaque_mutant)
        ]),
        "scanner type-level have bodyless opaque mutant passed",
    )
    print("mutant rejected: type-level have bodyless opaque")
    for label, source in (
        (
            "unparenthesized type-level let",
            "opaque hidden : let p := False; p\n",
        ),
        (
            "unparenthesized tactic type-level let",
            "opaque hidden : by let p := False; exact p\n",
        ),
    ):
        require(
            find_proof_escapes([(f"{label.replace(' ', '-')}.lean", source)]),
            f"scanner {label} bodyless opaque mutant passed",
        )
        print(f"mutant rejected: {label} bodyless opaque")
    legitimate_type_let_opaque = (
        "opaque good : (let p := Nat; p) := 1\n"
    )
    require_lean_elaboration(
        "scanner legitimate type-level let opaque body",
        legitimate_type_let_opaque,
    )
    require(
        not find_proof_escapes([
            ("type-let-opaque-body.lean", legitimate_type_let_opaque)
        ]),
        "scanner legitimate type-level let opaque body was rejected",
    )
    for label, source in (
        (
            "unparenthesized type-level let opaque body",
            "opaque good : let p := Nat; p := 1\n",
        ),
        (
            "unparenthesized tactic type-level let opaque body",
            "opaque good : by let p := Prop; exact p := True\n",
        ),
    ):
        require_lean_elaboration(f"scanner legitimate {label}", source)
        require(
            not find_proof_escapes([(f"legitimate-{label.replace(' ', '-')}.lean", source)]),
            f"scanner legitimate {label} was rejected",
        )
        print(f"safe positive accepted: legitimate {label}")

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
    wrong_current_repository = current_lake.replace(
        "https://github.com/lfglabs-dev/verity.git",
        "https://github.com/example/verity.git",
    )
    path = write_text_mutant(wrong_current_repository, ".lean")
    try:
        expect_failure(
            "current wrong Verity repository",
            lambda: validate_dependency_planes(root_lakefile=path),
            "Verity lakefile repository/revision mismatch",
        )
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
    extra_target_dependency = target_lake + (
        '\nrequire foo from git "https://example.com/foo.git"@'
        '"0123456789abcdef0123456789abcdef01234567"\n'
    )
    path = write_text_mutant(extra_target_dependency, ".lean")
    try:
        expect_failure(
            "target arbitrary extra direct dependency",
            lambda: validate_dependency_planes(target_lakefile=path),
            "direct lakefile dependencies differ from lock declaration",
        )
    finally:
        path.unlink()
    delimiter_decoy = target_lake + (
        '\ndef marker := "/-"\n'
        'require foo from git "https://example.com/foo.git"@'
        '"0123456789abcdef0123456789abcdef01234567"\n'
        'def closer := "-/"\n'
    )
    path = write_text_mutant(delimiter_decoy, ".lean")
    try:
        expect_failure(
            "target string comment-delimiter decoy",
            lambda: validate_dependency_planes(target_lakefile=path),
            "direct lakefile dependencies differ from lock declaration",
        )
    finally:
        path.unlink()
    escaped_wrong_repository = target_lake.replace(
        'require verity from git\n  "https://github.com/lfglabs-dev/verity.git"',
        'require «verity» from git\n  "https://example.com/verity.git"',
    ) + (
        '\ndef decoy := r#"require verity from git '
        '\\"https://github.com/lfglabs-dev/verity.git\\"@'
        '\\"68f560e66c5de6123061ce5ed60261be162673d1\\""#\n'
    )
    path = write_text_mutant(escaped_wrong_repository, ".lean")
    try:
        expect_failure(
            "target escaped Verity with raw-string decoy",
            lambda: validate_dependency_planes(target_lakefile=path),
            "Verity lakefile repository/revision mismatch",
        )
    finally:
        path.unlink()
    wrong_target_repository = target_lake.replace(
        "https://github.com/lfglabs-dev/verity.git",
        "https://example.com/verity.git",
    )
    path = write_text_mutant(wrong_target_repository, ".lean")
    try:
        expect_failure(
            "target wrong Verity repository with retained revision",
            lambda: validate_dependency_planes(target_lakefile=path),
            "Verity lakefile repository/revision mismatch",
        )
    finally:
        path.unlink()

    lock_data = load_json(LOCK)
    current_manifest_data = load_json(ROOT / "lake-manifest.json")
    for field, value, expected in (
        ("repository", "https://example.com/unrelated.git",
         "proof: exact repository mismatch"),
        ("ref", "does-not-exist", "proof: exact ref mismatch"),
    ):
        proof_lock = json.loads(json.dumps(lock_data))
        proof_lock["proof"][field] = value
        proof_lock_path = write_mutant(proof_lock)
        try:
            expect_failure(
                f"proof {field} tampering",
                lambda proof_lock_path=proof_lock_path: validate_lock(proof_lock_path),
                expected,
            )
        finally:
            proof_lock_path.unlink()
    certification_lock = json.loads(json.dumps(lock_data))
    certification_lock["verity"]["certification"] = (
        "target DEV-431-READY; target PrintAxioms FAIL; AUDIT-CERT=true"
    )
    certification_lock_path = write_mutant(certification_lock)
    try:
        expect_failure(
            "Verity certification summary tampering",
            lambda: validate_lock(certification_lock_path),
            "Verity certification summary differs from fixed non-certified state",
        )
    finally:
        certification_lock_path.unlink()
    for component, field, value, expected in (
        ("lido_core", "repository", "https://github.com/example/core.git",
         "lido_core: exact repository mismatch"),
        ("verity", "repository", "https://github.com/example/verity.git",
         "Verity: exact repository mismatch"),
        ("verity", "ref", "does-not-exist", "Verity: exact ref mismatch"),
        ("evmyullean", "repository", "https://github.com/example/EVMYulLean.git",
         "EVMYulLean: exact repository mismatch"),
        ("evmyullean", "ref", "does-not-exist", "EVMYulLean: exact ref mismatch"),
        ("current_root", "plane", "audit-only",
         "current root plane must remain active"),
    ):
        lock_mutant = json.loads(json.dumps(lock_data))
        lock_mutant[component][field] = value
        lock_mutant_path = write_mutant(lock_mutant)
        try:
            expect_failure(
                f"{component} {field} tampering",
                lambda lock_mutant_path=lock_mutant_path: validate_lock(
                    lock_mutant_path
                ),
                expected,
            )
        finally:
            lock_mutant_path.unlink()
    for plane, toolchain, expected in (
        ("current_root", "leanprover/lean4:v9.99.0",
         "current root Lean toolchain exact pin mismatch"),
        ("target_root", "leanprover/lean4:v9.99.0",
         "target root Lean toolchain exact pin mismatch"),
    ):
        toolchain_lock = json.loads(json.dumps(lock_data))
        toolchain_lock[plane]["lean_toolchain"] = toolchain
        toolchain_lock_path = write_mutant(toolchain_lock)
        try:
            expect_failure(
                f"consistent {plane.replace('_', '-')} Lean toolchain tampering",
                lambda toolchain_lock_path=toolchain_lock_path: validate_lock(
                    toolchain_lock_path
                ),
                expected,
            )
        finally:
            toolchain_lock_path.unlink()
    pin_lock = json.loads(json.dumps(lock_data))
    pin_lock["current_root"]["verity"] = "0" * 40
    pin_lock["current_root"]["evmyullean"] = "1" * 40
    pin_lock_path = write_mutant(pin_lock)
    pin_lake_path = write_text_mutant(
        current_lake.replace(
            "538c4a9ce2baa25b56062bdc727eb0191ad9e67f", "0" * 40
        ),
        ".lean",
    )
    pin_manifest = json.loads(json.dumps(current_manifest_data))
    for entry in pin_manifest["packages"]:
        if entry["name"] == "verity":
            entry["rev"] = entry["inputRev"] = "0" * 40
        elif entry["name"] == "evmyul":
            entry["rev"] = entry["inputRev"] = "1" * 40
    pin_manifest_path = write_mutant(pin_manifest)
    try:
        expect_failure(
            "consistent current-plane pin tampering",
            lambda: validate_lock(pin_lock_path),
            "current root Verity exact pin mismatch",
        )
    finally:
        pin_lock_path.unlink()
        pin_lake_path.unlink()
        pin_manifest_path.unlink()

    topology_lock = json.loads(json.dumps(lock_data))
    topology_lock["current_root"]["direct_dependencies"] = ["verity", "foo"]
    topology_lock_path = write_mutant(topology_lock)
    topology_lake_path = write_text_mutant(
        current_lake
        + '\nrequire foo from git "https://example.com/foo.git"@'
          '"0123456789abcdef0123456789abcdef01234567"\n',
        ".lean",
    )
    topology_manifest = json.loads(json.dumps(current_manifest_data))
    topology_manifest["packages"].append({
        "name": "foo",
        "scope": "",
        "rev": "0123456789abcdef0123456789abcdef01234567",
        "version": "",
        "inherited": False,
        "configFile": "lakefile.lean",
        "inputRev": "0123456789abcdef0123456789abcdef01234567",
        "gitDir": ".lake/packages/foo",
        "url": "https://example.com/foo.git",
        "type": "git",
        "subDir": None,
    })
    topology_manifest_path = write_mutant(topology_manifest)
    try:
        expect_failure(
            "consistent current-root topology tampering",
            lambda: validate_lock(topology_lock_path),
            "current root must depend exactly once on Verity",
        )
    finally:
        topology_lock_path.unlink()
        topology_lake_path.unlink()
        topology_manifest_path.unlink()
    target_manifest_data = load_json(TARGET / "lake-manifest.json")
    manifest_mutants = []
    rogue_current = json.loads(json.dumps(current_manifest_data))
    rogue_current_entry = json.loads(json.dumps(
        next(p for p in rogue_current["packages"] if p["name"] == "evmyul")
    ))
    rogue_current_entry["name"] = "rogue"
    rogue_current["packages"].append(rogue_current_entry)
    rogue_current_path = write_mutant(rogue_current)
    try:
        expect_failure(
            "current unrecorded inherited package",
            lambda: validate_dependency_planes(root_manifest=rogue_current_path),
            "current plane: complete package inventory mismatch",
        )
    finally:
        rogue_current_path.unlink()
    inherited_identity = json.loads(json.dumps(current_manifest_data))
    inherited_mathlib = next(
        p for p in inherited_identity["packages"] if p["name"] == "mathlib"
    )
    inherited_mathlib["url"] = "https://github.com/example/mathlib4.git"
    inherited_mathlib["rev"] = "0" * 40
    inherited_mathlib["inputRev"] = "0" * 40
    inherited_identity_path = write_mutant(inherited_identity)
    try:
        expect_failure(
            "current inherited package identity tampering",
            lambda: validate_dependency_planes(
                root_manifest=inherited_identity_path
            ),
            "current plane: mathlib URL mismatch",
        )
    finally:
        inherited_identity_path.unlink()
    duplicate = json.loads(json.dumps(target_manifest_data))
    duplicate["packages"].append(json.loads(json.dumps(duplicate["packages"][0])))
    manifest_mutants.append(("duplicate package instances", duplicate,
                             "duplicate package instances"))
    rogue_target = json.loads(json.dumps(target_manifest_data))
    rogue_target_entry = json.loads(json.dumps(
        next(p for p in rogue_target["packages"] if p["name"] == "evmyul")
    ))
    rogue_target_entry["name"] = "rogue"
    rogue_target["packages"].append(rogue_target_entry)
    manifest_mutants.append((
        "target unrecorded inherited package", rogue_target,
        "target plane: complete package inventory mismatch",
    ))
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
    extra_source = load_json(TARGET_SOURCE)
    extra_source = json.loads(json.dumps(extra_source))
    extra_source["sources"].append(json.loads(json.dumps(extra_source["sources"][0])))
    extra_source_path = write_mutant(extra_source)
    try:
        expect_failure(
            "additional committed provenance",
            lambda: validate_source_inventory(extra_source_path),
            "path mismatch",
        )
    finally:
        extra_source_path.unlink()
    with tempfile.TemporaryDirectory() as directory:
        target_mutant = Path(directory)
        for source in load_json(TARGET_SOURCE)["sources"]:
            snapshot = TARGET / source["path"]
            (target_mutant / source["path"]).write_bytes(snapshot.read_bytes())
        (target_mutant / "lakefile.lean").unlink()
        expect_failure(
            "removed committed target snapshot",
            lambda: validate_source_inventory(target=target_mutant),
            "target snapshot missing: lakefile.lean",
        )
    with tempfile.TemporaryDirectory() as directory:
        target_mutant = Path(directory)
        for source in load_json(TARGET_SOURCE)["sources"]:
            snapshot = TARGET / source["path"]
            (target_mutant / source["path"]).write_bytes(snapshot.read_bytes())
        manifest = target_mutant / "lake-manifest.json"
        manifest.write_bytes(manifest.read_bytes() + b"\n")
        expect_failure(
            "mutated committed target snapshot",
            lambda: validate_source_inventory(target=target_mutant),
            "target snapshot digest mismatch: lake-manifest.json",
        )
    receipt_mutant = load_json(TARGET / "verity.json")
    receipt_mutant = json.loads(json.dumps(receipt_mutant))
    receipt_mutant["print_axioms"]["audit_cert"] = True
    receipt_path = write_mutant(receipt_mutant)
    try:
        expect_failure("AUDIT-CERT with failing PrintAxioms",
                       lambda: validate_dependency_planes(verity_metadata=receipt_path),
                       "PrintAxioms receipt differs from fixed non-certified evidence")
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
            "schema.json: status enum differs from the executable format",
        )
    finally:
        inverted_enum_path.unlink()
    reversed_enum_schema = json.loads(json.dumps(schema))
    reversed_enum_schema["properties"]["invariants"]["items"]["properties"]["status"]["enum"].reverse()
    reversed_enum_path = write_mutant(reversed_enum_schema)
    try:
        expect_failure(
            "schema reversed-enum mutant",
            lambda: validate(REGISTRY, reversed_enum_path),
            "schema.json: status enum differs from the executable format",
        )
    finally:
        reversed_enum_path.unlink()

    status_views = rendered(data)
    status_lines = status_views["BY_STATUS.md"].splitlines(keepends=True)
    proved_heading = status_lines.index("## PROVED\n")
    next_heading = next(
        index for index in range(proved_heading + 1, len(status_lines))
        if status_lines[index].startswith("## ")
    )
    proved_row = next(
        index for index in range(proved_heading + 1, next_heading)
        if status_lines[index].startswith("| SRV3-")
    )
    moved_row = status_lines.pop(proved_row)
    dropped = dict(status_views)
    dropped["BY_STATUS.md"] = status_views["BY_STATUS.md"].replace(moved_row, "", 1)
    expect_failure(
        "generated status dropped-row mutant",
        lambda: assert_render_coverage(data, dropped),
        "BY_STATUS.md: rendered ID coverage differs",
    )
    open_heading = status_lines.index("## OPEN\n")
    open_table = next(
        index for index in range(open_heading + 1, len(status_lines))
        if status_lines[index].startswith("| ---")
    )
    status_lines.insert(open_table + 1, moved_row)
    misclassified = dict(status_views)
    misclassified["BY_STATUS.md"] = "".join(status_lines)
    expect_failure(
        "generated status misclassification mutant",
        lambda: assert_render_coverage(data, misclassified),
        "BY_STATUS.md: rendered status classification differs",
    )

    duplicated = dict(status_views)
    duplicated["BY_STATUS.md"] = status_views["BY_STATUS.md"].replace(
        moved_row, moved_row + moved_row, 1
    )
    expect_failure(
        "generated status duplication mutant",
        lambda: assert_render_coverage(data, duplicated),
        "BY_STATUS.md: rendered ID coverage differs",
    )

    with tempfile.TemporaryDirectory(dir=AUDIT / "fixtures") as fixture_directory:
        fixture_root = Path(fixture_directory)
        missing = fixture_root / "missing.json"
        expect_failure(
            "missing negative fixture",
            lambda: require_fixture(str(missing.relative_to(AUDIT / "fixtures"))),
            "negative fixture missing",
        )
        unreadable = fixture_root / "unreadable.json"
        unreadable.write_text("{}\n", encoding="utf-8")
        unreadable.chmod(0)
        expect_failure(
            "unreadable negative fixture",
            lambda: require_fixture(str(unreadable.relative_to(AUDIT / "fixtures"))),
            "negative fixture unreadable",
        )
        malformed = fixture_root / "malformed.json"
        malformed.write_text("{\n", encoding="utf-8")
        expect_failure(
            "malformed negative fixture",
            lambda: load_json(malformed),
            "Expecting property name",
        )
        semantic = fixture_root / "semantic.json"
        semantic.write_text('{"const": true}\n', encoding="utf-8")
        expect_failure(
            "semantically invalid negative fixture",
            lambda: validate_against_schema(
                load_json(semantic), {"const": {"required": True}}, "fixture"
            ),
            "fixture: does not match schema const",
        )

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
    repositories = source_repositories()
    verity_repository, verity_ref = repositories["verity"]
    expect_failure(
        "refresh nonexistent pinned ref",
        lambda: resolve_git_targets(
            "verity",
            verity_repository,
            verity_ref,
            pins["verity"],
            {"does-not-exist": {"kind": "ref", "object": pins["verity"]}},
        ),
        "ref identity does not match pinned repository ref",
    )
    lock_mutant = load_json(LOCK)
    lock_mutant = json.loads(json.dumps(lock_mutant))
    lock_mutant["proof"]["repository"] = "https://github.com/example/proof.git"
    lock_path = write_mutant(lock_mutant)
    try:
        expect_failure(
            "refresh immutable lock tampering",
            lambda: refresh_provenance(lock_path),
            "proof: exact repository mismatch",
        )
    finally:
        lock_path.unlink()
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
            refresh_provenance()
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
