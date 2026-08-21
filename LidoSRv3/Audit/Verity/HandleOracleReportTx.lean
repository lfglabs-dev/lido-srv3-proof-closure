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
* writes each module balance through `writeArray`;
* accumulates the router total with checked `uint256` addition and the
  destination `uint64` bound, persisting it through `writeSlot`;
* records the report-before-reward step flags through `writeSlot`, stamping
  each with a tick taken from a transaction-local step clock rather than a
  call-site constant, so the flags record execution order;
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

/-- Transaction-local step clock.  It is reset at the top of the modeled body
and read back by every subsequent step write, so the tick a step records is
the position at which that write actually ran. -/
def sequenceSlot : Nat := 15

/-- Tick proving that the accepted balance vector was actually persisted.
Unlike the historical hard-coded `.balancesWritten` prefix in `storedSteps`,
this slot is absent when the write-side step is skipped. -/
def balancesWrittenSlot : Nat := 16

/-- The tick the next step write will record: one past the current clock. -/
def nextTick (state : ContractState) : Word :=
  state.readSlot sequenceSlot + 1

/-- Advance the step clock and stamp `slot` with the new tick.

The tick is *read out of the state* rather than written as a call-site
constant, so moving this call earlier or later in the body changes the value
that lands in `slot`.  That is what makes the mint-after-read discipline below
a claim about execution order rather than about which numeral a particular
line of the program text happens to contain. -/
def stampStep (slot : Nat) (state : ContractState) : ContractState :=
  let tick := nextTick state
  (state.writeSlot sequenceSlot tick).writeSlot slot tick

@[simp] theorem readSlot_stampStep_self (slot : Nat) (state : ContractState) :
    (stampStep slot state).readSlot slot = nextTick state := by
  simp [stampStep, ContractState.readSlot_writeSlot_same]

@[simp] theorem readSlot_stampStep_clock (slot : Nat) (state : ContractState) :
    (stampStep slot state).readSlot sequenceSlot = nextTick state := by
  by_cases h : sequenceSlot = slot
  · rw [h]; simp [stampStep, ContractState.readSlot_writeSlot_same]
  · simp [stampStep, ContractState.readSlot_writeSlot_other _ h,
      ContractState.readSlot_writeSlot_same]

@[simp] theorem readSlot_stampStep_other {slot other : Nat} (state : ContractState)
    (h1 : other ≠ slot) (h2 : other ≠ sequenceSlot) :
    (stampStep slot state).readSlot other = state.readSlot other := by
  simp [stampStep, ContractState.readSlot_writeSlot_other _ h1,
    ContractState.readSlot_writeSlot_other _ h2]

/-! Slot disequalities, so proofs can keep the slot names folded (the tick
lemmas below are stated in terms of `sequenceSlot`, not its numeral). -/

theorem rewardsRead_ne_rewardsMinted : rewardsReadSlot ≠ rewardsMintedSlot := by decide

theorem rewardsRead_ne_sequence : rewardsReadSlot ≠ sequenceSlot := by decide

/-! The four ticks a committed body hands out.  `handleOracleReport` and every
mutant below share the same reset-then-stamp prefix, so these close the clock
arithmetic once instead of re-deriving it inside each proof. -/

@[simp] theorem nextTick_reset (s : ContractState) :
    nextTick (s.writeSlot sequenceSlot 0) = 1 := by
  simp [nextTick, ContractState.readSlot_writeSlot_same]

@[simp] theorem nextTick_stamp_one (a : Nat) (s : ContractState) :
    nextTick (stampStep a (s.writeSlot sequenceSlot 0)) = 2 := by
  simp only [nextTick, readSlot_stampStep_clock,
    ContractState.readSlot_writeSlot_same]
  decide

@[simp] theorem nextTick_stamp_two (a b : Nat) (s : ContractState) :
    nextTick (stampStep b (stampStep a (s.writeSlot sequenceSlot 0))) = 3 := by
  simp only [nextTick, readSlot_stampStep_clock,
    ContractState.readSlot_writeSlot_same]
  decide

@[simp] theorem nextTick_stamp_three (a b c : Nat) (s : ContractState) :
    nextTick
      (stampStep c (stampStep b (stampStep a (s.writeSlot sequenceSlot 0)))) = 4 := by
  simp only [nextTick, readSlot_stampStep_clock,
    ContractState.readSlot_writeSlot_same]
  decide

/-! Numeral normalization for the three tick values.  `Uint256`'s `add_comm` /
`add_assoc` simp lemmas reassociate the clock increments, so these close the
resulting `1 + 1` / `1 + 2` comparisons that `storedSteps` performs. -/

@[simp] theorem word_one_add_one : (1 : Word) + 1 = 2 := by decide

