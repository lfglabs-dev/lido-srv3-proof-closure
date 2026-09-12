# P-TOPUP-2 — live wei conversion + module-selected allocateDeposits

## CLAIM

- **Guarantee:** `P-TOPUP-2`
- **fidelity.missing entry:** `live wei conversion and the module-selected allocateDeposits return/policy`
- **Branch:** `grok/lido-topup-wei-alloc-20260912`
- **Base:** `origin/main` @ `1a40db36df3990da9287ac7b03b7e9a1e9bcffe4`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** closed on this consumer — Spark raccord pending

This lot does **not** claim the closed DEPOSIT LinksSource entry (PR #405)
or the ACCOUNT / ADDRESS / RESERVE fidelity PRs. Spark `lido-topup-*-registration`
and `lido-topup2-oracle-independence-registration` branches register existing
TOPUP consumers; they do not close this live wei / allocateDeposits entry.

## Targeted gap

The registered parent walks leftover budget in gwei (`consumeBudget` /
`transition`). Live `StakingRouter.topUp` converts units and admits a
**module-selected** `allocateDeposits` return. This lot models those two
facts additively. Parents, yaml, and Trust are not edited. Do not compose
with P-TOPUP-1.

## What the pinned router imposes

| Conversion / check | Source | Constraint |
|---|---|---|
| gwei → wei | `TopUpGateway.sol:226` / `StakingRouter.sol:696` | `* 1 gwei` |
| floor to gwei | `StakingRouter.sol:706` | `amount - amount % 1 gwei` |
| live target | `:700` then `:706` | `floor(min(moduleAlloc, maxTopUpPerBlockGwei * 1 gwei))` |
| module return | `:717-718` `IStakingModuleV2.allocateDeposits` | any wei vector; zeros allowed; sum may be `< depositAmount` |
| alignment | `:724` | `allocations[i] % 1 gwei == 0` |
| per-key limit | `:728` | `allocations[i] ≤ _topUpLimits[i]` |
| sum | `:737` | `amount ≤ rounded` |

`consumeBudget` is not that policy: two 20-gwei candidates under a 20-gwei
cap yield `[20, 0]` in the parent and may yield `[0, 20e9]` from the module.

## What is proved

Additive files:

- `LidoSRv3/Audit/Source/TopupWeiAlloc.lean`
- `LidoSRv3/Tests/TopupWeiAllocMutants.lean`

| Theorem | Source span | Claim |
|---|---|---|
| `mulGwei` / `divGwei` / `floorGwei` | `:226` / `:696` / `:706` | live `* 1 gwei`, `/ 1 gwei`, floor |
| `liveRoundedTarget` | `:696-706` | min then floor; always gwei-aligned |
| `admittedAllocations` | `:724/:728/:737` | fail-closed admission of the module return |
| `admitted_aligned` | `:724` | every admitted wei is `% 1 gwei == 0` |
| `admitted_le_limit` | `:728` | pointwise `alloc ≤ limit` |
| `admitted_sum_le_rounded` | `:737` | sum ≤ rounded target |
| `admitted_sum_le_block_cap` | `:696-737` | admitted sum ≤ `maxTopUpPerBlockGwei * 1 gwei` |
| `misaligned_rejected` | `:724` | 1 wei is `none` |
| `over_limit_rejected` | `:728` | `2e9 > 1e9` is `none` |
| `over_target_rejected` | `:737` | `20e9 > 10e9` rounded is `none` |
| `module_policy_not_consumeBudget` | residual | `[0, 20e9]` admitted; `consumeBudget` is `[20, 0]` |

Mutants: 5 gwei round-trip; floor dust +3+7; live cap 50 vs 20; happy `[10e9, 10e9]`; zeros; misaligned 1 wei; over-limit; over-target; arity mismatch; module-right vs leftover-left.

Axioms: `propext` / `Quot.sound` only. No `sorryAx`.

## Spark raccord (do not apply in this lot)

In `audit/guarantees.yaml` under `P-TOPUP-2`:

1. Remove this exact `fidelity.missing` string:
   ```
   - "live wei conversion and the module-selected allocateDeposits return/policy"
   ```
2. Add a `fidelity.covered` bullet that `mulGwei` / `floorGwei` /
   `liveRoundedTarget` are the pinned `* 1 gwei` / `% 1 gwei` conversions
   and that `admittedAllocations` admits a module-selected
   `allocateDeposits` return under `:724/:728/:737`, not `consumeBudget`.
   Keep the 32-guard as premise/guard necessity. Do not compose with
   P-TOPUP-1.

## Honesty (not this entry)

- The registered parent still walks `consumeBudget`. This consumer does
  not replace it.
- Module-internal policy (CSM queue cursor, which key gets the wei) is
  not modeled; only router admission of the returned vector.
- `Lido.withdrawDepositableEther` and `makeBeaconChainTopUp` remain a
  separate P-TOPUP-2 missing entry.
- `gwei versus wei units and 48-byte pubkeys`, keccak oracle, and
  trusted `pendingBalanceGwei` remain other missing entries.
- Same-block accumulation across calls stays excluded.
- The 32-guard witness stays premise/guard necessity.
- Pack W2 `valueWei / GWEI` on `transitionBudget` is the abstract Nat
  child; it is not this live conversion.
