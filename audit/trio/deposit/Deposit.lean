import LidoSRv3.Audit.Source.TrioComposition.ParentABI

/-!
Deposit suffix composed with the accepted ALLOC-1/ALLOC-2 public parent.

The allocation call is the existing `getDepositAllocationsABI`; this file does
not restate or strengthen its memory, compiler, lifecycle, or deployment claims.
The suffix models the pinned `StakingRouter.deposit` order at
lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436: select the requested
module allocation, obtain keys, record the actual deposit, pull from Lido, and
make one beacon call per returned key.  Failed transactions expose attempted
calls but restore the exact entry state.
-/
namespace audit.trio.deposit

open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

abbrev Word := TrioAlloc1.Word
abbrev Address := TrioAlloc1.Address

def thirtyTwoEtherWei : Nat := 32 * 10 ^ 18

inductive CallKind where
  | moduleData | lidoPull | beaconDeposit
  deriving DecidableEq, Repr

structure Attempt where
  kind : CallKind
  target : Address
  value : Nat
  deriving DecidableEq, Repr

structure State where
  routerBalance : Nat
  lidoDepositable : Nat
  lastDeposit : List Nat
  committedCalls : List Attempt
  deriving DecidableEq, Repr

structure Inputs where
  moduleIndex : Nat
  moduleAddress : Address
  lidoAddress : Address
  depositContract : Address
  actualKeys : Nat
  depositSize : Nat
  moduleCallOk : Bool
  lidoCallOk : Bool
  beaconCallOk : Nat → Bool

def canonicalDepositContract : Address :=
  ⟨0x00000000219ab540356cBB839Cbe05303d7705Fa, by native_decide⟩

/-- These are deployment/artifact assumptions, not consequences of ALLOC. -/
structure ArtifactAssumptions (inputs : Inputs) : Prop where
  A_DEPOSIT_CONTRACT : inputs.depositContract = canonicalDepositContract
  A_DEPOSIT_32_ETHER : inputs.depositSize = thirtyTwoEtherWei

inductive Error where
  | allocation (failure : TrioAlloc1.Failure)
  | moduleIndex
  | zeroDeposits
  | moduleCall
  | moduleReturnExceedsTarget
  | arithmetic
  | lidoCall
  | notEnoughEther
  | beaconCall (index : Nat)
  | balanceAssertion
  deriving DecidableEq, Repr

structure Outcome where
  result : Except Error Unit
  state : State
  attempts : List Attempt
  deriving Repr

def reverted (entry : State) (attempts : List Attempt) (error : Error) : Outcome :=
  ⟨.error error, entry, attempts⟩

def committed (state : State) (attempts : List Attempt) : Outcome :=
  ⟨.ok (), { state with committedCalls := state.committedCalls ++ attempts }, attempts⟩

/-- The non-tautological residual link between the selected router-order cell
and independently returned module keys.  It neither assumes the conclusion nor
identifies `maxEBType1` with the beacon deposit size. -/
def LinksSource (allocation : ParentOutput) (config : TrioAlloc1.Config)
    (inputs : Inputs) : Prop :=
  ∃ moduleAllocation : Word,
    allocation.allocated[inputs.moduleIndex]? = some moduleAllocation ∧
    inputs.actualKeys * config.maxEBType1.val ≤ moduleAllocation.val

def checkedMul (a b : Nat) : Except Error Nat :=
  if a * b < 2 ^ 256 then .ok (a * b) else .error .arithmetic

private def pushLoop (inputs : Inputs) (entry : State) (depositValue : Nat) :
    Nat → State → List Attempt → Outcome
  | 0, state, attempts =>
      if state.routerBalance = entry.routerBalance then committed state attempts
      else reverted entry attempts .balanceAssertion
  | n + 1, state, attempts =>
      let index := inputs.actualKeys - (n + 1)
      let attempt : Attempt := ⟨.beaconDeposit, inputs.depositContract, inputs.depositSize⟩
      let attempts' := attempts ++ [attempt]
      if !inputs.beaconCallOk index then reverted entry attempts' (.beaconCall index)
      else if inputs.depositSize ≤ state.routerBalance then
        pushLoop inputs entry depositValue n
          { state with routerBalance := state.routerBalance - inputs.depositSize } attempts'
      else reverted entry attempts' .balanceAssertion

