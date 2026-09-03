#!/usr/bin/env python3
"""Check that the Lido mainnet contracts audited here correspond to the pinned source.

Stdlib only. Three steps, each independently useful to a reviewer:

  Step B verdicts: "identical to pin" = byte-for-byte after line-ending normalisation;
  "comments/whitespace differ" = same code once comments and whitespace are stripped
  (same runtime bytecode, only the metadata hash can differ; reported as a note, not a
  failure); "CODE DIFFERS" = a token-level difference, printed as a unified diff excerpt
  and counted as a failure so the reviewer must look at it.

  A. ON-CHAIN (always, needs an Ethereum JSON-RPC endpoint):
     for every proxy in the table below read the EIP-1967 implementation slot
     (keccak256("eip1967.proxy.implementation") - 1) with eth_getStorageAt; when the slot
     is empty (Aragon AppProxyUpgradeable: Lido, NodeOperatorsRegistry) call
     implementation() instead. Assert the result equals the implementation address
     documented at docs.lido.fi/deployed-contracts ("slot" column: ok / aragon / MISMATCH).
     Then eth_getCode the implementation (or the non-proxied contract) and print the
     runtime code size and its keccak256 (pure-Python Keccak-f[1600]; keccak256 is NOT
     hashlib.sha3_256). The reviewer can compare the hash against Etherscan's
     "Contract Creation Code"/"Deployed Bytecode" or their own node.

  B. VERIFIED SOURCE (Sourcify without a key; Etherscan API v2 when ETHERSCAN_API_KEY
     is set): fetch the verified source bundle of each implementation, and diff every
     in-repo file (contracts/**) of the bundle against the same path in `lido-core/`
     (only line endings are normalised; @openzeppelin etc. are skipped unless
     lido-core/node_modules is installed). Prints: verified? / compiler version +
     settings / identical-to-pin or the list of differing files, from each provider.
     Sourcify match status: `exact_match` = Sourcify recompiled the source and the
     bytecode including the metadata hash is identical; `match` = bytecode identical
     except for the metadata hash (same code, possibly different file paths/comments).

  C. RECOMPILE (--recompile): explains what a full recompilation requires and whether
     `forge` / `npx hardhat` is on PATH. No multi-solc compilation is attempted here.

Environment:
    ETH_RPC_URL        JSON-RPC endpoint (default https://ethereum-rpc.publicnode.com)
    ETHERSCAN_API_KEY  enables step B (free key at https://etherscan.io/apis)

Exit status: 0 when every performed check passed; 1 when a performed check failed
(slot mismatch, source differs from pin); 2 when some check could not be performed
(no network, no key, rate limit) but nothing failed.

Usage:
    python3 scripts/check_deployed_code.py [--only NAME,...] [--recompile] [--no-sourcify]
    ETHERSCAN_API_KEY=... python3 scripts/check_deployed_code.py
"""

from __future__ import annotations

import argparse
import difflib
import json
import os
import shutil
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

DEFAULT_RPC = "https://ethereum-rpc.publicnode.com"
ETHERSCAN_V2 = "https://api.etherscan.io/v2/api"
SOURCIFY = "https://sourcify.dev/server/v2/contract/1/{addr}?fields=all"

