# P-TOPUP-2 — lift the two model bounds

## CLAIM

- **Guarantee:** `P-TOPUP-2`
- **Bounds lifted:** (i) Verity parent premise `count ≤ 32`; (ii) single-call
  exclusion of same-block accumulation
- **Branch:** `grok/lido-topup2-unbounded-20260912`
- **Base:** `origin/main` @ `1a40db36df3990da9287ac7b03b7e9a1e9bcffe4`
- **Pinned Solidity:** `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`
- **Lean toolchain:** `leanprover/lean4:v4.31.0` (`lean-toolchain`)
- **Verity pin:** `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` (`lakefile.lean`)
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** ready — both bounds lifted; Spark raccord is a later agent

This lot does **not** claim the already-merged TOPUP pointer-origin / keccak
lanes and does **not** claim Spark `A-ABSTRACT-TX`. No `spark/*` branch or PR
exists on this unbounded / multi-call subject (checked 2026-09-12 against
`origin` and GitHub search). Parallel open work `grok/lido-topup-wei-alloc-20260912`
(PR #407) is a different P-TOPUP-2 surface (live wei / `allocateDeposits`).

No existing Lean, registry, Trust, lakefile, or import-DAG file is edited.

## Verdict

| Bound | Origin | Disposition |
| --- | --- | --- |
| (i) `count ≤ 32` | **Model.** Not a StakingRouter / StakingModule constant. | Generalized: derived consumer on every count; induction on the key list; registered parent is an instance at the frozen 32. |
| (ii) same-block exclusion | **Model** of a missing gwei accumulator. Public gateway still refuses a second positive same-block call via `lastTopUpBlock` + `minBlockDistance ≥ 1`. | Generalized: `n` sequential calls on persistent gateway storage; sum ≤ `maxTopUpPerBlockGwei`. Router-only two-call exceedance is a kill-line, not a published finding. |

## (i) Where the 32 is — and is not

Searched pinned `17005714f151e5502c559932319a3f2f74ac2436`:

| Location | Guard / constant | Literal 32? |
| --- | --- | --- |
| `StakingRouter.sol:761-782` `_validateTopUpInputs` | `n == 0` → `EmptyKeysList`; sibling lengths; `PUBKEY_LENGTH` | No |
| `StakingRouter.sol:679-759` `topUp` | share / `maxTopUpPerBlockWei` / module `allocateDeposits` / sum ≤ target | No count cap |
| `IStakingModuleV2.sol:21-27` `allocateDeposits` | no count parameter bound | No |
| `TopUpGateway.sol:174-176` | `if (validatorsCount > $.maxValidatorsPerTopUp) revert MaxValidatorsPerTopUpExceeded();` | **No.** `$.maxValidatorsPerTopUp` is a packed `uint64` storage word (`TopUpGateway.sol:42`, ERC-7201 slot `0x22e5…2200`). `_setMaxValidatorsPerTopUp` (`:355-360`) admits every value in `1 .. 2^64-1`. |
| `LidoSRv3/Audit/Verity/Topup2DistributionTx.lean:37` | `def maxValidatorsPerTopUp : Nat := 32` | **Yes — model freeze** |
| `PTopup2Verity.verity_tx_simulates_topup2_spec` | premise `hMax : requested.length ≤ maxValidatorsPerTopUp` | **Yes — parent premise** |

Router `32` mentions at this pin are the 32-ether type-1 effective-balance unit
and `MAX_STAKING_MODULES_COUNT`, not a per-top-up key cap.

The registered Verity parent therefore assumes a model constant. The leftover
walk (`consumeBudget` / `sourceRun`) is already defined on every list length.
This lot states that unbounded consumer, proves it by induction on the key
list, and registers the existing parent as the instance `count ≤ 32`.

A “drop the 32-guard” mutant is **not** refused by StakingRouter /
IStakingModuleV2. TopUpGateway refuses `count > $.maxValidatorsPerTopUp`,
which is the stored word, not the literal 32. That is why the bound is
generalized rather than documented as a contract constant.

## (ii) Same-block accumulation

`aggregate_bounded_by_block_cap` is a single-call leftover walk of
`transitionBudget = min(valueGwei, min(moduleLimit, maxTopUpPerBlockGwei))`.
Pinned router storage (`SRTypes.sol` slot 5) holds the **config**
`maxTopUpPerBlockGwei`. It does not hold a used-this-block gwei counter.
Each `StakingRouter.topUp` (`:696-700`, `:736-738`) reapplies the full cap.

Pinned gateway storage that *is* written per successful positive top-up
(`TopUpGateway.sol:234-236`, `:340-345`):

- `lastTopUpBlock` (`uint32`)
- `lastTopUpTimestamp` (`uint32`)

Admission (`:324-329`, `:179`):

```
lastTopUpBlock == 0 || block.number - lastTopUpBlock >= minBlockDistance
```

`_setMinBlockDistance` (`:361-365`) reverts `ZeroValue` on `0`, so every
initialized gateway has `minBlockDistance ≥ 1`. `_setLastTopUpData` runs only
when `totalLimits > 0`. The sentinel `lastTopUpBlock == 0` means “never
topped up”; the n-call theorem therefore takes `blockNumber ≠ 0` so a write
is distinguishable from the sentinel (block 0 / `uint32` wrap are excluded,
not renamed parent premises).

On that storage, at most one committed positive gateway top-up can occur in
the same block. Combined with the single-call parent cap, the sum of
allocations over `n` sequential same-block calls is ≤ `maxTopUpPerBlockGwei`.

A mutant that drops the `lastTopUpBlock` write (or sets `minBlockDistance = 0`)
lets two calls each take the full cap. That kill-line shows the distance
lock is load-bearing. It is **not** a published finding: the pinned public
entry `TopUpGateway.topUp` refuses the second positive same-block call.
Router-only double application is auth-gated to the gateway
(`StakingRouter.sol:686` `_checkAppAuth(_getTopUpGateway())`).

Thomas: no `audit/findings/topup2-multicall-cap.md`. The product name
“per-block” is implemented as per-call cap plus a frequency lock, not a
gwei accumulator. Signal only; do not publish.

## Additive files

- `LidoSRv3/Audit/Verity/TopupUnboundedCount.lean`
- `LidoSRv3/Audit/Verity/TopupMultiCallBlockCap.lean`
- `LidoSRv3/Tests/TopupUnboundedCountMutants.lean`
- `LidoSRv3/Tests/TopupUnboundedMultiCallMutants.lean`
- `audit/topup2-unbounded/README.md` (this file)

`LidoSRv3Test` globs `LidoSRv3.Tests.*`. The Verity modules are compiled as
imports of those tests. `lakefile.lean` is not edited (Spark raccord may add
`.one` lines later).

## Hypotheses (not renamed parent premises)

| Hypothesis | Source |
| --- | --- |
| leftover walk / `sourceRun` on an arbitrary-length key list | `consumeBudget` / `Topup2Correspondence.sourceRun` already total on `List` |
| `count ≤ 32` only when instantiating the registered Verity parent | model freeze, not Solidity |
| `minBlockDistance ≥ 1` | `TopUpGateway.sol:361-365` |
| `blockNumber ≠ 0` and `lastTopUpBlock ≤ blockNumber` | sentinel `lastTopUpBlock == 0`; monotone blocks |
| each call’s `transition` is the existing leftover walk | registered parent, used as a lemma |

## Open (not this lot)

- Live wei conversion / module `allocateDeposits` policy (PR #407).
- SSZ / EIP-4788 / `TOP_UP_ROLE` / pause / root-age / WC 0x02.
- Trust registration and `guarantees.yaml` Spark raccord.
- `uint32(block.number)` wrap (~2^32) collapsing the `lastTopUpBlock == 0`
  sentinel — excluded, not claimed as a mainnet finding.

## Controls

Verified at `/workspace`, toolchain `leanprover/lean4:v4.31.0`, Solidity pin
`17005714f151e5502c559932319a3f2f74ac2436`.

```
lake build LidoSRv3.Tests.TopupUnboundedCountMutants
lake build LidoSRv3.Tests.TopupUnboundedMultiCallMutants
lake build LidoSRv3Test
```

`#print axioms` on every export: only `propext` / `Classical.choice` /
`Quot.sound` (or none). No `sorry`, no stub, no renamed premise.

## Commits

| SHA | Lot | Proved under | Open |
| --- | --- | --- | --- |
| `43903ef1` | claim | — | both bounds |
| `e642630a` | prove | leftover walk ∀ keys; `minBlockDistance ≥ 1`; `blockNumber ≠ 0` | Spark raccord |
| `2688fcdd` | test | 33-key lockstep; honest n=2 sum = cap; no-lock sum = 2×cap | — |
| `182b2220` | fix | same; no `sorryAx` | Spark raccord / live wei / SSZ |
| `15d9c592` | docs | `lake build` of both mutant targets and `LidoSRv3Test` green | Spark raccord / live wei / SSZ |
