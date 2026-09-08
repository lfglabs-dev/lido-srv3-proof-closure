import Std

/-!
Independent model of the P-ACCOUNT-1 router balance-write slice at pinned
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `SRLib.sol:853-870`, ordered validation and its three custom errors;
* `SRLib.sol:872-892`, per-module uint64 writes and checked uint64 total;
* `SRTypes.sol:157-171`, the packed accounting words.

It intentionally does not import the repository's earlier accounting model.
-/

namespace AccountAddress.PAccount1

def two64 : Nat := 2 ^ 64

def uint64Max : Nat := two64 - 1

def maxValueGwei : Nat := 1000000000000000000

/-- The source-visible failures, in the order in which the pinned code can
produce them. `ArithmeticOverflow` is Solidity's checked uint64 `+=` panic. -/
inductive Error where
  | arraysLengthMismatch
  | unexpectedModuleId (expected reported : Nat)
  | invalidAmountGwei (amount : Nat)
  | arithmeticOverflow
  deriving Repr, DecidableEq

/-- One physical `ModuleStateAccounting` word. The low uint64 is the validator
balance and the next uint64 is the exited-validator count. -/
structure ModuleAccounting where
  word : Nat
  deriving Repr, DecidableEq

/-- The router accounting struct occupies one slot; only its low uint64 is
written by `_reportValidatorBalancesByStakingModule`. -/
structure RouterAccounting where
  word : Nat
  deriving Repr, DecidableEq

structure State where
  modules : List ModuleAccounting
  router : RouterAccounting
  deriving Repr, DecidableEq

structure Input where
  registeredModuleIds : List Nat
  reportedModuleIds : List Nat
  balancesGwei : List Nat
  deriving Repr, DecidableEq

def low64 (word : Nat) : Nat := word % two64

def aboveLow64 (word : Nat) : Nat := word / two64

/-- Solidity assignment to a packed low uint64 field. -/
def writeLow64 (word value : Nat) : Nat := aboveLow64 word * two64 + value

def writeModuleBalance (m : ModuleAccounting) (value : Nat) : ModuleAccounting :=
  { word := writeLow64 m.word value }

def writeRouterBalance (r : RouterAccounting) (value : Nat) : RouterAccounting :=
  { word := writeLow64 r.word value }

/-- Ordered loop corresponding to `_validateReportValidatorBalancesByStakingModule`.
The first mismatching id or out-of-range balance determines the error. -/
def validateRows : List Nat -> List Nat -> Except Error Unit
  | [], [] => .ok ()
  | expected :: es, reported :: rs =>
      if expected != reported then .error (.unexpectedModuleId expected reported)
      else validateRows es rs
  | _, _ => .error .arraysLengthMismatch

def validateBalances : List Nat -> Except Error Unit
  | [] => .ok ()
  | amount :: rest =>
      if amount > maxValueGwei then .error (.invalidAmountGwei amount)
      else validateBalances rest

/-- The source checks each id and its balance in the same loop. -/
def validateInterleaved : List Nat -> List Nat -> List Nat -> Except Error Unit
  | [], [], [] => .ok ()
  | expected :: es, reported :: rs, amount :: bs =>
      if expected != reported then .error (.unexpectedModuleId expected reported)
      else if amount > maxValueGwei then .error (.invalidAmountGwei amount)
      else validateInterleaved es rs bs
  | _, _, _ => .error .arraysLengthMismatch

/-- Checked uint64 addition used by the total accumulator. -/
def checkedAdd64 (a b : Nat) : Except Error Nat :=
  if a + b < two64 then .ok (a + b) else .error .arithmeticOverflow

/-- Writes happen before the next checked addition, matching lines 883-888.
The caller supplies exactly one physical module word per registered id. -/
def writeRows : List ModuleAccounting -> List Nat -> Nat ->
    Except Error (List ModuleAccounting × Nat)
  | [], [], total => .ok ([], total)
  | m :: ms, amount :: bs, total => do
      let next <- checkedAdd64 total amount
      let (tail, finalTotal) <- writeRows ms bs next
      pure (writeModuleBalance m amount :: tail, finalTotal)
  | _, _, _ => .error .arraysLengthMismatch

inductive Outcome where
  | reverted (error : Error) (rollback : State)
  | committed (post : State)
  deriving Repr, DecidableEq

/-- Exact focused transaction: length guard, interleaved id/amount validation,
module writes with checked accumulation, then the router-total packed write.
Every error rolls back to the supplied snapshot. -/
def reportValidatorBalances (input : Input) (before : State) : Outcome :=
  if input.reportedModuleIds.length != input.registeredModuleIds.length ||
      input.balancesGwei.length != input.registeredModuleIds.length ||
      before.modules.length != input.registeredModuleIds.length then
    .reverted .arraysLengthMismatch before
  else
    match validateInterleaved input.registeredModuleIds input.reportedModuleIds
        input.balancesGwei with
    | .error e => .reverted e before
    | .ok _ =>
      match writeRows before.modules input.balancesGwei 0 with
      | .error e => .reverted e before
      | .ok (modules, total) =>
        .committed (State.mk modules (writeRouterBalance before.router total))

theorem low64_writeLow64 (word value : Nat) (h : value < two64) :
    low64 (writeLow64 word value) = value := by
  change value < 18446744073709551616 at h
  simp [low64, writeLow64, two64, Nat.mod_eq_of_lt h]

theorem aboveLow64_writeLow64 (word value : Nat) (h : value < two64) :
    aboveLow64 (writeLow64 word value) = aboveLow64 word := by
  change value < 18446744073709551616 at h
  simp only [aboveLow64, writeLow64, two64]
  omega

theorem checkedAdd64_ok_iff (a b : Nat) :
    (exists n, checkedAdd64 a b = .ok n) <-> a + b < two64 := by
  unfold checkedAdd64
  split <;> simp_all

theorem length_guard_is_first (input : Input) (before : State)
    (h : input.reportedModuleIds.length != input.registeredModuleIds.length ||
      input.balancesGwei.length != input.registeredModuleIds.length ||
      before.modules.length != input.registeredModuleIds.length) :
    reportValidatorBalances input before =
      .reverted .arraysLengthMismatch before := by
  simp [reportValidatorBalances, h]

theorem every_revert_restores_snapshot (input : Input) (before rollback : State)
    (e : Error) (h : reportValidatorBalances input before = .reverted e rollback) :
    rollback = before := by
  unfold reportValidatorBalances at h
  split at h
  · simp_all
  · split at h
    · simp_all
    · split at h <;> simp_all

end AccountAddress.PAccount1
