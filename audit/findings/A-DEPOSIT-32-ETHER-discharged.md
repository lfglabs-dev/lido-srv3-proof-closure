# Finding: A-DEPOSIT-32-ETHER discharged from deployed bytecode

**Category:** Assumption discharge -- outcome (a) per the goal loop.
**Severity:** N/A (bookkeeping -- accepted assumption boundary tightened).
**Scope:** `A-DEPOSIT-32-ETHER` was declared by `P-DEPOSIT-1` and `P-ALLOC-EXEC-1`; retired from both.
**Status:** Assumption retired from `audit/assumptions.yaml` and from `P-DEPOSIT-1.assumptions` and `P-ALLOC-EXEC-1.assumptions` in `audit/guarantees.yaml`.

## Discharge

The two production wei scales that carry the source deposit path --
`StakingRouter.MAX_EFFECTIVE_BALANCE_WC_TYPE_01` (an `immutable` set
by the constructor, `sr/StakingRouter.sol:65`) and
`BeaconChainDepositor.DEPOSIT_SIZE` (a `constant`,
`lib/BeaconChainDepositor.sol:24`) -- are now jointly bound to the
literal `32 * 10^18` wei (i.e. `32 ether`), reducing
`A-DEPOSIT-32-ETHER` to the accepted global assumption
`A-RUNTIME-PROVENANCE`.

## Provenance chain

Recorded in `audit/artifacts.lock.json` under
`deployed_bytecode.StakingRouter_implementation.immutable_extractions[1]`:

- Proxy: `0xFdDf38947aFB03C621C71b06C9C70bce73f12999` (StakingRouter).
- Implementation: `0xDD76927045435C7605cf6f5F978cfb8CABDb5F80`.
- Runtime bytecode fixture: `fixtures/deployed/StakingRouter-impl-runtime.bin`.
- Fixture size: 21087 bytes.
- Fixture SHA-256:
  `c30ed4e63cb0a57dca577484afff0765fcaa9840d75b440067fd55c7d4fc7013`
  (same fixture as A-TOPUP-BEACON-ADDRESS + A-DEPOSIT-CONTRACT).
- Every `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` read compiles to a `PUSH32`
  (opcode `0x7f`) of the constructor-patched immutable value; every
  `DEPOSIT_SIZE` read compiles to a `PUSH32` of the `32 ether` literal.
- Enumerating every offset where a 32-byte word appears immediately
  after `0x7f` and equals the 32-ether encoding
  `000000000000000000000000000000000000000000000001bc16d674ec800000`
  yields exactly **five** offsets in this fixture:
  `[5521, 12112, 14036, 15415, 20126]`.
- Each 32-byte payload folds big-endian to
  `32000000000000000000` wei = `32 * 10^18` wei = `32 ether`.

The joint discharge argument: the runtime read of the immutable and
of the constant are both `PUSH32 <32-byte>` sites. Any `PUSH32` in
the runtime whose payload equals the 32-ether word therefore covers
every runtime read of `MAX_EBType1` and `DEPOSIT_SIZE`. The
enumeration is total and the payload at every such offset is the
32-ether word. `MAX_EFFECTIVE_BALANCE_WC_TYPE_02` (`sr/StakingRouter.sol:66`)
is a distinct immutable with a different production value and does
not appear at any of these offsets.

## Reproduction

```bash
python3 scripts/verify_deposit_thirty_two_ether.py
```

The script:
1. Recomputes the fixture SHA-256 and compares to the pinned value.
2. Enumerates every `PUSH32(0x7f) <word>` site whose 32-byte payload
   equals the 32-ether encoding.
3. Asserts the offset set matches
   `(5521, 12112, 14036, 15415, 20126)` exactly.
4. Verifies each 32-byte payload folds big-endian to `32*10^18`.
5. With `ETH_RPC_URL` set, refetches the deployed implementation
   bytecode via `eth_getCode` and re-verifies the fixture SHA-256 still
   matches -- the exact `A-RUNTIME-PROVENANCE` check for this fixture.

## Lean proof

`LidoSRv3/Audit/Provenance/DepositThirtyTwoEther.lean` composes five
theorems, all of which are axiom-free (do not even depend on
`{propext, Classical.choice, Quot.sound}`):

1. `deployed_thirty_two_ether_push_folds_to_thirty_two_ether` -- the
   32-byte payload folds big-endian to `32 * 10^18`. Proof by
   `decide +kernel` on a concrete finite computation.
2. `deployed_maxEBType1_equals_pushed_value` -- the deployed
   production configuration's `maxEBType1` equals the fixture-extracted
   32-ether word.
3. `deployed_depositSize_equals_pushed_value` -- the deployed
   production configuration's `depositSize` equals the same
   fixture-extracted word.
4. `deployed_maxEBType1_equals_depositSize` -- joint equality in the
   deployed configuration: `MAX_EFFECTIVE_BALANCE_WC_TYPE_01 = DEPOSIT_SIZE`.
   Proof by `rfl`.
5. `deployed_production_config_thirty_two_ether` -- composed
   statement: both fields equal both `32 * 10^18` and the fixture
   payload.

## Trust chain now reads

- Runtime bytecode == fixture   (verified by
  `scripts/verify_deposit_thirty_two_ether.py` under
  `A-RUNTIME-PROVENANCE`).
- The set of `PUSH32` sites in the fixture whose 32-byte payload
  equals the 32-ether encoding is exactly `{5521, 12112, 14036,
  15415, 20126}`   (verified by the same script).
- Payload at each such site folds to `32 * 10^18`   (proved in Lean
  by `decide +kernel`).
- The deployed production configuration's `maxEBType1` and
  `depositSize` equal `32 * 10^18` = the fixture-extracted word
  (proved in Lean).
- Therefore, in the deployed StakingRouter,
  `MAX_EFFECTIVE_BALANCE_WC_TYPE_01 = DEPOSIT_SIZE = 32 * 10^18` wei
  = `32 ether`.

## Actions taken in this commit

- Extended `audit/artifacts.lock.json` with a second
  `immutable_extractions` entry in
  `deployed_bytecode.StakingRouter_implementation` (extraction_kind
  `push32_payload_enumeration`, five byte offsets, expected value
  hex/decimal, discharge target).
- Added `LidoSRv3/Audit/Provenance/DepositThirtyTwoEther.lean` with
  the five theorems above.
- Registered the five theorems in `LidoSRv3/Audit/Trust.lean`.
- Added `scripts/verify_deposit_thirty_two_ether.py` (offline + optional
  live re-verification of the fixture SHA).
- Removed `A-DEPOSIT-32-ETHER` from `audit/assumptions.yaml`
  (10 assumptions remaining).
- Removed `A-DEPOSIT-32-ETHER` from `P-DEPOSIT-1.assumptions` and
  `P-ALLOC-EXEC-1.assumptions` in `audit/guarantees.yaml`.
- Updated `EXPECTED_CANONICAL_CLAIMS["P-DEPOSIT-1"]` in
  `scripts/audit_metadata.py`.
- Regenerated `audit/STATUS.md`, `audit/ROADMAP.md`,
  `audit/R1-FINAL-AUDITOR-REPORT.md`.
- Advanced `R1_REVIEW_BASE` and updated
  `R1_REPORT_INPUT_SHA256["audit/guarantees.yaml"]` (follow-up commit).
