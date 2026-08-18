import LidoSRv3.Audit.Source.AccountingCorrespondence
import Verity.Core

/-!
# P-ACCOUNT-1 faithful oracle-report transaction

This transaction models the accounting-relevant path of
`AccountingOracle._handleConsensusReportData` →
`StakingRouter.reportValidatorBalancesByStakingModule` →
`Accounting.handleOracleReport` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

The executable body:

* admits a report only when module ids match the registered order, lengths
  agree, and every balance is `≤ MAX_VALUE_GWEI`;
* writes each module balance through `writeMapUint`;
* accumulates the router total with checked `uint256` addition and the
  destination `uint64` bound, persisting it through `writeSlot`;
* records the report-before-reward step flags through `writeSlot`;
* rolls every intermediate write back through `Contract.run` on failure.

This is not an EVM theorem: slot numbers are a model-local projection of the
pinned accounting-relevant path. Sanity checks, CL state, vault transfers,
and extra-data processing stay outside this guarantee.
-/

namespace LidoSRv3.Audit.Verity.HandleOracleReportTx

open _root_.Verity
open _root_.Verity.Stdlib.Math
open LidoSRv3.Audit.SolidityAccounting

abbrev Word := Verity.Core.Uint256

def moduleBalancesSlot : Nat := 10
def totalBalanceSlot : Nat := 11
def accountingCalledSlot : Nat := 12
def rewardsReadSlot : Nat := 13
def rewardsMintedSlot : Nat := 14

/-- Independent transaction-plane accumulator.  This is deliberately not
`checkedTotal64` or `checkedTotal256`: the correspondence theorem below,
rather than a shared definition, is the boundary tying executable
accumulation to the pinned-source presentation. -/
def txCheckedTotal : List Nat → Option Word
  | [] => some 0
  | x :: xs => do
      let tail ← txCheckedTotal xs
      let next ← safeAdd tail (Verity.Core.Uint256.ofNat x)
      if next.val ≤ uint64Max then some next else none

def writeAll : List Nat → List Nat → ContractState → ContractState
  | [], _, state => state
  | _, [], state => state
  | id :: ids, bal :: bals, state =>
      writeAll ids bals
        (state.writeMapUint moduleBalancesSlot (Verity.Core.Uint256.ofNat id)
          (Verity.Core.Uint256.ofNat bal))

structure Result where
  balances : List Nat
  total : Word
  steps : List Step
  deriving DecidableEq, Repr

/-- Executable oracle-report transaction.  Validity and overflow guards run
in the body.  On overflow the prefix writes are performed and then reverted
by `Contract.run`.  `failAfterWrites` is a test hook placed after every
balance, total, and step-flag write. -/
def handleOracleReport (i : ReportInput) (sharesToMintAsFees : Nat)
    (failAfterWrites : Bool := false) : Contract Result := fun snapshot =>
  if idsAndBalancesValid i then
    match txCheckedTotal i.balancesGwei with
    | none =>
        .revert "OVERFLOW" (writeAll i.reportedModuleIds i.balancesGwei snapshot)
    | some total =>
        let dirty := writeAll i.reportedModuleIds i.balancesGwei snapshot
        let dirty := dirty.writeSlot totalBalanceSlot total
        let dirty := dirty.writeSlot accountingCalledSlot 1
        let dirty := dirty.writeSlot rewardsReadSlot 1
        let dirty := dirty.writeSlot rewardsMintedSlot (if 0 < sharesToMintAsFees then 1 else 0)
        if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
        else
          let accepted : AcceptedReport :=
            ⟨i.reportedModuleIds, i.balancesGwei, total.val⟩
          .success ⟨i.balancesGwei, total, successfulSteps accepted sharesToMintAsFees⟩
            dirty
  else .revert "INVALID_REPORT" snapshot

inductive Status where | committed | reverted
  deriving DecidableEq, Repr

/-- Outcome observables only.  The comparison never includes a residual
mutated field of the full post-state. -/
structure View where
  status : Status
  balances : List Nat
  total : Nat
  steps : List Step
  deriving DecidableEq, Repr

def storedSteps (state : ContractState) (balances : List Nat) : List Step :=
  let acc :=
    if state.readSlot accountingCalledSlot = 1 then [.accountingCalled] else []
  let rd :=
    if state.readSlot rewardsReadSlot = 1 then [.rewardsRead balances] else []
  let mint :=
    if state.readSlot rewardsMintedSlot = 1 then [.rewardsMinted] else []
  [.balancesWritten balances] ++ acc ++ rd ++ mint