@[simp] theorem word_one_add_two : (1 : Word) + 2 = 3 := by decide

/-- Persist reported balances in router order as a `uint256[]` storage array.
This is the `reportValidatorBalancesByStakingModule` write of the modeled
path; ids are the registered router order already checked by
`idsAndBalancesValid`. -/
def persistBalances (bals : List Nat) (state : ContractState) : ContractState :=
  state.writeArray moduleBalancesSlot (bals.map Verity.Core.Uint256.ofNat)

def writeAll : List Nat → List Nat → ContractState → ContractState
  | _, bals, state => persistBalances bals state

structure Result where
  balances : List Nat
  total : Word
  steps : List Step
  deriving DecidableEq, Repr

/-- Independent tx-storage-flag reconstruction of the observable step trace.
Each flag holds the *tick* at which the transaction wrote it (`0` means never
written), not a bare boolean, so a write-order mutation on `rewardsReadSlot`
and `rewardsMintedSlot` is a fact recorded in storage and not merely an
artifact of a fixed list literal.  This function is the only source of
`Result.steps` and of the observed `View.steps` below: neither reads or calls
`AccountingCorrespondence`'s `successfulSteps`, so the two planes cannot share
a single miscoded `if`-tree. -/
def storedSteps (state : ContractState) (balances : List Nat) : List Step :=
  let written :=
    if state.readSlot balancesWrittenSlot = 1 then [.balancesWritten balances] else []
  let acc :=
    if state.readSlot accountingCalledSlot = 2 then [.accountingCalled] else []
  let rd :=
    if state.readSlot rewardsReadSlot = 3 then [.rewardsRead balances] else []
  let mint :=
    if state.readSlot rewardsMintedSlot = 4 then [.rewardsMinted] else []
  written ++ acc ++ rd ++ mint

/-- Executable oracle-report transaction.  Validity and overflow guards run
in the body.  On overflow the prefix writes are performed and then reverted
by `Contract.run`.  `failAfterWrites` is a test hook placed after every
balance, total, and step-flag write.  The step clock is reset and then each
step-flag write `stampStep`s its own slot, so the ticks (`1`, `2`, `3`) are
*computed from the order the writes execute in*, not chosen at the call site:
accounting is called, rewards are read from the just-written snapshot, and
only then are shares minted.  `Result.steps` is read back from those ticks
through `storedSteps`, never through
`AccountingCorrespondence.successfulSteps` — the tx plane owns its own
trace. -/
def handleOracleReport (i : ReportInput) (sharesToMintAsFees : Nat)
    (failAfterWrites : Bool := false) : Contract Result := fun snapshot =>
  if idsAndBalancesValid i then
    match checkedTotal256 i.balancesGwei with
    | none =>
        .revert "OVERFLOW" (writeAll i.reportedModuleIds i.balancesGwei snapshot)
    | some total =>
        let dirty := writeAll i.reportedModuleIds i.balancesGwei snapshot
        let dirty := dirty.writeSlot totalBalanceSlot total
        let dirty := dirty.writeSlot sequenceSlot 0
        let dirty := stampStep balancesWrittenSlot dirty
        let dirty := stampStep accountingCalledSlot dirty
        let dirty := stampStep rewardsReadSlot dirty
        let dirty :=
          if 0 < sharesToMintAsFees then stampStep rewardsMintedSlot dirty
          else dirty.writeSlot rewardsMintedSlot 0
        if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
        else .success ⟨i.balancesGwei, total, storedSteps dirty i.balancesGwei⟩ dirty
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

def observe (_i : ReportInput) : ContractResult Result → View
  | .success _ state =>
      let bals := (state.readArray moduleBalancesSlot).map (·.val)
      ⟨.committed, bals, (state.readSlot totalBalanceSlot).val,
        storedSteps state bals⟩
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

private theorem checkedTotal256_none_of_source (xs : List Nat)
    (hxs : ∀ x ∈ xs, x ≤ maxValueGwei)
    (h : checkedTotal64 xs = none) : checkedTotal256 xs = none := by
  induction xs with
  | nil => simp [checkedTotal64] at h
  | cons x xs ih =>
      have hx : x ≤ maxValueGwei := hxs x List.mem_cons_self
      have htail : ∀ y ∈ xs, y ≤ maxValueGwei := fun y hy =>
        hxs y (List.mem_cons_of_mem _ hy)
      cases hTail : checkedTotal64 xs with
      | none =>
          simp [checkedTotal64, hTail] at h
          simp [checkedTotal256, ih htail hTail]
      | some tail =>
          simp [checkedTotal64, hTail] at h
          have href := checkedTotal256_refines_source xs tail hTail
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
          simp [checkedTotal256, href, hSafe, hVal, h]

