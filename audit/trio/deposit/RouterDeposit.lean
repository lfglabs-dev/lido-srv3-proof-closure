import audit.trio.deposit.Deposit

/-! Executable source-order model for the remainder of `StakingRouter.deposit`.
Pinned source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
`StakingRouter.sol:943-996`, `SRLib.sol:896-900`, and
`BeaconChainDepositor.sol:24,43-63`. -/
namespace audit.trio.deposit.RouterDeposit

open audit.trio.deposit

inductive Fault where
  | notAuthorized | moduleNotActive | unsupportedWithdrawalCredentials
  | invalidPublicKeysBatchLength | invalidSignaturesBatchLength
  | lidoCallFailed | beaconCallFailed | insufficientRouterBalance
  | balanceAssertion
  deriving DecidableEq, Repr

structure Context where
  caller : Address
  depositSecurityModule : Address
  moduleActive : Bool
  withdrawalCredentials : Option Word
  timestamp : Nat
  blockNumber : Nat
  deriving DecidableEq, Repr

structure Input where
  moduleId : Word
  actualDepositsCount : Nat
  maxEBType1 : Nat
  publicKeysBatchLength : Nat
  signaturesBatchLength : Nat
  deriving DecidableEq, Repr

structure DepositCall where
  index : Nat
  value : Nat
  withdrawalCredentials : Word
  deriving DecidableEq, Repr

structure World where
  routerBalance : Nat
  beaconBalance : Nat
  lastDepositAt : Nat
  lastDepositBlock : Nat
  depositedEvents : List (Word × Nat) := []
  calls : List DepositCall := []
  deriving DecidableEq, Repr

structure External where
  lidoAccepts : Bool
  beaconAccepts : Nat → Bool

structure Result where
  outcome : Except Fault Unit
  world : World
  deriving Repr

/-- `SRLib._updateModuleLastDepositState` followed by the router event.  Both
writes precede the zero-key early return. -/
def updateModuleLastDepositState (ctx : Context) (input : Input) (w : World) : World :=
  { w with
    lastDepositAt := ctx.timestamp % 2^64
    lastDepositBlock := ctx.blockNumber % 2^64
    depositedEvents := w.depositedEvents ++
      [(input.moduleId, input.actualDepositsCount * input.maxEBType1)] }

private def beaconLoop (external : External) (credentials : Word)
    (remaining index : Nat) (w : World) : Except Fault World :=
  match remaining with
  | 0 => .ok w
  | n + 1 =>
      if w.routerBalance < DEPOSIT_SIZE then .error .insufficientRouterBalance
      else if !external.beaconAccepts index then .error .beaconCallFailed
      else
        beaconLoop external credentials n (index + 1)
          { w with
            routerBalance := w.routerBalance - DEPOSIT_SIZE
            beaconBalance := w.beaconBalance + DEPOSIT_SIZE
            calls := w.calls ++ [⟨index, DEPOSIT_SIZE, credentials⟩] }

/-- Lines 943-996 in source order: router authorization, active status,
credential lookup, last-deposit update, conditional Lido pull, helper batch
validation, one 32-ether call per key, and the final balance assertion. -/
def executeRaw (external : External) (ctx : Context) (input : Input) (before : World) : Result :=
  if ctx.caller != ctx.depositSecurityModule then ⟨.error .notAuthorized, before⟩
  else if !ctx.moduleActive then ⟨.error .moduleNotActive, before⟩
  else match ctx.withdrawalCredentials with
  | none => ⟨.error .unsupportedWithdrawalCredentials, before⟩
  | some credentials =>
      let updated := updateModuleLastDepositState ctx input before
      if input.actualDepositsCount = 0 then ⟨.ok (), updated⟩
      else if !external.lidoAccepts then ⟨.error .lidoCallFailed, updated⟩
      else
        let pulled := { updated with routerBalance := updated.routerBalance +
          input.actualDepositsCount * input.maxEBType1 }
        if input.publicKeysBatchLength != 48 * input.actualDepositsCount then
          ⟨.error .invalidPublicKeysBatchLength, pulled⟩
        else if input.signaturesBatchLength != 96 * input.actualDepositsCount then
          ⟨.error .invalidSignaturesBatchLength, pulled⟩
        else match beaconLoop external credentials input.actualDepositsCount 0 pulled with
        | .error fault => ⟨.error fault, pulled⟩
        | .ok after =>
            if after.routerBalance = before.routerBalance then ⟨.ok (), after⟩
            else ⟨.error .balanceAssertion, after⟩

/-- Root EVM transaction semantics: every failure restores the complete input
world, including the pre-call state update and every prior value transfer. -/
def execute (external : External) (ctx : Context) (input : Input) (before : World) : Result :=
  let result := executeRaw external ctx input before
  match result.outcome with
  | .ok () => result
  | .error fault => ⟨.error fault, before⟩

theorem every_failure_rolls_back (external : External) (ctx : Context)
    (input : Input) (before after : World) (fault : Fault)
    (h : execute external ctx input before = ⟨.error fault, after⟩) : after = before := by
  simp only [execute] at h
  generalize rawEq : executeRaw external ctx input before = raw at h
  cases outcomeEq : raw.outcome with
  | ok value =>
      have impossible := congrArg Result.outcome h
      simp [outcomeEq] at impossible
  | error reason =>
      simp only [outcomeEq] at h
      exact (Result.mk.inj h).2.symm

#print axioms every_failure_rolls_back

end audit.trio.deposit.RouterDeposit
