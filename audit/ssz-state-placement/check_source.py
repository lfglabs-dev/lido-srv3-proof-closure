#!/usr/bin/env python3
"""Offline schema extraction, pinned identities and source anchors only.
This is not compiler/EVM correspondence or deployed-fork verification.
"""
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
CORE_PIN = "17005714f151e5502c559932319a3f2f74ac2436"
SPEC_PIN = "f96d3e7acf35125295d234da4b0c67591fdef49c"
manifest = json.loads((HERE / "schema-sources.json").read_text())
assert manifest["commit"] == SPEC_PIN
for entry in manifest["files"]:
    data = (HERE / "consensus-specs" / entry["path"]).read_bytes()
    assert hashlib.sha256(data).hexdigest() == entry["sha256"], entry["path"]
    assert entry["url"] == f"https://raw.githubusercontent.com/ethereum/consensus-specs/{SPEC_PIN}/{entry['path']}"


def container(path, name):
    text = (HERE / "consensus-specs" / path).read_text()
    block = re.search(r"class " + name + r"\(Container\):\n(.*?)\n```", text, re.S).group(1)
    return re.findall(r"^    (\w+): (.+)$", block, re.M)


def camel(name):
    head, *tail = name.split("_")
    return head + "".join(word[0].upper() + word[1:] for word in tail)

lean = (ROOT / "LidoSRv3/Audit/Source/SszStatePlacement.lean").read_text()
lean_fields = re.findall(r"\.(\w+)", lean.split("def electraFields : List StateField := [", 1)[1].split("]", 1)[0])
electra = container("specs/electra/beacon-chain.md", "BeaconState")
fulu = container("specs/fulu/beacon-chain.md", "BeaconState")
assert [camel(name) for name, _ in electra] == lean_fields
assert [name for name, _ in fulu] == [name for name, _ in electra] + ["proposer_lookahead"]
assert "| .fulu => electraFields ++ [.proposerLookahead]" in lean
assert len(electra) == 37 and len(fulu) == 38
assert electra[11] == fulu[11] == ("validators", "List[Validator, VALIDATOR_REGISTRY_LIMIT]")
assert fulu[-1][1] == "Vector[ValidatorIndex, (MIN_SEED_LOOKAHEAD + 1) * SLOTS_PER_EPOCH]"
validator = container("specs/phase0/beacon-chain.md", "Validator")
assert [name for name, _ in validator] == ["pubkey", "withdrawal_credentials", "effective_balance", "slashed",
    "activation_eligibility_epoch", "activation_epoch", "exit_epoch", "withdrawable_epoch"]
phase0 = (HERE / "consensus-specs/specs/phase0/beacon-chain.md").read_text()
assert re.search(r"`VALIDATOR_REGISTRY_LIMIT`\s*\|\s*`uint64\(2\*\*40\)`", phase0)
assert re.search(r"`BLSPubkey`\s*\|\s*`Bytes48`", phase0)
ssz = (HERE / "consensus-specs/ssz/simple-serialize.md").read_text()
assert '(`"uint256"`\n  little-endian serialization)' in ssz
assert "mix_in_length(merkleize([hash_tree_root(element) for element in value], limit=chunk_count(type)), len(value))" in ssz
assert "next_pow_of_two(limit)" in ssz
merkle = (HERE / "consensus-specs/ssz/merkle-proofs.md").read_text()
assert "root * base_index * get_power_of_two_ceil(chunk_count(typ)) + pos" in merkle

core_files = ["contracts/0.8.25/CLValidatorVerifier.sol", "contracts/common/lib/GIndex.sol",
    "contracts/common/lib/SSZ.sol", "contracts/common/lib/BLS.sol",
    "contracts/common/interfaces/ValidatorWitness.sol", "scripts/upgrade/upgrade-params-mainnet.toml"]
core = []
for path in core_files:
    data = (ROOT / "lido-core" / path).read_bytes()
    pinned = subprocess.check_output(["git", "-C", str(ROOT / "lido-core"), "show", f"{CORE_PIN}:{path}"])
    assert data == pinned, path
    core.append({"path": path, "sha256": hashlib.sha256(data).hexdigest(), "matches_pin": True})
config = (ROOT / "lido-core/scripts/upgrade/upgrade-params-mainnet.toml").read_text()
for name in ["topUpGateway", "consolidationGateway"]:
    section = re.search(r"\[" + name + r"\]\n(.*?)(?=\n\[|\Z)", config, re.S).group(1)
    for key in ["gIFirstValidatorPrev", "gIFirstValidatorCurr"]:
        packed = int(re.search(r"^" + key + r' = "(0x[0-9a-fA-F]+)"', section, re.M).group(1), 16)
        assert packed >> 8 == 150 * 2**40 and packed & 255 == 40
    assert int(re.search(r"^pivotSlot = (\d+)", section, re.M).group(1)) == 0

schemas = []
for name, fields in [("electra", electra), ("fulu", fulu)]:
    width = 1 << (len(fields) - 1).bit_length()
    field_index = width + [field for field, _ in fields].index("validators")
    schemas.append({"schema": name, "field_count": len(fields), "padded_width": width,
        "validator_position": 11, "validator_field_gindex": field_index,
        "list_data_gindex": field_index * 2, "validator_capacity": 2**40,
        "state_path_prefix": bin(field_index * 2)[3:], "state_proof_depth": 6 + 1 + 40,
        "header_proof_depth": 3 + 6 + 1 + 40})
print(json.dumps({"scope": "offline schema/field extraction and file identity; no semantic or deployed-runtime claim",
    "core_pin": CORE_PIN, "schema_pin": SPEC_PIN, "schema_files_verified": len(manifest["files"]),
    "schemas": schemas, "core_files": core}, indent=2))