def observe (i : ReportInput) : ContractResult Result → View
  | .success _ state =>
      ⟨.committed, i.balancesGwei, (state.readSlot totalBalanceSlot).val,
        storedSteps state i.balancesGwei⟩
  | .revert _ _ => ⟨.reverted, [], 0, []⟩

/-- Independently stated pinned-source view.  It uses `accept` /
`successfulSteps` and never calls `handleOracleReport`. -/
def sourceView (i : ReportInput) (sharesToMintAsFees : Nat) : View :=
  match accept i with
  | none => ⟨.reverted, [], 0, []⟩
  | some accepted =>
      ⟨.committed, accepted.balancesGwei, accepted.totalBalanceGwei,
        successfulSteps accepted sharesToMintAsFees⟩

private theorem balances_le_max (i : ReportInput)
    (h : idsAndBalancesValid i = true) :
    ∀ x ∈ i.balancesGwei, x ≤ maxValueGwei := by
  simp [idsAndBalancesValid, Bool.and_eq_true] at h
  exact h.2

private theorem maxValueGwei_lt_modulus : maxValueGwei < Verity.Core.Uint256.modulus := by
  decide

private theorem uint64Max_lt_modulus : uint64Max < Verity.Core.Uint256.modulus := by
  decide

private theorem uint64Max_le_maxUint : uint64Max ≤ Verity.Core.MAX_UINT256 := by
  decide

private theorem txCheckedTotal_refines_source (xs : List Nat) (n : Nat)
    (h : checkedTotal64 xs = some n) :
    txCheckedTotal xs = some (Verity.Core.Uint256.ofNat n) := by
  induction xs generalizing n with
  | nil =>
      simp [checkedTotal64, txCheckedTotal] at h ⊢
      exact h.symm ▸ rfl
  | cons x xs ih =>
      simp [checkedTotal64, Option.bind_eq_some_iff] at h
      rcases h with ⟨tail, hTail, hNext⟩
      rcases hNext with ⟨hFit, rfl⟩
      have h64mod := uint64Max_lt_modulus
      have hx : x < Verity.Core.Uint256.modulus :=
        Nat.lt_of_le_of_lt (Nat.le_add_right x tail)
          (Nat.lt_of_le_of_lt hFit h64mod)
      have ht : tail < Verity.Core.Uint256.modulus :=
        Nat.lt_of_le_of_lt (Nat.le_add_left tail x)
          (Nat.lt_of_le_of_lt hFit h64mod)
      have hsum : x + tail ≤ Verity.Core.MAX_UINT256 :=
        Nat.le_trans hFit uint64Max_le_maxUint
      have hsumlt : x + tail < Verity.Core.Uint256.modulus :=
        Nat.lt_of_le_of_lt hFit h64mod
      have hSafe : safeAdd (Verity.Core.Uint256.ofNat tail)
          (Verity.Core.Uint256.ofNat x) =
          some (Verity.Core.Uint256.ofNat (x + tail)) := by
        simp [safeAdd, Nat.mod_eq_of_lt hx, Nat.mod_eq_of_lt ht,
          Nat.not_lt.mpr hsum, Nat.add_comm, Verity.Core.Uint256.ofNat_add]
      have hVal : (Verity.Core.Uint256.ofNat x +
          Verity.Core.Uint256.ofNat tail).val = x + tail := by
        simp [HAdd.hAdd, Verity.Core.Uint256.add, Nat.mod_eq_of_lt hx,
          Nat.mod_eq_of_lt ht]
        exact Nat.mod_eq_of_lt hsumlt
      simp [txCheckedTotal, ih tail hTail, hSafe, hVal, hFit,
        Verity.Core.Uint256.ofNat_add]

