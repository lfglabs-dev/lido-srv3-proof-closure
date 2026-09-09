import audit.trio.deposit.Deposit
import LidoSRv3.Audit.Source.TrioReserve1.Live

/-! Executable source-order model for the remainder of `StakingRouter.deposit`.
Pinned source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
`StakingRouter.sol:943-996`, `SRLib.sol:896-900`, and
`BeaconChainDepositor.sol:24,43-63`. -/
namespace audit.trio.deposit.RouterDeposit

open audit.trio.deposit
open LidoSRv3.Audit.Source.TrioAlloc1

inductive Fault where
  | notAuthorized | moduleNotActive | unsupportedWithdrawalCredentials
  | arithmeticOverflow | invalidPublicKeysBatchLength | invalidSignaturesBatchLength
  | beaconCallFailed | insufficientRouterBalance | balanceAssertion
  | liveWithdrawalMissing | liveWorldMismatch
  deriving DecidableEq, Repr

structure Context where
  caller : Address
  depositSecurityModule : Address
  moduleActive : Bool
  withdrawalCredentials : Option Word
  depositContract : Address
  timestamp : Nat
  blockNumber : Nat
  deriving DecidableEq, Repr

structure DepositCall where
  index : Nat
  value : Nat
  publicKey : LidoSRv3.Audit.Source.TrioAlloc1.Bytes
  withdrawalCredentials : LidoSRv3.Audit.Source.TrioAlloc1.Bytes
  signature : LidoSRv3.Audit.Source.TrioAlloc1.Bytes
  depositContract : Address
  depositDataRoot : List Nat
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
  beaconAccepts : DepositCall → Bool

/-- Evidence that the nonzero producer withdrawal ran in the RESERVE-1 live
ETH world and that its successful router callback supplied the balance used by
the deposit suffix. -/
structure LiveWithdrawalExecution (execution : DepositExecution) where
  external : LidoSRv3.Audit.Source.TrioReserve1.Live.External
  context : LidoSRv3.Audit.Source.TrioReserve1.Live.Context
  before : LidoSRv3.Audit.Source.TrioReserve1.Live.World
  after : LidoSRv3.Audit.Source.TrioReserve1.Live.World
  attempts : List LidoSRv3.Audit.Source.TrioReserve1.Live.Attempt
  executed : LidoSRv3.Audit.Source.TrioReserve1.Live.run
    (LidoSRv3.Audit.Source.TrioReserve1.Live.withdrawDepositableEther external context
      (LidoSRv3.Audit.Source.TrioReserve1.Live.word execution.values.lidoPullWei)
      (LidoSRv3.Audit.Source.TrioReserve1.Live.word execution.values.actualKeys)) before =
      ⟨.ok (), after, attempts⟩
  callbackCredit : after.balances context.sender =
    before.balances context.sender + execution.values.lidoPullWei
  callbackObserved : ∃ attempt ∈ attempts,
    attempt.accepted = true ∧
    attempt.request.target = context.sender ∧
    attempt.request.value = LidoSRv3.Audit.Source.TrioReserve1.Live.word execution.values.lidoPullWei ∧
    attempt.request.payload = LidoSRv3.Audit.Source.TrioReserve1.Live.encode 4 0x13ae8460

structure Result where
  outcome : Except Fault Unit
  world : World
  deriving Repr

/-- A value can enter the router suffix only together with evidence that the
ALLOC/module/Lido executor produced it successfully. -/
structure SuccessfulDepositExecution where
  layout : Layout
  storage : Storage
  oracle : StaticOracle
  config : Config
  requested : Word
  before : Transcript
  after : Transcript
  moduleId : Word
  limits : DepositLimits
  obtainDepositData : ObtainDepositData
  depositSize : Nat
  withdraw : audit.trio.deposit.WithdrawDepositableEther
  execution : DepositExecution
  executed : depositValuesABI layout storage oracle config requested before moduleId
    limits obtainDepositData depositSize withdraw = (.ok execution, after)
  liveWithdrawal : Option (LiveWithdrawalExecution execution)
  liveWithdrawalIffNonzero : liveWithdrawal.isSome = (execution.values.actualKeys != 0)

def checkedProduct (a b : Nat) : Except Fault Nat :=
  if a * b < 2 ^ 256 then .ok (a * b)
  else .error .arithmeticOverflow

def updateModuleLastDepositState (ctx : Context) (execution : DepositExecution)
    (w : World) : World :=
  { w with
    lastDepositAt := ctx.timestamp % 2^64
    lastDepositBlock := ctx.blockNumber % 2^64
    depositedEvents := w.depositedEvents ++
      [(execution.moduleId, execution.values.lidoPullWei)] }

private def rootInput (credentials publicKey signature : LidoSRv3.Audit.Source.TrioAlloc1.Bytes) :
    LidoSRv3.Audit.Source.DepositDataRootCorrespondence.SourceDepositDataRootInput where
  withdrawalCredentials := credentials.map Fin.val
  publicKey := publicKey.map Fin.val
  signature := signature.map Fin.val
  amountGwei := 32 * 10^9
  withdrawalCredentialsBounded := by
    intro byte h
    simp only [List.mem_map] at h
    obtain ⟨b, _, rfl⟩ := h
    exact b.isLt
  publicKeyBounded := by
    intro byte h
    simp only [List.mem_map] at h
    obtain ⟨b, _, rfl⟩ := h
    exact b.isLt
  signatureBounded := by
    intro byte h
    simp only [List.mem_map] at h
    obtain ⟨b, _, rfl⟩ := h
    exact b.isLt
  amountGweiBounded := by omega