private theorem map_ofNat_val (xs : List Nat)
    (h : ∀ x ∈ xs, x ≤ maxValueGwei) :
    (xs.map Verity.Core.Uint256.ofNat).map (·.val) = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
      have hx : x < Verity.Core.Uint256.modulus :=
        Nat.lt_of_le_of_lt (h x List.mem_cons_self) maxValueGwei_lt_modulus
      have hxs : ∀ y ∈ xs, y ≤ maxValueGwei :=
        fun y hy => h y (List.mem_cons_of_mem _ hy)
      simp [Nat.mod_eq_of_lt hx, ih hxs]

private theorem persistBalances_read (bals : List Nat) (state : ContractState)
    (h : ∀ x ∈ bals, x ≤ maxValueGwei) :
    ((persistBalances bals state).readArray moduleBalancesSlot).map (·.val) =
      bals := by
  unfold persistBalances ContractState.readArray ContractState.writeArray
  simp [moduleBalancesSlot, map_ofNat_val bals h]

private theorem persistBalances_readSlot (bals : List Nat) (state : ContractState)
    (slot : Nat) :
    (persistBalances bals state).readSlot slot = state.readSlot slot := by
  simp [persistBalances, ContractState.readSlot, ContractState.storage_writeArray]

private theorem readSlot_writeAll (ids bals : List Nat) (state : ContractState)
    (slot : Nat) :
    (writeAll ids bals state).readSlot slot = state.readSlot slot := by
  simp [writeAll, persistBalances_readSlot]

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
        have hTx : checkedTotal256 i.balancesGwei = none :=
          checkedTotal256_none_of_source i.balancesGwei hxs hSrc
        simp [hTx]
    | some n =>
        have hTx : checkedTotal256 i.balancesGwei =
            some (Verity.Core.Uint256.ofNat n) :=
          checkedTotal256_refines_source i.balancesGwei n hSrc
        have hnle := checkedTotal64_le i.balancesGwei n hSrc
        have hnlt : n < Verity.Core.Uint256.modulus :=
          Nat.lt_of_le_of_lt hnle uint64Max_lt_modulus
        simp [hTx]
        by_cases hFees : 0 < sharesToMintAsFees
        · simp [hFees, storedSteps, successfulSteps, persistBalances, writeAll,
            stampStep, nextTick, sequenceSlot,
            totalBalanceSlot, balancesWrittenSlot, accountingCalledSlot,
            rewardsReadSlot, rewardsMintedSlot,
            ContractState.readArray, ContractState.writeArray,
            ContractState.readSlot_writeSlot_same,
            ContractState.readSlot_writeSlot_other, ContractState.storageArray_writeSlot,
            Nat.mod_eq_of_lt hnlt, map_ofNat_val i.balancesGwei hxs] <;> decide
        · simp [hFees, storedSteps, successfulSteps, persistBalances, writeAll,
            stampStep, nextTick, sequenceSlot,
            totalBalanceSlot, balancesWrittenSlot, accountingCalledSlot,
            rewardsReadSlot, rewardsMintedSlot,
            ContractState.readArray, ContractState.writeArray,
            ContractState.readSlot_writeSlot_same,
            ContractState.readSlot_writeSlot_other, ContractState.storageArray_writeSlot,
            Nat.mod_eq_of_lt hnlt, map_ofNat_val i.balancesGwei hxs]
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

/-! ## Mint-after-read discipline

`storedSteps` above only checks that each flag equals the exact tick its own
write site assigned; that presence check cannot see whether the writes
happened in the pinned order, because `ContractState` is a key-value store
and writes to distinct slots commute.  The independent order fact — that the
`rewardsReadSlot` tick precedes any nonzero `rewardsMintedSlot` tick — is
stated and proved separately below, over the raw tick values, so a
transaction that runs those two steps out of order is caught even though its
step flags remain present.

The ticks are `stampStep`'s reads of the transaction-local clock, not
per-call-site constants, so this is an ordering claim about execution and not
about which numeral appears on which line: moving a step write without
touching its slot or any literal already changes the tick it records. -/

/-- Order predicate over the two raw tick values a reordering mutant would
have to invert. -/
def mintAfterRead (rewardsReadTick rewardsMintedTick : Word) : Prop :=
  0 < rewardsMintedTick.val → rewardsReadTick.val < rewardsMintedTick.val

