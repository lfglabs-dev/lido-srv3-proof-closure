import LidoSRv3.Audit.Guarantees.PTopup2
import Verity.Core
import Verity.Stdlib.Math

/-! Source-shaped interpreter for `TopUpGateway.topUp` and `_evaluateTopUpLimit`
at `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

The Nat scaffold below remains a regression helper for the historical
CallProgram plane.  The checked-`uint256` interpreter is the promoted source
plane: `effectiveBalance + pendingBalanceGwei` is `safeAdd` and reverts on
overflow, matching Solidity 0.8 checked addition at
`TopUpGateway.sol` lines 408--412.

## Units

Solidity's `TopUpGateway.sol:226 topUpLimits[i] = _evaluateTopUpLimit(vw, _topUps.pendingBalanceGwei[i]) * 1 gwei;`
converts the gwei limit to wei before handing it to `StakingRouter.topUp`.
This module keeps every quantity in **gwei**: `sourceLimits` is line 226
*without* the `* 1 gwei`, and `requested`, `moduleLimit`, `remainingCap`,
`valueGwei` are all gwei words.  The `* 1 gwei` cannot overflow for limits
bounded by `targetBalanceGwei`, so dropping it is a unit choice, not a
semantic change.

## Name correspondence

| Solidity (TopUpGateway.sol) | Lean |
|---|---|
| `_validator.effectiveBalance` (408) | `effective` |
| `_pendingBalanceGwei` (408) | `pending` |
| `$.targetBalanceGwei` (409, 411) | `target` |
| `$.minTopUpGwei` (412) | `minTopUp` |
| `topUpLimits` (194, 226) | `topUpLimits` (input) / `evaluatedLimits` (recomputed) |
| `totalLimits` (196, 227) | `used` (the budget actually consumed, see `sourceRun`) |
-/

namespace LidoSRv3.Audit.Source.Topup2

open LidoSRv3.Audit.Guarantees.PTopup2
open Verity.Stdlib.Math

abbrev Word := Verity.Core.Uint256

/-- Inputs that must be independently established before a deployed runtime can
be identified with the pinned source.  They are parameters, never axioms. -/
structure RuntimeProvenance where
  gatewayAddress : Nat
  gatewayCodehash : Nat
  verifierAddress : Nat
  verifierCodehash : Nat
  forkId : Nat
  canonicalGatewayCodehash : Nat
  canonicalVerifierCodehash : Nat
  canonicalForkId : Nat
  deriving Repr, DecidableEq

def RuntimeProvenance.Valid (p : RuntimeProvenance) : Prop :=
  p.gatewayCodehash = p.canonicalGatewayCodehash ∧
  p.verifierCodehash = p.canonicalVerifierCodehash ∧
  p.forkId = p.canonicalForkId

/-- The source-shaped execution reads exactly the pinned limit computation and
left-to-right aggregate-budget transition. -/
def execute (batch : TopupBatch) (cfg : TopupConfig) : List Nat :=
  transition batch cfg

theorem execute_matches_pinned_transition (batch : TopupBatch) (cfg : TopupConfig) :
    execute batch cfg = transition batch cfg := rfl

/-- Conditional bound for the source-shaped scaffold.  This theorem does not
establish Solidity correspondence for overflowing effective-plus-pending
balances and therefore does not promote the SOURCE layer. -/
theorem source_aggregate_bounded_by_block_cap
    (provenance : RuntimeProvenance) (_hProvenance : provenance.Valid)
    (batch : TopupBatch) (cfg : TopupConfig) (_hBatch : well_formed_batch batch cfg) :
    (execute batch cfg).sum ≤ cfg.maxTopUpPerBlockGwei := by
  rw [execute_matches_pinned_transition]
  exact aggregate_bounded_by_block_cap batch cfg

/-! ## Checked-word source interpreter

Independent of `evaluated_topup_limit` / `transition`.  Overflow of
`effective + pending` is `none`, not a total Nat sum. -/

def minWord (a b : Word) : Word := if a ≤ b then a else b

/-! ## TopUpGateway._evaluateTopUpLimit (TopUpGateway.sol:396-415) -/

/-- `TopUpGateway.sol:396-415 _evaluateTopUpLimit(ValidatorWitness calldata _validator, uint256 _pendingBalanceGwei) returns (uint256)`.

Not transcribed: 403-405
`if (_validator.exitEpoch != FAR_FUTURE_EPOCH || _validator.slashed) { return 0; }`
(the exit / slash filter; exited or slashed validators are upstream of this
numeric slice and must be filtered by the caller); 407 `Storage storage $ = _gatewayStorage();`
(`target` / `minTopUp` are explicit inputs).
Added by the model: the `none` branch of the checked addition (Solidity 0.8
panics).

Pinned `_evaluateTopUpLimit` after activation/exit/slash
filters.  Locals follow the source: `currentTotal`, then `topUpLimit`.
The addition is checked; overflow is `none`. Slash/exit/activation arrays
are upstream of this numeric slice. -/
def evaluateTopUpLimit (effective pending target minTopUp : Word) : Option Word := do
  -- TopUpGateway.sol:408  uint256 currentTotal = _validator.effectiveBalance + _pendingBalanceGwei;
  let currentTotal ← safeAdd effective pending
  -- TopUpGateway.sol:409  if (currentTotal >= $.targetBalanceGwei) return 0;
  if target ≤ currentTotal then some 0
  else
    -- TopUpGateway.sol:411  uint256 topUpLimit = $.targetBalanceGwei - currentTotal;
    -- (`safeSub` cannot fail here: the branch has `currentTotal < target`)
    let topUpLimit ← safeSub target currentTotal
    -- TopUpGateway.sol:412  if (topUpLimit < $.minTopUpGwei) return 0;
    -- TopUpGateway.sol:414  return topUpLimit;
    if topUpLimit < minTopUp then some 0 else some topUpLimit

/-- Solidity-facing name, TopUpGateway.sol:396. -/
abbrev _evaluateTopUpLimit := evaluateTopUpLimit

/-! ## TopUpGateway.topUp (TopUpGateway.sol:160-237) -/

/-- Left-to-right budget consumption, matching `consumeBudget` on words. -/
def sourceConsume : Word → List Word → Option (List Word × Word)
  | remaining, [] => some ([], remaining)
  | remaining, cand :: rest => do
      let allocated := minWord cand remaining
      let next ← safeSub remaining allocated
      let (tail, leftover) ← sourceConsume next rest
      some (allocated :: tail, leftover)

/-- First of the three passes (`sourceLimits`, `sourceCandidates`,
`sourceConsume`) that replace Solidity's single loop
`TopUpGateway.sol:204-228 for (uint256 i; i < validatorsCount; ++i) { ... }`.
This pass keeps only line 226
`topUpLimits[i] = _evaluateTopUpLimit(vw, _topUps.pendingBalanceGwei[i]) * 1 gwei;`
without the `* 1 gwei` (see the unit note in the module header); the
`totalLimits +=` of 227 is not accumulated here (it reappears as `used` in
`sourceRun`).  Length mismatch between `effective` and `pending` is `none`
(Solidity: 168-172 `WrongArrayLength`).

Per-key limits produced by the gateway evaluation loop.  Keeping this list
explicit is important: it is the live array passed to the module allocation
boundary, rather than an implicit constant hidden in the allocator. -/
def sourceLimits : List Word → List Word → Word → Word → Option (List Word)
  | [], [], _, _ => some []
  | e :: es, p :: ps, target, minTopUp => do
      let limit ← evaluateTopUpLimit e p target minTopUp
      let rest ← sourceLimits es ps target minTopUp
      some (limit :: rest)
  | _, _, _, _ => none

/-- Second pass: module requests are independently capped by the explicit
per-key limits.  This is the StakingRouter side (`StakingRouter.topUp`
consuming `topUpLimits`), not a TopUpGateway.sol line. -/
def sourceCandidates : List Word → List Word → Option (List Word)
  | [], [] => some []
  | r :: rs, limit :: limits => do
      let rest ← sourceCandidates rs limits
      some (minWord r limit :: rest)
  | _, _ => none

/-- `TopUpGateway.sol:160-237 topUp(TopUpData calldata _topUps)`, composed
with the StakingRouter budget it calls at 232.

Transcribed: 163-164 `uint256 validatorsCount = _topUps.validatorIndices.length; if (validatorsCount == 0) revert WrongArrayLength();`
(as `effective.length == 0`); 226 `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei;`
(via `sourceLimits`, in gwei); 227 `totalLimits += topUpLimits[i];` (as the
consumed total `used`, see below).  174-175
`if (validatorsCount > $.maxValidatorsPerTopUp) revert MaxValidatorsPerTopUpExceeded();`
is transcribed in `Topup2DistributionTx.allocate`, not here.

Not transcribed: 166-172 the four `.length != validatorsCount` checks
(`WrongArrayLength`; a length mismatch is the `none` of `sourceLimits` /
`sourceCandidates`); 179 `_requireBlockDistancePassed();`; 184
`_verifyRootAge(_topUps.beaconRootData);`; 189-190 withdrawal-credentials
lookup and `_requireWithdrawalCredentials02`; 208 `WrongPubkeyLength`;
214-216 `InvalidValidatorIndicesSortOrder`; 219
`_verifyValidatorWasActivated(...)`; 221 `_verifyValidator(...)`; 223
`pubkeys[i] = vw.pubkey;`; 232 `stakingRouter.topUp(...)` as an external call
(its budget arithmetic is inlined below); 234-236
`if (totalLimits > 0) { _setLastTopUpData(); }`.

Added by the model: the budget `min valueGwei (min moduleLimit remainingCap)`
(StakingRouter share / value / block cap, not a TopUpGateway line); the
left-to-right consumption `sourceConsume`; the consistency test
`evaluatedLimits != topUpLimits`, which checks that the caller-supplied
`topUpLimits` array is the one line 226 would compute (Solidity computes it,
the model receives it and re-evaluates); the tuple result
`(allocs, remaining, used)` where `used` is the budget actually consumed
(Solidity's `totalLimits` is the *sum of limits*, an upper bound of `used`).

Pinned-source batch: evaluate and bind the explicit per-key limit array,
take the share/value/block budget, then consume it left to right.  Empty,
misaligned, or inconsistent arrays revert. -/
def sourceRun (effective pending requested topUpLimits : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word) :
    Option (List Word × Word × Word) :=
  -- TopUpGateway.sol:163-164  uint256 validatorsCount = _topUps.validatorIndices.length; if (validatorsCount == 0) revert WrongArrayLength();
  if effective.length == 0 then none
  else
    -- TopUpGateway.sol:226  topUpLimits[i] = _evaluateTopUpLimit(vw, _topUps.pendingBalanceGwei[i]) * 1 gwei;   (gwei here)
    match sourceLimits effective pending target minTopUp with
    | none => none
    | some evaluatedLimits =>
        -- added by the model: the supplied array must be the evaluated one
        if evaluatedLimits != topUpLimits then none
        else
          -- StakingRouter side of 232 `stakingRouter.topUp(...)`: per-key cap, budget, consumption
          match sourceCandidates requested topUpLimits with
          | none => none
          | some candidates =>
              -- added by the model: share / value / block budget (StakingRouter)
              let budget := minWord valueGwei (minWord moduleLimit remainingCap)
              match sourceConsume budget candidates with
              | none => none
              | some (allocs, leftover) =>
                  match safeSub budget leftover with
                  | none => none
                  | some used =>
                      match safeSub remainingCap used with
                      | none => none
                      | some remaining => some (allocs, remaining, used)

/-- Overflow of the pinned checked addition is a source revert, not a total
Nat wrap. -/
theorem evaluateTopUpLimit_overflow
    (effective pending target minTopUp : Word)
    (h : MAX_UINT256 < effective.val + pending.val) :
    evaluateTopUpLimit effective pending target minTopUp = none := by
  unfold evaluateTopUpLimit
  simp [safeAdd, Bind.bind, h]

/-- Solidity-facing name, TopUpGateway.sol:160. -/
abbrev topUp := sourceRun

end LidoSRv3.Audit.Source.Topup2