/-- Executable source-order suffix.  Every failure is finalized against
`entry`, so failures after the last-deposit write, Lido pull, or an earlier
successful beacon call roll back all persistent state. -/
def executeSuffix (config : TrioAlloc1.Config) (allocation : ParentOutput)
    (inputs : Inputs) (entry : State) : Outcome :=
  match allocation.allocated[inputs.moduleIndex]? with
  | none => reverted entry [] .moduleIndex
  | some moduleAllocation =>
    if config.maxEBType1.val = 0 then reverted entry [] .arithmetic
    else
      let maxDepositsCount := moduleAllocation.val / config.maxEBType1.val
      if maxDepositsCount = 0 then reverted entry [] .zeroDeposits
      else
        let moduleAttempt : Attempt := ⟨.moduleData, inputs.moduleAddress, 0⟩
        if !inputs.moduleCallOk then reverted entry [moduleAttempt] .moduleCall
        else if maxDepositsCount < inputs.actualKeys then
          reverted entry [moduleAttempt] .moduleReturnExceedsTarget
        else
          match checkedMul inputs.actualKeys config.maxEBType1.val with
          | .error error => reverted entry [moduleAttempt] error
          | .ok depositValue =>
            let written := { entry with
              lastDeposit := (entry.lastDeposit.set inputs.moduleIndex depositValue) }
            if inputs.actualKeys = 0 then committed written [moduleAttempt]
            else
              let lidoAttempt : Attempt := ⟨.lidoPull, inputs.lidoAddress, 0⟩
              let attempts := [moduleAttempt, lidoAttempt]
              if !inputs.lidoCallOk then reverted entry attempts .lidoCall
              else if depositValue ≤ written.lidoDepositable then
                let pulled := { written with
                  routerBalance := written.routerBalance + depositValue
                  lidoDepositable := written.lidoDepositable - depositValue }
                pushLoop inputs entry depositValue inputs.actualKeys pulled attempts
              else reverted entry attempts .notEnoughEther

/-- Composition entry: execute the accepted canonical allocation ABI parent,
then the deposit suffix.  Allocation failures preserve its attempted static-call
transcript and never enter the stateful suffix. -/
def execute (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage)
    (oracle : TrioAlloc1.StaticOracle) (config : TrioAlloc1.Config) (amount : Word)
    (before : TrioAlloc1.Transcript) (inputs : Inputs) (entry : State) :
    Outcome × TrioAlloc1.Transcript :=
  match getDepositAllocationsABI layout storage oracle config amount false before with
  | (.error failure, after) => (reverted entry [] (.allocation failure), after)
  | (.ok allocation, after) => (executeSuffix config allocation inputs entry, after)

private theorem pushLoop_error_restores (inputs : Inputs) (entry state : State)
    (depositValue n : Nat) (attempts : List Attempt) (error : Error)
    (failed : (pushLoop inputs entry depositValue n state attempts).result = .error error) :
    (pushLoop inputs entry depositValue n state attempts).state = entry := by
  induction n generalizing state attempts with
  | zero =>
    by_cases balanced : state.routerBalance = entry.routerBalance
    · simp [pushLoop, balanced, committed] at failed
    · simp [pushLoop, balanced, reverted]
  | succ n ih =>
    by_cases rejected : (!inputs.beaconCallOk (inputs.actualKeys - (n + 1))) = true
    · simp [pushLoop, rejected, reverted]
    · by_cases funded : inputs.depositSize ≤ state.routerBalance
      · simp only [pushLoop, rejected, funded, ↓reduceIte] at failed ⊢
        exact ih _ _ failed
      · simp [pushLoop, rejected, funded, reverted]

theorem error_restores_entry (config : TrioAlloc1.Config) (allocation : ParentOutput)
    (inputs : Inputs) (entry : State) (error : Error)
    (failed : (executeSuffix config allocation inputs entry).result = .error error) :
    (executeSuffix config allocation inputs entry).state = entry := by
  unfold executeSuffix at failed ⊢
  split <;> simp_all [reverted, committed]
  split <;> simp_all [reverted, committed]
  split <;> simp_all [reverted, committed]
  split <;> simp_all [reverted, committed]
  split <;> simp_all [reverted, committed]
  split <;> simp_all [reverted, committed]
  split <;> simp_all [reverted, committed]
  split <;> simp_all [reverted, committed]
  split <;> simp_all [reverted, committed]
  exact pushLoop_error_restores _ _ _ _ _ _ _ failed

theorem allocation_failure_restores_entry (layout : TrioAlloc1.Layout)
    (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (config : TrioAlloc1.Config) (amount : Word) (before after : TrioAlloc1.Transcript)
    (inputs : Inputs) (entry : State) (failure : TrioAlloc1.Failure)
    (h : getDepositAllocationsABI layout storage oracle config amount false before =
      (.error failure, after)) :
    (execute layout storage oracle config amount before inputs entry).1 =
      reverted entry [] (.allocation failure) := by
  simp [execute, h]

end audit.trio.deposit