private def makeCall (ctx : Context) (credentials : LidoSRv3.Audit.Source.TrioAlloc1.Bytes)
    (execution : DepositExecution) (index : Nat) : DepositCall :=
  let publicKey := (execution.moduleData.publicKeysBatch.drop (index * 48)).take 48
  let signature := (execution.moduleData.signaturesBatch.drop (index * 96)).take 96
  { index := index
    value := DEPOSIT_SIZE
    publicKey := publicKey
    withdrawalCredentials := credentials
    signature := signature
    depositContract := ctx.depositContract
    depositDataRoot := (LidoSRv3.Audit.Source.DepositDataRootCorrespondence.computeDepositDataRootWithAmount
      (rootInput credentials publicKey signature)).bytes }

private def beaconLoop (external : External) (ctx : Context)
    (credentials : LidoSRv3.Audit.Source.TrioAlloc1.Bytes)
    (execution : DepositExecution) (remaining index : Nat) (w : World) : Except Fault World :=
  match remaining with
  | 0 => .ok w
  | n + 1 =>
      let call := makeCall ctx credentials execution index
      if w.routerBalance < DEPOSIT_SIZE then .error .insufficientRouterBalance
      else if !external.beaconAccepts call then .error .beaconCallFailed
      else
        beaconLoop external ctx credentials execution n (index + 1)
          { w with
            routerBalance := w.routerBalance - DEPOSIT_SIZE
            beaconBalance := w.beaconBalance + DEPOSIT_SIZE
            calls := w.calls ++ [call] }

/-- The suffix consumes one successful `depositValuesABI` result. Module ID,
actual count, immutable max balance, both returned batches, and successful Lido
withdrawal are therefore not independently injectable at this boundary. -/
private def executeExecutionRaw (external : External) (ctx : Context)
    (linked : SuccessfulDepositExecution)
    (before : World) : Result :=
  let execution := linked.execution
  if ctx.caller != ctx.depositSecurityModule then ⟨.error .notAuthorized, before⟩
  else if !ctx.moduleActive then ⟨.error .moduleNotActive, before⟩
  else match ctx.withdrawalCredentials with
  | none => ⟨.error .unsupportedWithdrawalCredentials, before⟩
  | some credentialsWord =>
      let credentials := encodeWord credentialsWord
      let updated := updateModuleLastDepositState ctx execution before
      if execution.values.actualKeys = 0 then ⟨.ok (), updated⟩
      else
        match linked.liveWithdrawal with
        | none => ⟨.error .liveWithdrawalMissing, updated⟩
        | some live =>
        if before.routerBalance != live.before.balances live.context.sender then
          ⟨.error .liveWorldMismatch, updated⟩
        else
        let pulled := { updated with routerBalance := live.after.balances live.context.sender }
        match checkedProduct 48 execution.values.actualKeys with
        | .error fault => ⟨.error fault, pulled⟩
        | .ok expectedPublicKeys =>
          if execution.moduleData.publicKeysBatch.length != expectedPublicKeys then
            ⟨.error .invalidPublicKeysBatchLength, pulled⟩
          else match checkedProduct 96 execution.values.actualKeys with
          | .error fault => ⟨.error fault, pulled⟩
          | .ok expectedSignatures =>
            if execution.moduleData.signaturesBatch.length != expectedSignatures then
              ⟨.error .invalidSignaturesBatchLength, pulled⟩
            else match beaconLoop external ctx credentials execution
                execution.values.actualKeys 0 pulled with
            | .error fault => ⟨.error fault, pulled⟩
            | .ok after =>
                if after.routerBalance = before.routerBalance then ⟨.ok (), after⟩
                else ⟨.error .balanceAssertion, after⟩

/-- `executeRaw` is the direct composition boundary: its only deposit payload
is accompanied by a successful `depositValuesABI` premise. -/
def executeRaw (external : External) (ctx : Context) (linked : SuccessfulDepositExecution)
    (before : World) : Result :=
  executeExecutionRaw external ctx linked before

def execute (external : External) (ctx : Context) (linked : SuccessfulDepositExecution)
    (before : World) : Result :=
  let result := executeRaw external ctx linked before
  match result.outcome with
  | .ok () => result
  | .error fault => ⟨.error fault, before⟩

theorem every_failure_rolls_back (external : External) (ctx : Context)
    (linked : SuccessfulDepositExecution) (before after : World) (fault : Fault)
    (h : execute external ctx linked before = ⟨.error fault, after⟩) : after = before := by
  simp only [execute] at h
  generalize rawEq : executeRaw external ctx linked before = raw at h
  cases outcomeEq : raw.outcome with
  | ok value =>
      have impossible := congrArg Result.outcome h
      simp [outcomeEq] at impossible
  | error reason =>
      simp only [outcomeEq] at h
      exact (Result.mk.inj h).2.symm

#print axioms every_failure_rolls_back

end audit.trio.deposit.RouterDeposit