# (name, proxy or None, implementation or None -> resolved from slot, solidity path under lido-core/)
# Addresses: https://docs.lido.fi/deployed-contracts (mainnet, Lido V3 / SR v3 upgrade).
CONTRACTS = [
    ("StakingRouter", "0xFdDf38947aFB03C621C71b06C9C70bce73f12999", "0xDD76927045435C7605cf6f5F978cfb8CABDb5F80", "contracts/0.8.25/sr/StakingRouter.sol"),
    ("TopUpGateway", "0x3FC2C71579D80790Aaa3fc7Be8B66ac39dC57374", "0xb08dBc68C521cD7A4318dc4C807a42bEB20f1106", "contracts/0.8.25/TopUpGateway.sol"),
    ("ConsolidationGateway", None, "0x17be979344f2c2cC806229a532D92f8742C10462", "contracts/0.8.25/consolidation/ConsolidationGateway.sol"),
    ("ConsolidationBus", "0xd907CE33B4Be423823d1CFFe80BD147E8b8554C8", "0xFfDe8Acab9D7037f29198Ad03ad6d05bac8B0a2E", "contracts/0.8.25/consolidation/ConsolidationBus.sol"),
    ("ConsolidationMigrator", "0x9Dc70b5A4f4F5E4AF9058C983D560564F031f1D7", "0x6Fb4c152F092373dD71f0C07C83c1E77406599aB", "contracts/0.8.25/consolidation/ConsolidationMigrator.sol"),
    ("WithdrawalVault", "0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f", "0xfB4521BD151BFB45DB6045D2d07e58e0f597e340", "contracts/0.8.9/WithdrawalVault.sol"),
    ("Accounting", "0x23ED611be0e1a820978875C0122F92260804cdDf", "0x3aa937Ac2ab89CDd363EdC6b5A4d4A42dF5bc043", "contracts/0.8.9/Accounting.sol"),
    ("AccountingOracle", "0x852deD011285fe67063a08005c71a85690503Cee", "0xe4f03D1107d1905B6F2A28FCb6Af221E0CE19136", "contracts/0.8.9/oracle/AccountingOracle.sol"),
    ("ValidatorsExitBusOracle", "0x0De4Ea0184c2ad0BacA7183356Aea5B8d5Bf5c6e", "0x2C3386b39db89eef0F362A3BE0C05a6811E809E3", "contracts/0.8.9/oracle/ValidatorsExitBusOracle.sol"),
    ("TriggerableWithdrawalsGateway", None, "0xDC00116a0D3E064427dA2600449cfD2566B3037B", "contracts/0.8.9/TriggerableWithdrawalsGateway.sol"),
    ("Lido", "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84", "0x028271E30a695c0527A0C50cA30603feD004cDb0", "contracts/0.4.24/Lido.sol"),
    ("DepositSecurityModule", None, "0xF573E9E3de1f86B085417ab294f56E7920B4e9Be", "contracts/0.8.9/DepositSecurityModule.sol"),
    ("WithdrawalQueueERC721", "0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1", None, "contracts/0.8.9/WithdrawalQueueERC721.sol"),
    ("HashConsensus(AccountingOracle)", None, "0xD624B08C83bAECF0807Dd2c6880C3154a5F0B288", "contracts/0.8.9/oracle/HashConsensus.sol"),
    # Curated Module v2 is built from a separate repository (src/CuratedModule.sol, solc 0.8.33),
    # not from lidofinance/core: only step A applies.
    ("CuratedModuleV2", "0xDa5F930cE326EB5205085D66c72A4E79d60cB8C1", "0x959fC67FE53c8A6C7a1AEd73430Aa07a36eD9337", None),
]

# ------------------------------------------------------------------ Keccak-256 (pure Python)
_RC = [
    0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
    0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
    0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
    0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
    0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
]
_ROT = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61], [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]]
_MASK = (1 << 64) - 1


def _rol(x: int, n: int) -> int:
    return ((x << n) | (x >> (64 - n))) & _MASK if n else x


def _keccak_f(a: list[list[int]]) -> None:
    for rnd in range(24):
        c = [a[x][0] ^ a[x][1] ^ a[x][2] ^ a[x][3] ^ a[x][4] for x in range(5)]
        d = [c[(x - 1) % 5] ^ _rol(c[(x + 1) % 5], 1) for x in range(5)]
        for x in range(5):
            for y in range(5):
                a[x][y] ^= d[x]
        b = [[0] * 5 for _ in range(5)]
        for x in range(5):
            for y in range(5):
                b[y][(2 * x + 3 * y) % 5] = _rol(a[x][y], _ROT[x][y])
        for x in range(5):
            for y in range(5):
                a[x][y] = b[x][y] ^ ((~b[(x + 1) % 5][y]) & b[(x + 2) % 5][y])
        a[0][0] ^= _RC[rnd]


