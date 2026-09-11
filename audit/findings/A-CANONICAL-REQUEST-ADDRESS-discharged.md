# Finding: A-CANONICAL-REQUEST-ADDRESS discharged from deployed bytecode

**Category:** Assumption discharge — outcome (a) per the goal loop.
**Severity:** N/A (bookkeeping — accepted assumption boundary tightened).
**Scope:** Only P-CONSOLIDATION-ETH-1 declared `A-CANONICAL-REQUEST-ADDRESS`; retired.
**Status:** Assumption retired from `audit/assumptions.yaml` and from
`P-CONSOLIDATION-ETH-1.assumptions` in `audit/guarantees.yaml`.

## Discharge

The Lean model literal
`LidoSRv3.Audit.Verity.ConsolidationCallFragment.consolidationPredeploy`
= `0x0000BBdDc7CE488642fb579F8B00f3a590007251` is now anchored to the
actual `CONSOLIDATION_REQUEST` immutable inside the deployed Lido
`WithdrawalVault` implementation bytecode, reducing
`A-CANONICAL-REQUEST-ADDRESS` to the accepted global assumption
`A-RUNTIME-PROVENANCE`.

## Provenance chain

Recorded in `audit/artifacts.lock.json`:

- Proxy: `0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f` (WithdrawalVault).
- Implementation slot resolves to
  `0xfB4521BD151BFB45DB6045D2d07e58e0f597e340`.
- Runtime bytecode fixture: `fixtures/deployed/WithdrawalVault-impl-runtime.bin`.
- Fixture size: 5088 bytes.
- Fixture SHA-256:
  `a3e9e582928d58cdfe87a6405ad1a7967f720cafa97f98ae8d619e36b961aa7f`.
- `CONSOLIDATION_REQUEST` immutable is patched by `solc` at byte
  offset **730**, width **20 bytes**.
- The 20 bytes at that offset are literally
  `0000bbddc7ce488642fb579f8b00f3a590007251`, i.e. the canonical
  EIP-7251 consolidation-request predeploy.

## Reproduction

```bash
python3 scripts/verify_consolidation_request_immutable.py
```

The script recomputes the fixture SHA-256, extracts the 20-byte
immutable at offset 730, and compares to the pinned expected value.
With `ETH_RPC_URL` set, it additionally refetches the deployed
runtime bytecode via `eth_getCode` and re-verifies that the fixture
still matches (this is the exact `A-RUNTIME-PROVENANCE` check for
this immutable).

The Lean proof lives in
`LidoSRv3/Audit/Provenance/CanonicalRequestAddress.lean` and is
composed of three theorems (all depending only on
`{propext, Classical.choice, Quot.sound}`):

1. `deployed_consolidation_request_immutable_equals_canonical`
   — the 20 fixture bytes at the extraction offset fold (big-endian)
   into `0x0000BBdDc7CE488642fb579F8B00f3a590007251`. Proof by
   `decide +kernel`.
2. `model_consolidation_predeploy_equals_canonical`
   — the model literal `consolidationPredeploy` equals the same
   canonical value. Proof by `rfl`.
3. `model_predeploy_equals_deployed_immutable`
   — composes 1 and 2: model literal = fixture-extracted bytes.

## Trust chain now reads

- Runtime bytecode == fixture   (verified by
  `scripts/verify_consolidation_request_immutable.py` under
  `A-RUNTIME-PROVENANCE`).
- Fixture[730:750] = canonical predeploy   (proved in Lean by
  `decide +kernel`).
- Model literal = canonical predeploy   (proved in Lean by `rfl`).
- ∴ model literal = deployed immutable (composition).

## Actions taken in this commit

- Added `fixtures/deployed/WithdrawalVault-impl-runtime.bin` (raw
  runtime bytecode, 5088 bytes).
- Added `scripts/verify_consolidation_request_immutable.py`
  (offline + optional live re-verification).
- Extended `audit/artifacts.lock.json` with the
  `deployed_bytecode.WithdrawalVault_implementation` entry (proxy,
  implementation, fixture path/size/SHA-256, immutable extraction).
- Added `LidoSRv3/Audit/Provenance/CanonicalRequestAddress.lean` with
  the three theorems above.
- Registered the three theorems in `LidoSRv3/Audit/Trust.lean`.
- Removed `A-CANONICAL-REQUEST-ADDRESS` from `audit/assumptions.yaml`
  (13 assumptions remaining).
- Removed `A-CANONICAL-REQUEST-ADDRESS` from
  `P-CONSOLIDATION-ETH-1.assumptions` in `audit/guarantees.yaml`.
- Updated `EXPECTED_CANONICAL_CLAIMS["P-CONSOLIDATION-ETH-1"]` in
  `scripts/audit_metadata.py`.
- Regenerated `audit/STATUS.md`, `audit/ROADMAP.md`,
  `audit/R1-FINAL-AUDITOR-REPORT.md`.
- Advanced `R1_REVIEW_BASE` and updated
  `R1_REPORT_INPUT_SHA256["audit/guarantees.yaml"]` (follow-up commit).