private theorem txCheckedTotal_none_of_source (xs : List Nat)
    (hxs : ∀ x ∈ xs, x ≤ maxValueGwei)
    (h : checkedTotal64 xs = none) : txCheckedTotal xs = none := by
  induction xs with
  | nil => simp [checkedTotal64] at h
  | cons x xs ih =>
      have hx : x ≤ maxValueGwei := hxs x List.mem_cons_self
      have htail : ∀ y ∈ xs, y ≤ maxValueGwei := fun y hy =>
        hxs y (List.mem_cons_of_mem _ hy)
      cases hTail : checkedTotal64 xs with
      | none =>
          simp [checkedTotal64, hTail] at h
          simp [txCheckedTotal, ih htail hTail]
      | some tail =>
          simp [checkedTotal64, hTail] at h
          have href := txCheckedTotal_refines_source xs tail hTail
          have hxmod : x < Verity.Core.Uint256.modulus :=
            Nat.lt_of_le_of_lt hx maxValueGwei_lt_modulus
          have ht := checkedTotal64_le xs tail hTail
          have htmod : tail < Verity.Core.Uint256.modulus :=
            Nat.lt_of_le_of_lt ht uint64Max_lt_modulus
          have hsum : x + tail ≤ Verity.Core.MAX_UINT256 := by
            have hbound : x + tail ≤ maxValueGwei + uint64Max :=
              Nat.add_le_add hx ht
            have hfit : maxValueGwei + uint64Max ≤ Verity.Core.MAX_UINT256 := by
              decide
            exact Nat.le_trans hbound hfit
          have hSafe : safeAdd (Verity.Core.Uint256.ofNat tail)
              (Verity.Core.Uint256.ofNat x) =
              some (Verity.Core.Uint256.ofNat (x + tail)) := by
            simp [safeAdd, Nat.mod_eq_of_lt hxmod, Nat.mod_eq_of_lt htmod,
              Nat.not_lt.mpr hsum, Nat.add_comm, Verity.Core.Uint256.ofNat_add]
          have hsumlt : x + tail < Verity.Core.Uint256.modulus :=
            Nat.lt_of_le_of_lt hsum (by decide)
          have hVal : (Verity.Core.Uint256.ofNat x +
              Verity.Core.Uint256.ofNat tail).val = x + tail := by
            simp [HAdd.hAdd, Verity.Core.Uint256.add, Nat.mod_eq_of_lt hxmod,
              Nat.mod_eq_of_lt htmod]
            exact Nat.mod_eq_of_lt hsumlt
          simp [txCheckedTotal, href, hSafe, hVal, h]

private theorem readSlot_writeAll (ids bals : List Nat) (state : ContractState)
    (slot : Nat) :
    (writeAll ids bals state).readSlot slot = state.readSlot slot := by
  induction ids generalizing bals state with
  | nil => simp [writeAll]
  | cons id ids ih =>
      cases bals with
      | nil => simp [writeAll]
      | cons bal bals =>
          simp [writeAll]
          rw [ih]
          simp [ContractState.readSlot, ContractState.storage_writeMapUint]

/-- Composed faithful-plane theorem: the real storage transaction has the
same outcome observables as the independently stated pinned-source report. -/
theorem verity_tx_simulates_pinned_source
    (i : ReportInput) (sharesToMintAsFees : Nat) (state : ContractState) :
    observe i ((handleOracleReport i sharesToMintAsFees).run state) =
      sourceView i sharesToMintAsFees := by
  by_cases hValid : idsAndBalancesValid i = true
  · have hxs := balances_le_max i hValid
    unfold handleOracleReport Contract.run sourceView observe accept
    simp only [hValid, Bool.false_eq_true, ↓reduceIte]
    cases hSrc : checkedTotal64 i.balancesGwei with
    | none =>
        have hTx : txCheckedTotal i.balancesGwei = none :=
          txCheckedTotal_none_of_source i.balancesGwei hxs hSrc
        simp [hTx]
    | some n =>
        have hTx : txCheckedTotal i.balancesGwei =
            some (Verity.Core.Uint256.ofNat n) :=
          txCheckedTotal_refines_source i.balancesGwei n hSrc
        have hnle := checkedTotal64_le i.balancesGwei n hSrc
        have hnlt : n < Verity.Core.Uint256.modulus :=
          Nat.lt_of_le_of_lt hnle uint64Max_lt_modulus
        simp [hTx]
        by_cases hFees : 0 < sharesToMintAsFees
        · simp [hFees, storedSteps, successfulSteps, totalBalanceSlot,
            accountingCalledSlot, rewardsReadSlot, rewardsMintedSlot,
            ContractState.readSlot_writeSlot_same,
            ContractState.readSlot_writeSlot_other, Nat.mod_eq_of_lt hnlt]
        · simp [hFees, storedSteps, successfulSteps, totalBalanceSlot,
            accountingCalledSlot, rewardsReadSlot, rewardsMintedSlot,
            ContractState.readSlot_writeSlot_same,
            ContractState.readSlot_writeSlot_other, Nat.mod_eq_of_lt hnlt]
          decide
  · unfold handleOracleReport Contract.run sourceView observe accept
    simp [hValid]

/-- Any failure, including overflow after prefix writes and the injected
failure after every intermediate write, returns the exact pre-transaction
snapshot. -/
theorem revert_restores_snapshot
    (i : ReportInput) (sharesToMintAsFees : Nat) (inject : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (handleOracleReport i sharesToMintAsFees inject).run state =
      .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.HandleOracleReportTx