def keccak256(data: bytes) -> bytes:
    rate = 136  # 1088 bits
    a = [[0] * 5 for _ in range(5)]
    msg = bytearray(data)
    msg.append(0x01)  # Keccak padding (SHA-3 would use 0x06)
    while len(msg) % rate:
        msg.append(0)
    msg[-1] |= 0x80
    for off in range(0, len(msg), rate):
        for i in range(rate // 8):
            lane = int.from_bytes(msg[off + 8 * i: off + 8 * i + 8], "little")
            a[i % 5][i // 5] ^= lane
        _keccak_f(a)
    out = b"".join(a[i % 5][i // 5].to_bytes(8, "little") for i in range(4))
    return out[:32]


def _selftest() -> None:
    assert keccak256(b"").hex() == "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
    assert keccak256(b"abc").hex() == "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45"


EIP1967_IMPL_SLOT = "0x" + f"{int.from_bytes(keccak256(b'eip1967.proxy.implementation'), 'big') - 1:064x}"

# ------------------------------------------------------------------ helpers


def http_json(url: str, body: dict | None = None, timeout: float = 20.0) -> dict | list:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json",
                                                          "User-Agent": "lido-srv3-proof-closure/check_deployed_code"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode())


def rpc(url: str, method: str, params: list) -> str:
    r = http_json(url, {"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    if "error" in r:
        raise RuntimeError(f"{method}: {r['error']}")
    return r["result"]


def norm(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n").rstrip("\n") + "\n"


def parse_etherscan_sources(raw: str) -> dict[str, str]:
    """Etherscan returns either a bare source, a standard-json wrapped in {{ }}, or JSON."""
    raw = raw.strip()
    if raw.startswith("{{") and raw.endswith("}}"):
        raw = raw[1:-1]
    if raw.startswith("{"):
        try:
            j = json.loads(raw)
        except json.JSONDecodeError:
            return {"<single-file>": raw}
        srcs = j.get("sources", j)
        return {k: (v["content"] if isinstance(v, dict) else v) for k, v in srcs.items()}
    return {"<single-file>": raw}


def etherscan_sources(addr: str, key: str) -> dict:
    q = urllib.parse.urlencode({"chainid": 1, "module": "contract", "action": "getsourcecode",
                                "address": addr, "apikey": key})
    r = http_json(f"{ETHERSCAN_V2}?{q}")
    if r.get("status") != "1" or not r.get("result"):
        raise RuntimeError(f"etherscan: {r.get('message')} {r.get('result')}")
    return r["result"][0]


def sourcify_record(addr: str) -> tuple[str, dict | None]:
    """Returns (status line, record or None). The record carries `sources` and `compilation`."""
    try:
        r = http_json(SOURCIFY.format(addr=addr), timeout=30)
    except urllib.error.HTTPError as exc:
        return ("not found" if exc.code == 404 else f"http {exc.code}"), None
    except Exception as exc:  # noqa: BLE001
        return f"unreachable ({type(exc).__name__})", None
    return f"{r.get('match', '?')} (runtime={r.get('runtimeMatch')}, creation={r.get('creationMatch')})", r


_COMMENT_RE = None


def strip_comments_ws(text: str) -> str:
    """Remove // and /* */ comments and all whitespace: two Solidity files equal under this
    normalisation compile to the same runtime bytecode (only the metadata hash may differ)."""
    global _COMMENT_RE
    import re
    if _COMMENT_RE is None:
        _COMMENT_RE = re.compile(r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', re.S)
    def repl(m):
        t = m.group(0)
        return t if t[0] in "\"'" else " "
    return re.sub(r"\s+", "", _COMMENT_RE.sub(repl, text))


def diff_excerpt(local_text: str, remote_text: str, name: str, n: int = 12) -> list[str]:
    ud = difflib.unified_diff(norm(local_text).splitlines(), norm(remote_text).splitlines(),
                              f"lido-core/{name}", f"verified/{name}", lineterm="", n=0)
    return [l for l in ud if not l.startswith(("---", "+++"))][:n]


def compare_sources(srcs: dict[str, str], core: Path, main_path: str) -> tuple[list, list, list, list, bool]:
    """Diff a verified source bundle against lido-core/.
    Returns (same, doc_only, code_diff, skipped, main_seen); code_diff entries are
    (path, excerpt lines)."""
    same, doc_only, diff, skipped = [], [], [], []
    main_seen = False
    for bp, content in srcs.items():
        if isinstance(content, dict):
            content = content.get("content", "")
        local = map_bundle_path(bp, core)
        if bp.endswith(main_path) or main_path.endswith(bp):
            main_seen = True
        if local is None or not local.is_file():
            skipped.append(bp)
            continue
        local_text = local.read_text(encoding="utf-8", errors="replace")
        if norm(local_text) == norm(content):
            same.append(bp)
        elif strip_comments_ws(local_text) == strip_comments_ws(content):
            doc_only.append(bp)
        else:
            diff.append((bp, diff_excerpt(local_text, content, bp)))
    return same, doc_only, diff, skipped, main_seen


def report_bundle(name: str, provider: str, srcs: dict, core: Path, path: str,
                  failed: list, unchecked: list, notes: list) -> str:
    """Compare a bundle and return the verdict line; records failures/notes."""
    same, doc_only, diff, skipped, main_seen = compare_sources(srcs, core, path)
    if diff:
        failed.append(f"{name}: {provider}: code differs from pin in {[d[0] for d in diff]}")
        verdict = f"CODE DIFFERS ({len(diff)} file(s))"
    elif not same and not doc_only:
        unchecked.append(f"{name}: no {provider} bundle file could be mapped into lido-core")
        verdict = "no comparable files"
    else:
        verdict = f"identical to pin ({len(same)} files)"
    if doc_only:
        notes.append(f"{name}: {provider}: comment/whitespace-only differences in {doc_only}")
        verdict += f"; comments/whitespace differ in {len(doc_only)} file(s)"
    if not main_seen:
        unchecked.append(f"{name}: {path} absent from {provider} bundle")
        verdict += f"; main file {path} absent from bundle"
    if skipped:
        verdict += f"; {len(skipped)} external file(s) not compared"
    for bp in doc_only:
        verdict += f"\n  {'':<40}   doc-only: {bp}"
    for bp, excerpt in diff:
        verdict += f"\n  {'':<40}   differs: {bp}"
        for l in excerpt:
            verdict += f"\n  {'':<40}     {l}"
    return verdict


def map_bundle_path(bundle_path: str, core: Path) -> Path | None:
    """Bundle paths look like 'contracts/0.8.25/sr/StakingRouter.sol' or
    '@openzeppelin/...' or 'node_modules/...'. Only in-repo contract files are compared."""
    p = bundle_path.lstrip("./")
    if p.startswith("contracts/"):
        return core / p
    for prefix in ("node_modules/", "lib/", "@"):
        if p.startswith(prefix):
            cand = core / "node_modules" / p.removeprefix("node_modules/")
            return cand if cand.is_file() else None
    return None


# ------------------------------------------------------------------ main


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo-root", default=str(Path(__file__).resolve().parent.parent))
    ap.add_argument("--only", help="comma-separated contract names to check")
    ap.add_argument("--recompile", action="store_true", help="step C: describe recompilation prerequisites")
    ap.add_argument("--no-sourcify", action="store_true")
    args = ap.parse_args()
    _selftest()
    root = Path(args.repo_root)
    core = root / "lido-core"
    rpc_url = os.environ.get("ETH_RPC_URL", DEFAULT_RPC)
    es_key = os.environ.get("ETHERSCAN_API_KEY", "")
    failed: list[str] = []
    unchecked: list[str] = []
    notes: list[str] = []

    rows = CONTRACTS
    if args.only:
        wanted = {n.strip() for n in args.only.split(",")}
        rows = [c for c in CONTRACTS if c[0] in wanted]

    print(f"RPC endpoint       : {rpc_url}")
    print(f"EIP-1967 impl slot : {EIP1967_IMPL_SLOT}")
    print(f"lido-core checkout : ", end="")
    try:
        import subprocess
        print(subprocess.run(["git", "-C", str(core), "rev-parse", "HEAD"], capture_output=True, text=True, check=True).stdout.strip())
    except Exception as exc:  # noqa: BLE001
        print(f"unavailable ({exc})")
        unchecked.append("lido-core submodule not initialised (step B cannot diff)")

    # ---- Step A ----------------------------------------------------------------
    print("\n== A. On-chain: EIP-1967 implementation slot and runtime code hash")
    rpc_ok = True
    try:
        rpc(rpc_url, "eth_chainId", [])
    except Exception as exc:  # noqa: BLE001
        rpc_ok = False
        unchecked.append(f"RPC unreachable ({exc}); step A skipped")
        print(f"  RPC unreachable: {exc}")

    impls: dict[str, str] = {}
    if rpc_ok:
        hdr = f"  {'contract':<40} {'impl (documented)':<44} {'slot':<9} {'code':>7}  keccak256(runtime code)"
        print(hdr)
        for name, proxy, impl_doc, _path in rows:
            try:
                impl_chain = None
                slot = "n/a"
                if proxy:
                    raw = rpc(rpc_url, "eth_getStorageAt", [proxy, EIP1967_IMPL_SLOT, "latest"])
                    impl_chain = "0x" + raw[-40:]
                    slot = "ok"
                    if int(impl_chain, 16) == 0:
                        # Aragon AppProxyUpgradeable (Lido, NodeOperatorsRegistry): the base is
                        # resolved through the Kernel; the proxy exposes implementation().
                        raw = rpc(rpc_url, "eth_call", [{"to": proxy, "data": "0x5c60da1b"}, "latest"])
                        impl_chain = "0x" + raw[-40:]
                        slot = "aragon"
                target = impl_doc or impl_chain
                if impl_doc and impl_chain and impl_chain.lower() != impl_doc.lower():
                    slot = "MISMATCH"
                    failed.append(f"{name}: proxy resolves to {impl_chain}, docs say {impl_doc}")
                code = bytes.fromhex(rpc(rpc_url, "eth_getCode", [target, "latest"])[2:])
                if not code:
                    failed.append(f"{name}: no code at {target}")
                impls[name] = target
                shown = impl_doc or f"{impl_chain} (from slot)"
                print(f"  {name:<40} {shown:<44} {slot:<9} {len(code):>7}  0x{keccak256(code).hex()}")
            except Exception as exc:  # noqa: BLE001
                unchecked.append(f"{name}: RPC error {exc}")
                print(f"  {name:<40} RPC error: {exc}")

    # ---- Step B ----------------------------------------------------------------
    print("\n== B. Verified source vs pinned lido-core (Etherscan v2, Sourcify)")
    if not es_key:
        unchecked.append("ETHERSCAN_API_KEY not set; Etherscan source comparison skipped")
        print("  ETHERSCAN_API_KEY not set: skipping Etherscan comparison.")
    for name, proxy, impl_doc, path in rows:
        target = impls.get(name) or impl_doc
        if path is None:
            unchecked.append(f"{name}: built outside lidofinance/core (separate repository); step B not applicable")
            print(f"  {name:<40} {target}  built from a separate repository, not lido-core: source diff not applicable")
            continue
        if not target:
            unchecked.append(f"{name}: implementation unknown without RPC")
            print(f"  {name}: implementation address unknown (no RPC); skipped")
            continue
        line = f"  {name:<40} {target}"
        if es_key:
            try:
                info = etherscan_sources(target, es_key)
                if not info.get("SourceCode"):
                    failed.append(f"{name}: not verified on Etherscan")
                    print(f"{line}  NOT VERIFIED on Etherscan")
                else:
                    srcs = parse_etherscan_sources(info["SourceCode"])
                    settings = info.get("CompilerVersion", "?")
                    extra = f"optimizer={info.get('OptimizationUsed')} runs={info.get('Runs')} evm={info.get('EVMVersion')}"
                    print(f"{line}  etherscan: verified [{info.get('ContractName')}] {settings} {extra}")
                    print(f"  {'':<40} {report_bundle(name, 'Etherscan', srcs, core, path, failed, unchecked, notes)}")
                time.sleep(0.25)  # free-tier rate limit
            except Exception as exc:  # noqa: BLE001
                unchecked.append(f"{name}: Etherscan error {exc}")
                print(f"{line}  Etherscan error: {exc}")
        if not args.no_sourcify:
            status, rec = sourcify_record(target)
            print(f"  {name:<40} {target}  sourcify: {status}")
            if rec is None:
                unchecked.append(f"{name}: Sourcify has no record ({status})")
                continue
            comp = rec.get("compilation") or {}
            srcs = rec.get("sources") or {}
            if not srcs:
                unchecked.append(f"{name}: Sourcify record without sources")
                continue
            verdict = report_bundle(name, "Sourcify", srcs, core, path, failed, unchecked, notes)
            print(f"  {'':<40} [{comp.get('fullyQualifiedName')}] solc {comp.get('compilerVersion')}: {verdict}")

    # ---- Step C ----------------------------------------------------------------
    if args.recompile:
        print("\n== C. Recompilation (not performed)")
        forge = shutil.which("forge")
        npx = shutil.which("npx")
        print(f"  forge on PATH: {forge or 'no'};  npx on PATH: {npx or 'no'}")
        print("  Reproducing the deployed bytecode from lido-core requires, per contract, the exact solc")
        print("  version and settings shown in step B (0.4.24, 0.6.12, 0.8.9 and 0.8.25 are all used),")
        print("  the pinned npm dependencies (`yarn install --frozen-lockfile` in lido-core) and")
        print("  `yarn hardhat compile`; then compare artifacts/**/deployedBytecode (metadata hash stripped")
        print("  or matched) with the keccak256 printed in step A. Sourcify 'exact_match' in step B means")
        print("  Sourcify already performed that recompilation including the metadata hash.")

    # ---- Summary ---------------------------------------------------------------
    print("\n== Summary")
    for n_ in notes:
        print(f"  note: {n_}")
    for u in unchecked:
        print(f"  unchecked: {u}")
    for f in failed:
        print(f"  FAIL: {f}")
    if failed:
        print(f"  RESULT: {len(failed)} failure(s)")
        return 1
    if unchecked:
        print(f"  RESULT: no failure, {len(unchecked)} check(s) not performed")
        return 2
    print("  RESULT: all performed checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