/-- Mint-after-read discipline, stated over an arbitrary transaction of the
same shape as `handleOracleReport` so the kill-line mutant below is checked
against the identical statement. -/
def mintAfterReadDisciplineOf (tx : ReportInput → Nat → Contract Result) : Prop :=
  ∀ (i : ReportInput) (sharesToMintAsFees : Nat) (state : ContractState),
    match (tx i sharesToMintAsFees).run state with
    | .success _ dirty =>
        mintAfterRead (dirty.readSlot rewardsReadSlot) (dirty.readSlot rewardsMintedSlot)
    | .revert _ _ => True

/-- Named mint-after-read discipline for the registered P-ACCOUNT-1 parent. -/
def mintAfterReadDiscipline : Prop :=
  mintAfterReadDisciplineOf (fun i sharesToMintAsFees => handleOracleReport i sharesToMintAsFees)

/-- The real transaction satisfies mint-after-read discipline: the balance
write is stamped at tick `1`, the read step runs at tick `3`, and any nonzero
mint step at tick `4`, for every
input, fee, and starting state.  Both ticks come from `stampStep`'s read of
the reset clock, so this is the order the two writes executed in. -/
theorem mintAfterReadDiscipline_holds : mintAfterReadDiscipline := by
  intro i sharesToMintAsFees state
  unfold handleOracleReport Contract.run mintAfterRead
  by_cases hValid : idsAndBalancesValid i = true
  · simp only [hValid, Bool.false_eq_true, ↓reduceIte]
    cases checkedTotal256 i.balancesGwei with
    | none => simp
    | some total =>
        by_cases hFees : 0 < sharesToMintAsFees <;>
          simp [hFees, stampStep, nextTick,
            ContractState.readSlot_writeSlot_same,
            ContractState.readSlot_writeSlot_other, balancesWrittenSlot, totalBalanceSlot,
            accountingCalledSlot, rewardsReadSlot, rewardsMintedSlot,
            sequenceSlot] <;>
          decide
  · simp [hValid]

/-- Reordering mutant: the mint step runs before the read step, the same fault
as a patch that calls `reportRewardsMinted` before re-reading the freshly
written balances.

This is a *pure call-site reordering*: the two `stampStep` calls are moved,
and each one still stamps its own slot with whatever tick the clock hands it.
No literal is edited and no slot binding is changed, so `storedSteps`'
presence check — and any other check that only asks "did this slot get
written?" — cannot tell this apart from the honest transaction.  It is caught
only because `stampStep` reads the tick out of the state instead of writing a
constant.  Kept beside the discipline it violates, not only in the mutants
test file, so the kill-line theorem can quantify over it directly. -/
def handleOracleReportMintBeforeRead (i : ReportInput)
    (sharesToMintAsFees : Nat) : Contract Result := fun snapshot =>
  if idsAndBalancesValid i then
    match checkedTotal256 i.balancesGwei with
    | none =>
        .revert "OVERFLOW" (writeAll i.reportedModuleIds i.balancesGwei snapshot)
    | some total =>
        let dirty := writeAll i.reportedModuleIds i.balancesGwei snapshot
        let dirty := dirty.writeSlot totalBalanceSlot total
        let dirty := dirty.writeSlot sequenceSlot 0
        let dirty := stampStep balancesWrittenSlot dirty
        let dirty := stampStep accountingCalledSlot dirty
        let dirty :=
          if 0 < sharesToMintAsFees then stampStep rewardsMintedSlot dirty
          else dirty.writeSlot rewardsMintedSlot 0
        let dirty := stampStep rewardsReadSlot dirty
        .success ⟨i.balancesGwei, total, storedSteps dirty i.balancesGwei⟩ dirty
  else .revert "INVALID_REPORT" snapshot

/-- Named kill-line statement for the registered P-ACCOUNT-1 parent: running
the mint step before the read step must falsify mint-after-read discipline. -/
def mintOrderKillLine : Prop :=
  ¬ mintAfterReadDisciplineOf handleOracleReportMintBeforeRead

theorem mintOrderKillLine_holds : mintOrderKillLine := by
  intro hDisc
  let witness : ReportInput := ⟨[1], [1], [1]⟩
  have hValid : idsAndBalancesValid witness = true := by native_decide
  have hTotal : checkedTotal256 witness.balancesGwei = some 1 := by native_decide
  have h := hDisc witness 1 defaultState
  simp [handleOracleReportMintBeforeRead, Contract.run, witness, hValid, hTotal,
    mintAfterRead, writeAll, persistBalances, stampStep, nextTick,
    ContractState.readSlot_writeSlot_same, ContractState.readSlot_writeSlot_other,
    totalBalanceSlot, accountingCalledSlot, rewardsReadSlot, rewardsMintedSlot,
    balancesWrittenSlot, sequenceSlot] at h
  exact absurd (h (by decide)) (by decide)

end LidoSRv3.Audit.Verity.HandleOracleReportTx
