import LidoSRv3.Audit.Source.Topup2Correspondence
import Verity.Core.Model.Denote

/-!
# P-TOPUP-2 faithful allocation/share transaction

This transaction models the guarantee-relevant slice of
`TopUpGateway.topUp` / `_evaluateTopUpLimit` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`
(lines 160--237 and 396--415), composed with the StakingRouter share
budget `min(moduleAllocation, maxTopUpPerBlock)` that
`StakingRouter.topUp` applies at lines 696--700.

Input arrays are denoted `uint256[]` memory.  Per-validator allocations
are persisted through `writeMapUint`; remaining block-cap and aggregate
used are persisted through `writeSlot`.  Checked `uint256` addition of
`effectiveBalance + pendingBalanceGwei` reverts on overflow.  A
standalone call-trace ledger is not this module.
-/

namespace LidoSRv3.Audit.Verity.Topup2DistributionTx

open _root_.Verity
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open LidoSRv3.Audit.Source.Topup2

abbrev Word := LidoSRv3.Audit.Source.Topup2.Word

def effectiveBase : Nat := 0x1000
def pendingBase : Nat := 0x2000
def requestedBase : Nat := 0x3000
def allocSlot : Nat := 30
def remainingSlot : Nat := 31
def allocatedSlot : Nat := 32
def maxValidatorsPerTopUp : Nat := 32

private def oracle : DenoteOracle where
  mappingSlot := fun _ _ => 0
  keccakMemorySlice := fun _ _ _ => 0

def arrayState (state : ContractState) (name : String) (base length : Nat) : DenoteState :=
  { world := state
    bindings := [(name ++ "_data_offset", base), (name ++ "_length", length)] }

def readWord (state : ContractState) (name : String) (base length index : Nat) : Option Word :=
  (evalExpr oracle [] (arrayState state name base length)
    (.memoryArrayElement name (.literal index))).map Verity.Core.Uint256.ofNat

def readArray (state : ContractState) (name : String) (base length : Nat) : Option (List Word) :=
  (List.range length).mapM (readWord state name base length)

def memoryFor (effective pending requested : List Word) : Nat → Word := fun offset =>
  if effectiveBase ≤ offset ∧ offset < effectiveBase + 32 * effective.length ∧
      (offset - effectiveBase) % 32 = 0 then
    effective.getD ((offset - effectiveBase) / 32) 0
  else if pendingBase ≤ offset ∧ offset < pendingBase + 32 * pending.length ∧
      (offset - pendingBase) % 32 = 0 then
    pending.getD ((offset - pendingBase) / 32) 0
  else if requestedBase ≤ offset ∧ offset < requestedBase + 32 * requested.length ∧
      (offset - requestedBase) % 32 = 0 then
    requested.getD ((offset - requestedBase) / 32) 0
  else 0

def stateFor (effective pending requested : List Word) (base : ContractState) : ContractState :=
  { base with memory := memoryFor effective pending requested }

/-- Persist per-validator allocations as a `uint256[]`-shaped storage array. -/
def persistAllocs (allocs : List Word) (state : ContractState) : ContractState :=
  state.writeArray allocSlot allocs

/-! ## Independent source-view interpreter

These equations intentionally copy the pinned source interpreter instead of
calling `Source.Topup2.sourceRun`, which remains the executor path used by
`allocate`.  The equality lemmas below are the explicit bridge. -/

def sourceConsumeIndependent : Word → List Word → Option (List Word × Word)
  | remaining, [] => some ([], remaining)
  | remaining, cand :: rest => do
      let allocated := minWord cand remaining
      let next ← Verity.Stdlib.Math.safeSub remaining allocated
      let (tail, leftover) ← sourceConsumeIndependent next rest
      some (allocated :: tail, leftover)

def sourceCandidatesIndependent : List Word → List Word → List Word → Word → Word →
    Option (List Word)
  | [], [], [], _, _ => some []
  | e :: es, p :: ps, r :: rs, target, minTopUp => do
      let limit ← evaluateTopUpLimit e p target minTopUp
      let rest ← sourceCandidatesIndependent es ps rs target minTopUp
      some (minWord r limit :: rest)
  | _, _, _, _, _ => none

def sourceRunIndependent (effective pending requested : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word) :
    Option (List Word × Word × Word) :=
  if effective.length == 0 then none
  else
    match sourceCandidatesIndependent effective pending requested target minTopUp with
    | none => none
    | some candidates =>
        let budget := minWord valueGwei (minWord moduleLimit remainingCap)
        match sourceConsumeIndependent budget candidates with
        | none => none
        | some (allocs, leftover) =>
            match Verity.Stdlib.Math.safeSub budget leftover with
            | none => none
            | some used =>
                match Verity.Stdlib.Math.safeSub remainingCap used with
                | none => none
                | some remaining => some (allocs, remaining, used)

theorem sourceConsumeIndependent_eq_sourceConsume :
    ∀ remaining candidates,
      sourceConsumeIndependent remaining candidates = sourceConsume remaining candidates
  | _, [] => rfl
  | remaining, cand :: rest => by
      simp [sourceConsumeIndependent, sourceConsume,
        sourceConsumeIndependent_eq_sourceConsume]

theorem sourceCandidatesIndependent_eq_sourceCandidates :
    ∀ effective pending requested target minTopUp,
      sourceCandidatesIndependent effective pending requested target minTopUp =
        sourceCandidates effective pending requested target minTopUp
  | [], [], [], _, _ => rfl
  | e :: es, p :: ps, r :: rs, target, minTopUp => by
      simp [sourceCandidatesIndependent, sourceCandidates,
        sourceCandidatesIndependent_eq_sourceCandidates]
  | [], [], _ :: _, _, _ => rfl
  | [], _ :: _, _, _, _ => rfl
  | _ :: _, [], _, _, _ => rfl
  | _ :: _, _ :: _, [], _, _ => rfl

theorem sourceRunIndependent_eq_sourceRun
    (effective pending requested : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word) :
    sourceRunIndependent effective pending requested target minTopUp remainingCap
        moduleLimit valueGwei =
      sourceRun effective pending requested target minTopUp remainingCap
        moduleLimit valueGwei := by
  unfold sourceRunIndependent sourceRun
  simp only [sourceCandidatesIndependent_eq_sourceCandidates,
    sourceConsumeIndependent_eq_sourceConsume]
  rfl

structure Result where
  allocations : List Word
  remaining : Word
  allocated : Word
  deriving DecidableEq, Repr

/-- Executable transaction.  Length / overflow / empty-batch failures revert
to the pre-call snapshot.  `failAfterWrites` is a test hook placed after the
allocation and budget writes; it proves rollback even after intermediate
effects. -/
def allocate (count : Nat) (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (failAfterWrites : Bool := false) : Contract Result := fun snapshot =>
  if count == 0 then .revert "WrongArrayLength" snapshot else
  if count > maxValidatorsPerTopUp then .revert "MaxValidatorsPerTopUpExceeded" snapshot else
  match readArray snapshot "effective" effectiveBase count,
      readArray snapshot "pending" pendingBase count,
      readArray snapshot "requested" requestedBase count with
  | some effective, some pending, some requested =>
      match sourceRun effective pending requested target minTopUp remainingCap
          moduleLimit valueGwei with
      | none => .revert "TOPUP_ARITHMETIC" snapshot
      | some (allocs, remaining, used) =>
          let dirty := persistAllocs allocs snapshot
          let dirty := (dirty.writeSlot remainingSlot remaining).writeSlot allocatedSlot used
          if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
          else .success ⟨allocs, remaining, used⟩ dirty
  | _, _, _ => .revert "MEMORY_ARRAY_DECODE" snapshot

inductive Status where | committed | reverted deriving DecidableEq, Repr

structure View where
  status : Status
  allocations : List Word
  remaining : Word
  allocated : Word
  deriving DecidableEq, Repr

/-- Outcome observables only.  A revert does not expose the mutated storage
fields (PR #91). -/
def observe (beforeAllocs : List Word) (beforeRemaining : Word) :
    ContractResult Result → View
  | .success _ state =>
      ⟨.committed, state.readArray allocSlot, state.readSlot remainingSlot,
        state.readSlot allocatedSlot⟩
  | .revert _ _ => ⟨.reverted, beforeAllocs, beforeRemaining, 0⟩

def sourceView (effective pending requested : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word) : View :=
  match sourceRunIndependent effective pending requested target minTopUp remainingCap
      moduleLimit valueGwei with
  | none => ⟨.reverted, List.replicate requested.length 0, remainingCap, 0⟩
  | some (allocs, remaining, used) => ⟨.committed, allocs, remaining, used⟩

/-- Composed faithful-plane theorem: the executable memory-array transaction
has the same allocation/share observables as the independently stated
pinned-source batch. -/
theorem verity_tx_simulates_pinned_source
    (effective pending requested : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (state : ContractState)
    (hEff : readArray state "effective" effectiveBase effective.length = some effective)
    (hPend : readArray state "pending" pendingBase pending.length = some pending)
    (hReq : readArray state "requested" requestedBase requested.length = some requested)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length)
    (hMax : requested.length ≤ maxValidatorsPerTopUp) :
    observe (List.replicate requested.length 0) remainingCap
        ((allocate requested.length target minTopUp remainingCap moduleLimit valueGwei).run
          state) =
      sourceView effective pending requested target minTopUp remainingCap
        moduleLimit valueGwei := by
  have hER : effective.length = requested.length := hLen.1.trans hLen.2
  have hPR : pending.length = requested.length := hLen.2
  have hEff' : readArray state "effective" effectiveBase requested.length = some effective := by
    simpa [hER] using hEff
  have hPend' : readArray state "pending" pendingBase requested.length = some pending := by
    simpa [hPR] using hPend
  have hNotOver : ¬ maxValidatorsPerTopUp < requested.length :=
    Nat.not_lt.mpr hMax
  by_cases hZero : requested.length = 0
  · have hEffZ : effective.length = 0 := hER.trans hZero
    unfold Contract.run allocate sourceView
    simp [hZero, hEffZ, observe, sourceRunIndependent]
  · have hZ : (requested.length == 0) = false := by simp [hZero]
    unfold Contract.run allocate sourceView
    simp only [hZ, hNotOver, Bool.false_eq_true, ↓reduceIte, hEff', hPend', hReq]
    rw [sourceRunIndependent_eq_sourceRun]
    cases hRun : sourceRun effective pending requested target minTopUp
        remainingCap moduleLimit valueGwei with
    | none =>
        simp [observe]
    | some trip =>
        rcases trip with ⟨allocs, remaining, used⟩
        simp [observe, persistAllocs, remainingSlot, allocatedSlot,
          ContractState.readArray, ContractState.writeArray,
          ContractState.readSlot_writeSlot_same,
          ContractState.readSlot_writeSlot_other,
          ContractState.storageArray_writeSlot]

/-- Any failure, including the injected failure after intermediate writes,
returns the exact pre-transaction snapshot. -/
theorem revert_restores_snapshot
    (count : Nat) (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (inject : Bool) (state rollback : ContractState) (reason : String)
    (h : (allocate count target minTopUp remainingCap moduleLimit valueGwei inject).run
      state = .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.Topup2DistributionTx
