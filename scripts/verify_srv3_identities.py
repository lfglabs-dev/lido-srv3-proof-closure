#!/usr/bin/env python3
"""Verify the SRv3 deployed-identity fixtures recorded under A-RUNTIME-PROVENANCE.

Step 1c of the "not proven" cleanup (Thomas 2026-09-17) extends the
deployed-runtime fixtures of `fixtures/deployed/` (pattern:
`scripts/verify_lido_immutable.py`) with

- the SRLib library linked into the StakingRouter implementation, the
  BeaconChainDepositor library linked next to it, and the
  MinFirstAllocationStrategy library linked into SRLib, each with the PUSH20
  offsets at which the linked address is inlined (the link map);
- the implementations behind the four registered staking modules
  (NodeOperatorsRegistry / SimpleDVT, CSModule, CuratedModuleV2);
- the LidoLocator implementation and the implementations of its
  withdrawalQueue() and accountingOracle() proxies, plus the AccountingOracle's
  HashConsensus contract.

Every identity is recorded by EIP-1052 codehash (keccak256 of the runtime
bytecode) in `fixtures/deployed/srv3-identities.json`.

Offline (always): re-hash every fixture (SHA-256 and keccak256), compare with
the record, and re-extract every linked library address at its recorded PUSH20
offsets in the StakingRouter and SRLib runtimes.

Online (`ETH_RPC_URL` set): re-read `StakingRouter.getStakingModules()`, the
Aragon `implementation()` / EIP-1967 implementation slots, the locator getters,
`AccountingOracle.getConsensusContract()`, and `eth_getCode` of every recorded
runtime; any divergence from the record fails.

Usage:
    python3 scripts/verify_srv3_identities.py
    ETH_RPC_URL=https://... python3 scripts/verify_srv3_identities.py
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RECORD = ROOT / "fixtures/deployed/srv3-identities.json"

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_deployed_code import keccak256  # noqa: E402

EIP1967_IMPL_SLOT = hex(int.from_bytes(keccak256(b"eip1967.proxy.implementation"), "big") - 1)


def die(msg: str) -> None:
    print(f"verify_srv3_identities: {msg}", file=sys.stderr)
    sys.exit(1)


def push20_offsets(code: bytes, address: str) -> list[int]:
    payload = bytes.fromhex(address[2:])
    return [i + 1 for i in range(len(code) - 20) if code[i] == 0x73 and code[i + 1:i + 21] == payload]


def verify_fixture(name: str, entry: dict) -> bytes:
    path = ROOT / entry["fixture_path"]
    if not path.is_file():
        die(f"{name}: fixture missing: {entry['fixture_path']}")
    code = path.read_bytes()
    if len(code) != entry["fixture_size_bytes"]:
        die(f"{name}: fixture length {len(code)} != {entry['fixture_size_bytes']}")
    if hashlib.sha256(code).hexdigest() != entry["fixture_sha256"]:
        die(f"{name}: fixture SHA-256 mismatch")
    codehash = keccak256(code).hex()
    if codehash != entry["fixture_codehash_keccak256"]:
        die(f"{name}: fixture keccak256 {codehash} != recorded {entry['fixture_codehash_keccak256']}")
    print(f"{name:40s} {entry['address']} codehash 0x{codehash} OK")
    return code


class Rpc:
    def __init__(self, url: str) -> None:
        self.url = url

    def call(self, method: str, params: list) -> str:
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        req = urllib.request.Request(
            self.url, data=body,
            headers={"Content-Type": "application/json", "User-Agent": "verify-srv3-identities/1.0"},
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                d = json.load(resp)
        except Exception as e:  # noqa: BLE001
            die(f"RPC {method} failed: {e}")
        if "result" not in d:
            die(f"RPC error for {method}: {d}")
        return d["result"]

    def eth_call(self, to: str, signature: str) -> str:
        selector = keccak256(signature.encode())[:4].hex()
        return self.call("eth_call", [{"to": to, "data": "0x" + selector}, "latest"])

    def address_reply(self, to: str, signature: str) -> str:
        return "0x" + self.eth_call(to, signature)[-40:]

    def code(self, address: str) -> bytes:
        return bytes.fromhex(self.call("eth_getCode", [address, "latest"])[2:])

    def eip1967_implementation(self, proxy: str) -> str:
        return "0x" + self.call("eth_getStorageAt", [proxy, EIP1967_IMPL_SLOT, "latest"])[-40:]

    def staking_modules(self, router: str) -> list[tuple[int, str]]:
        raw = bytes.fromhex(self.eth_call(router, "getStakingModules()")[2:])
        count = int.from_bytes(raw[32:64], "big")
        modules = []
        for i in range(count):
            offset = int.from_bytes(raw[64 + 32 * i:96 + 32 * i], "big")
            base = 64 + offset
            module_id = int.from_bytes(raw[base:base + 32], "big")
            address = "0x" + raw[base + 32:base + 64].hex()[-40:]
            modules.append((module_id, address))
        return modules


def expect(label: str, actual: str, recorded: str) -> None:
    if actual.lower() != recorded.lower():
        die(f"{label}: live {actual} != recorded {recorded}")
    print(f"live {label}: {actual} OK")


def main() -> None:
    record = json.loads(RECORD.read_text())
    if record.get("schema") != "lido-srv3-deployed-identities-v1":
        die("unexpected record schema")

    codes = {name: verify_fixture(name, entry) for name, entry in record["deployed_runtimes"].items()}

    router_code = (ROOT / record["link_map"]["StakingRouter_implementation"]["fixture_path"]).read_bytes()
    if keccak256(router_code).hex() != record["link_map"]["StakingRouter_implementation"]["fixture_codehash_keccak256"]:
        die("StakingRouter fixture keccak256 differs from the link-map record")
    link_sources = {
        "StakingRouter_implementation": router_code,
        "SRLib": codes["SRLib"],
    }
    for holder, spec in record["link_map"].items():
        code = link_sources[holder]
        for library, link in spec["links"].items():
            offsets = push20_offsets(code, link["address"])
            if offsets != link["push20_offsets"]:
                die(f"{holder}: {library} linked address offsets {offsets} != recorded {link['push20_offsets']}")
            if not offsets:
                die(f"{holder}: {library} address is not inlined anywhere")
            print(f"link map {holder} -> {library} @ {link['address']}: {len(offsets)} PUSH20 sites OK")

    rpc_url = os.environ.get("ETH_RPC_URL")
    if not rpc_url:
        print("live re-verification skipped (set ETH_RPC_URL to enable)")
        print("verify_srv3_identities: OK (offline)")
        return

    rpc = Rpc(rpc_url)
    router = record["staking_router"]
    expect("StakingRouter implementation slot", rpc.eip1967_implementation(router["proxy"]), router["implementation"])
    live_modules = rpc.staking_modules(router["proxy"])
    recorded_modules = [(m["id"], m["address"].lower()) for m in router["registered_modules"]]
    if [(i, a.lower()) for i, a in live_modules] != recorded_modules:
        die(f"registered modules differ: live {live_modules} recorded {recorded_modules}")
    print(f"live StakingRouter.getStakingModules(): {len(live_modules)} modules OK")
    for module in router["registered_modules"]:
        if module["proxy_kind"] == "aragon-app-proxy":
            implementation = rpc.address_reply(module["address"], "implementation()")
        else:
            implementation = rpc.eip1967_implementation(module["address"])
        expect(f"module {module['id']} implementation", implementation, module["implementation"])

    locator = record["locator"]
    expect("Lido.getLidoLocator()", rpc.address_reply(locator["getters"]["lido()"], "getLidoLocator()"), locator["proxy"])
    expect("LidoLocator implementation slot", rpc.eip1967_implementation(locator["proxy"]), locator["implementation"])
    for getter, recorded in locator["getters"].items():
        expect(f"locator.{getter}", rpc.address_reply(locator["proxy"], getter), recorded)
    for getter, recorded in locator["consensus"].items():
        oracle = locator["getters"]["accountingOracle()"]
        expect(getter, rpc.address_reply(oracle, "getConsensusContract()"), recorded)
    for name, entry in record["deployed_runtimes"].items():
        live = rpc.code(entry["address"])
        live_hash = keccak256(live).hex()
        if live_hash != entry["fixture_codehash_keccak256"]:
            die(f"{name}: live codehash {live_hash} != fixture {entry['fixture_codehash_keccak256']}")
        for proxy in list(entry.get("proxies", {}).values()) + ([entry["proxy"]] if "proxy" in entry else []):
            if name == "NodeOperatorsRegistry_implementation":
                pointed = rpc.address_reply(proxy, "implementation()")
            else:
                pointed = rpc.eip1967_implementation(proxy)
            expect(f"{name} proxy {proxy} implementation", pointed, entry["address"])
        print(f"live {name}: codehash 0x{live_hash} OK")
    print(f"live re-verification (via {rpc_url}): OK")
    print("verify_srv3_identities: OK")


if __name__ == "__main__":
    main()
