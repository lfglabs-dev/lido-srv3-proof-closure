# Finding: A-TOPUP-BEACON-ADDRESS and A-DEPOSIT-CONTRACT discharged from deployed bytecode

**Category:** Assumption discharge — outcome (a) per the goal loop.
**Severity:** N/A (bookkeeping — accepted assumption boundary tightened).
**Scope:** `A-TOPUP-BEACON-ADDRESS` was declared by P-TOPUP-1; `A-DEPOSIT-CONTRACT` was declared by P-DEPOSIT-1 and P-ALLOC-EXEC-1. Both are retired.
**Status:** Assumptions retired from `audit/assumptions.yaml`; `A-TOPUP-BEACON-ADDRESS` removed from `P-TOPUP-1.assumptions`; `A-DEPOSIT-CONTRACT` removed from `P-DEPOSIT-1.assumptions` and `P-ALLOC-EXEC-1.assumptions` in `audit/guarantees.yaml`.

## Discharge

The Lean model literals
`LidoSRv3.Audit.Verity.TopupTx.beaconAddress` (=
`LidoSRv3.Audit.Guarantees.PTopup1.canonicalBeaconDepositAddress` =
`LidoSRv3.Audit.Guarantees.PDeposit1.canonicalDepositContractAddress` =
`0x00000000219ab540356cBB839Cbe05303d7705Fa`) are now anchored to the
actual `DEPOSIT_CONTRACT` immutable inside the deployed Lido
`StakingRouter` implementation bytecode, reducing both
`A-TOPUP-BEACON-ADDRESS` and `A-DEPOSIT-CONTRACT` to the accepted global
assumption `A-RUNTIME-PROVENANCE`.

This is the same singleton on-chain address for both hypotheses: the
top-up beacon deposit target used by `StakingRouter` is the canonical
Ethereum beacon deposit contract that the source-level P-DEPOSIT-1
already pins as `canonicalDepositContractAddress`. A single deployed
immutable extraction therefore discharges both.

## Provenance chain

Recorded in `audit/artifacts.lock.json` under
`deployed_bytecode.StakingRouter_implementation`:

- Proxy: `0xFdDf38947aFB03C621C71b06C9C70bce73f12999` (StakingRouter).
- Implementation slot resolves to
  `0xDD76927045435C7605cf6f5F978cfb8CABDb5F80`.
- Runtime bytecode fixture: `fixtures/deployed/StakingRouter-impl-runtime.bin`.
- Fixture size: 21087 bytes.
- Fixture SHA-256:
  `c30ed4e63cb0a57dca577484afff0765fcaa9840d75b440067fd55c7d4fc7013`.
- `DEPOSIT_CONTRACT` immutable is patched by `solc` at byte offset
  **7525**, width **20 bytes**.
- The 20 bytes at that offset are literally
  `00000000219ab540356cbb839cbe05303d7705fa`, i.e. the canonical
  Ethereum beacon deposit contract address.

## Reproduction

```bash
python3 scripts/verify_beacon_deposit_immutable.py
```

The script recomputes the fixture SHA-256, extracts the 20-byte
immutable at offset 7525, and compares to the pinned expected value.
With `ETH_RPC_URL` set, it additionally refetches the deployed runtime
bytecode via `eth_getCode` and re-verifies that the fixture still
matches (this is the exact `A-RUNTIME-PROVENANCE` check for this
immutable).

The Lean proof lives in
`LidoSRv3/Audit/Provenance/BeaconDepositAddress.lean` and is composed
of six theorems, each depending only on the accepted trust base
`{propext, Classical.choice, Quot.sound}` (three actually depend on no
axioms at all):

1. `deployed_beacon_deposit_immutable_equals_canonical` — the 20 fixture
   bytes at the extraction offset fold (big-endian) into
   `0x00000000219ab540356cBB839Cbe05303d7705Fa`. Proof by `decide +kernel`.
2. `topup_verity_beacon_equals_canonical` — the Verity model literal
   `TopupTx.beaconAddress` equals the same canonical value. Proof by
   `decide`.
3. `topup_canonical_pin_equals_canonical` — the P-TOPUP-1 registered
   canonical pin equals the canonical value. Proof by `rfl`.
4. `deposit_canonical_pin_equals_canonical` — the P-DEPOSIT-1 registered
   canonical pin equals the canonical value. Proof by `rfl`.
5. `topup_verity_beacon_equals_deployed_immutable` — composes 1 and 2:
   Verity top-up model literal = fixture-extracted bytes. Closes
   `A-TOPUP-BEACON-ADDRESS` down to `A-RUNTIME-PROVENANCE`.
6. `deposit_canonical_pin_equals_deployed_immutable` — composes 1 and 4:
   P-DEPOSIT-1 canonical pin = fixture-extracted bytes. Closes
   `A-DEPOSIT-CONTRACT` down to `A-RUNTIME-PROVENANCE`.

## Trust chain now reads

- Runtime bytecode == fixture   (verified by
  `scripts/verify_beacon_deposit_immutable.py` under
  `A-RUNTIME-PROVENANCE`).
- Fixture[7525:7545] = canonical beacon deposit address   (proved in
  Lean by `decide +kernel`).
- Model literals = canonical beacon deposit address   (proved in Lean
  by `decide` / `rfl`).
- ∴ Verity top-up literal = P-DEPOSIT-1 canonical pin = deployed
  immutable (composition).

## Actions taken in this commit

- Added `fixtures/deployed/StakingRouter-impl-runtime.bin` (raw runtime
  bytecode, 21087 bytes).
- Added `scripts/verify_beacon_deposit_immutable.py` (offline + optional
  live re-verification).
- Extended `audit/artifacts.lock.json` with the
  `deployed_bytecode.StakingRouter_implementation` entry (proxy,
  implementation, fixture path/size/SHA-256, immutable extraction).
- Added `LidoSRv3/Audit/Provenance/BeaconDepositAddress.lean` with the
  six theorems above.
- Registered the six theorems in `LidoSRv3/Audit/Trust.lean`.
- Removed `A-TOPUP-BEACON-ADDRESS` and `A-DEPOSIT-CONTRACT` from
  `audit/assumptions.yaml` (11 assumptions remaining).
- Removed `A-TOPUP-BEACON-ADDRESS` from `P-TOPUP-1.assumptions` in
  `audit/guarantees.yaml`.
- Removed `A-DEPOSIT-CONTRACT` from `P-DEPOSIT-1.assumptions` and
  `P-ALLOC-EXEC-1.assumptions` in `audit/guarantees.yaml`.
- Updated `EXPECTED_CANONICAL_CLAIMS["P-TOPUP-1"]` and
  `EXPECTED_CANONICAL_CLAIMS["P-DEPOSIT-1"]` in `scripts/audit_metadata.py`.
- Regenerated `audit/STATUS.md`, `audit/ROADMAP.md`,
  `audit/R1-FINAL-AUDITOR-REPORT.md`.
- Advanced `R1_REVIEW_BASE` and updated
  `R1_REPORT_INPUT_SHA256["audit/guarantees.yaml"]` (follow-up commit).
