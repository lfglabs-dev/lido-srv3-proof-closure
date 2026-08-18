import LidoSRv3.Audit.Guarantees.PTopup2
import Verity.Core
import Verity.Stdlib.Math

/-! Source-shaped interpreter for `TopUpGateway.topUp` and `_evaluateTopUpLimit`
at `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

The Nat scaffold below remains a regression helper for the historical
CallProgram plane.  The checked-`uint256` interpreter is the promoted source
plane: `effectiveBalance + pendingBalanceGwei` is `safeAdd` and reverts on
overflow, matching Solidity 0.8 checked addition at
`TopUpGateway.sol` lines 408--412. -/

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
    (batch : TopupBatch) (cfg : TopupConfig) (hBatch : well_formed_batch batch cfg) :
    (execute batch cfg).sum ≤ cfg.maxTopUpPerBlockGwei := by
  rw [execute_matches_pinned_transition]
  rw [← hBatch.2.2.2.2.2.2.2.2.2]
  exact aggregate_bounded_by_block_cap batch cfg hBatch

/-! ## Checked-word source interpreter

Independent of `evaluated_topup_limit` / `transition`.  Overflow of
`effective + pending` is `none`, not a total Nat sum. -/

def minWord (a b : Word) : Word := if a ≤ b then a else b

/-- Pinned `_evaluateTopUpLimit` (lines 396--415) after activation/exit/slash
filters.  The addition is checked; overflow is `none`. -/
def sourceEvaluateLimit (effective pending target minTopUp : Word) : Option Word := do
  let current ← safeAdd effective pending
  if target ≤ current then some 0
  else
    let gap ← safeSub target current
    if gap < minTopUp then some 0 else some gap

/-- Left-to-right budget consumption, matching `consumeBudget` on words. -/
def sourceConsume : Word → List Word → Option (List Word × Word)
  | remaining, [] => some ([], remaining)
  | remaining, cand :: rest => do
      let allocated := minWord cand remaining
      let next ← safeSub remaining allocated
      let (tail, leftover) ← sourceConsume next rest
      some (allocated :: tail, leftover)

/-- Candidates are independently capped by the evaluated validator limits. -/
def sourceCandidates : List Word → List Word → List Word → Word → Word →
    Option (List Word)
  | [], [], [], _, _ => some []
  | e :: es, p :: ps, r :: rs, target, minTopUp => do
      let limit ← sourceEvaluateLimit e p target minTopUp
      let rest ← sourceCandidates es ps rs target minTopUp
      some (minWord r limit :: rest)
  | _, _, _, _, _ => none

/-- Pinned-source batch: evaluate limits, take the share/value/block budget,
consume it left to right.  Empty or misaligned arrays revert. -/
def sourceRun (effective pending requested : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word) :
    Option (List Word × Word × Word) :=
  if effective.length == 0 then none
  else
    match sourceCandidates effective pending requested target minTopUp with
    | none => none
    | some candidates =>
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
theorem sourceEvaluateLimit_overflow
    (effective pending target minTopUp : Word)
    (h : MAX_UINT256 < effective.val + pending.val) :
    sourceEvaluateLimit effective pending target minTopUp = none := by
  unfold sourceEvaluateLimit
  simp [safeAdd, Bind.bind, h]

end LidoSRv3.Audit.Source.Topup2
