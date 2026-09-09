import audit.trio.deposit.Deposit
import LidoSRv3.Audit.Source.TrioReserve1.Live

/-! One executable source-order model of `StakingRouter.deposit`.
Pinned source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
`StakingRouter.sol:943-996`, `SRLib.sol:896-900`, and
`BeaconChainDepositor.sol:24,43-63`. -/
namespace audit.trio.deposit.RouterDeposit

open audit.trio.deposit
open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioReserve1

inductive Fault where
  | notAuthorized | moduleNotActive | unsupportedWithdrawalCredentials
  | depositPrefix (reason : DepositFailure)
  | lidoWithdrawal (reason : Live.Fault)
  | arithmeticOverflow | invalidPublicKeysBatchLength | invalidSignaturesBatchLength
  | beaconCallFailed | insufficientRouterBalance | balanceAssertion
  | liveWorldMismatch
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

structure RouterWorld where
  routerBalance : Nat
  beaconBalance : Nat
  lastDepositAt : Nat
  lastDepositBlock : Nat
  depositedEvents : List (Word × Nat) := []
  calls : List DepositCall := []
  deriving DecidableEq, Repr

/-- The allocation transcript, Lido storage/balances, and router suffix state
are one root-transaction world. -/
structure World where
  allocationTranscript : Transcript
  live : Live.World
  router : RouterWorld

structure External where
  lido : Live.External
  beaconAccepts : DepositCall → Bool

/-- All inputs needed to execute the source path. There is intentionally no
successful execution premise and no independently supplied withdrawal receipt. -/
structure Inputs where
  layout : Layout
  storage : Storage
  oracle : StaticOracle
  config : Config
  requested : Word
  moduleId : Word
  limits : DepositLimits
  obtainDepositData : ObtainDepositData
  liveContext : Live.Context

structure Result where
  outcome : Except Fault Unit
  world : World
  lidoAttempts : List Live.Attempt := []

def checkedProduct (a b : Nat) : Except Fault Nat :=
  if a * b < 2 ^ 256 then .ok (a * b)
  else .error .arithmeticOverflow

def updateModuleLastDepositState (ctx : Context) (prepared : PreparedDeposit)
    (w : RouterWorld) : RouterWorld :=
  { w with
    lastDepositAt := ctx.timestamp % 2^64
    lastDepositBlock := ctx.blockNumber % 2^64
    depositedEvents := w.depositedEvents ++
      [(prepared.moduleId, prepared.values.lidoPullWei)] }

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
    (prepared : PreparedDeposit) (index : Nat) : DepositCall :=
  let publicKey := (prepared.moduleData.publicKeysBatch.drop (index * 48)).take 48
  let signature := (prepared.moduleData.signaturesBatch.drop (index * 96)).take 96
  { index := index
    value := DEPOSIT_SIZE
    publicKey := publicKey
    withdrawalCredentials := credentials
    signature := signature
    depositContract := ctx.depositContract
    depositDataRoot := (LidoSRv3.Audit.Source.DepositDataRootCorrespondence.computeDepositDataRootWithAmount
      (rootInput credentials publicKey signature)).bytes }

private def debitLiveRouter (liveCtx : Live.Context) (depositContract : Address)
    (amount : Nat) (w : Live.World) : Live.World :=
  Live.transfer w liveCtx.sender (Verity.Core.Address.ofNat depositContract.val) amount

def beaconLoop (external : External) (ctx : Context) (liveCtx : Live.Context)
    (credentials : LidoSRv3.Audit.Source.TrioAlloc1.Bytes)
    (prepared : PreparedDeposit) (remaining index : Nat) (w : World)
    (attempts : List Live.Attempt) : Result :=
  match remaining with
  | 0 => ⟨.ok (), w, attempts⟩
  | n + 1 =>
      let call := makeCall ctx credentials prepared index
      if w.router.routerBalance < DEPOSIT_SIZE then
        ⟨.error .insufficientRouterBalance, w, attempts⟩
      else if !external.beaconAccepts call then ⟨.error .beaconCallFailed, w, attempts⟩
      else
        let router := { w.router with
          routerBalance := w.router.routerBalance - DEPOSIT_SIZE
          beaconBalance := w.router.beaconBalance + DEPOSIT_SIZE
          calls := w.router.calls ++ [call] }
        let live := debitLiveRouter liveCtx ctx.depositContract DEPOSIT_SIZE w.live
        beaconLoop external ctx liveCtx credentials prepared n (index + 1)
          { w with router := router, live := live } attempts

/-- Execute authorization, allocation, returned keys, the Lido withdrawal, and
all beacon calls as one transition over one root world. -/
def executeRaw (external : External) (ctx : Context) (inputs : Inputs)
    (before : World) : Result :=
  if ctx.caller != ctx.depositSecurityModule then ⟨.error .notAuthorized, before, []⟩
  else if !ctx.moduleActive then ⟨.error .moduleNotActive, before, []⟩
  else match ctx.withdrawalCredentials with
  | none => ⟨.error .unsupportedWithdrawalCredentials, before, []⟩
  | some credentialsWord =>
    let preparedResult := prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
      inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
      inputs.obtainDepositData DEPOSIT_SIZE
    let withTranscript := { before with allocationTranscript := preparedResult.2 }
    match preparedResult.1 with
    | .error reason => ⟨.error (.depositPrefix reason), withTranscript, []⟩
    | .ok prepared =>
      let updatedRouter := updateModuleLastDepositState ctx prepared before.router
      let updated := { withTranscript with router := updatedRouter }
      if prepared.values.actualKeys = 0 then ⟨.ok (), updated, []⟩
      else if before.router.routerBalance != before.live.balances inputs.liveContext.sender then
        ⟨.error .liveWorldMismatch, updated, []⟩
      else
        let withdrawal := Live.run
          (Live.withdrawDepositableEther external.lido inputs.liveContext
            (Live.word prepared.values.lidoPullWei)
            (Live.word prepared.values.actualKeys)) before.live
        match withdrawal.outcome with
        | .error reason =>
          ⟨.error (.lidoWithdrawal reason), updated, withdrawal.attempts⟩
        | .ok () =>
          let pulledRouter := { updatedRouter with
            routerBalance := withdrawal.world.balances inputs.liveContext.sender }
          let pulled := { updated with live := withdrawal.world, router := pulledRouter }
          match checkedProduct 48 prepared.values.actualKeys with
          | .error fault => ⟨.error fault, pulled, withdrawal.attempts⟩
          | .ok expectedPublicKeys =>
            if prepared.moduleData.publicKeysBatch.length != expectedPublicKeys then
              ⟨.error .invalidPublicKeysBatchLength, pulled, withdrawal.attempts⟩
            else match checkedProduct 96 prepared.values.actualKeys with
            | .error fault => ⟨.error fault, pulled, withdrawal.attempts⟩
            | .ok expectedSignatures =>
              if prepared.moduleData.signaturesBatch.length != expectedSignatures then
                ⟨.error .invalidSignaturesBatchLength, pulled, withdrawal.attempts⟩
              else
                let loop := beaconLoop external ctx inputs.liveContext (encodeWord credentialsWord)
                  prepared prepared.values.actualKeys 0 pulled withdrawal.attempts
                match loop.outcome with
                | .error fault => loop
                | .ok () =>
                  if loop.world.router.routerBalance = before.router.routerBalance then loop
                  else ⟨.error .balanceAssertion, loop.world, loop.lidoAttempts⟩

/-- Root rollback restores the allocation transcript, Lido world, and router
state together. Attempts remain observations of the failed transaction. -/
def execute (external : External) (ctx : Context) (inputs : Inputs)
    (before : World) : Result :=
  let result := executeRaw external ctx inputs before
  match result.outcome with
  | .ok () => result
  | .error fault => ⟨.error fault, before, result.lidoAttempts⟩

theorem every_failure_rolls_back (external : External) (ctx : Context)
    (inputs : Inputs) (before after : World) (fault : Fault) (attempts : List Live.Attempt)
    (h : execute external ctx inputs before = ⟨.error fault, after, attempts⟩) :
    after = before := by
  simp only [execute] at h
  generalize rawEq : executeRaw external ctx inputs before = raw at h
  cases outcomeEq : raw.outcome with
  | ok value =>
      have impossible := congrArg Result.outcome h
      simp [outcomeEq] at impossible
  | error reason =>
      simp only [outcomeEq] at h
      exact (Result.mk.inj h).2.1.symm

#print axioms every_failure_rolls_back

/-- Successful beacon-loop iterations move exactly `remaining * DEPOSIT_SIZE`
wei from the router to the beacon. Failures of the loop are excluded by the
`.ok` hypothesis, so this is the conservation content of the per-key suffix. -/
theorem beaconLoop_ok_conservation
    (external : External) (ctx : Context) (liveCtx : Live.Context)
    (credentials : LidoSRv3.Audit.Source.TrioAlloc1.Bytes)
    (prepared : PreparedDeposit) (remaining index : Nat)
    (w after : World) (attempts outAttempts : List Live.Attempt)
    (h : beaconLoop external ctx liveCtx credentials prepared remaining index w attempts =
      ⟨.ok (), after, outAttempts⟩) :
    after.router.beaconBalance = w.router.beaconBalance + remaining * DEPOSIT_SIZE ∧
      after.router.routerBalance + remaining * DEPOSIT_SIZE = w.router.routerBalance := by
  induction remaining generalizing index w after attempts outAttempts with
  | zero =>
    simp [beaconLoop] at h
    rcases h with ⟨rfl, rfl⟩
    simp
  | succ n ih =>
    simp [beaconLoop] at h
    split_ifs at h with hBal hAcc
    · cases h
    · cases h
    · obtain ⟨hBeacon, hRouter⟩ := ih (index + 1) _ after attempts outAttempts h
      simp at hBeacon hRouter
      constructor
      · rw [hBeacon, Nat.add_assoc, Nat.add_comm DEPOSIT_SIZE, Nat.succ_mul]
      · have hge : DEPOSIT_SIZE ≤ w.router.routerBalance := Nat.not_lt.mp hBal
        rw [Nat.succ_mul, ← Nat.add_assoc, hRouter, Nat.sub_add_cancel hge]

#print axioms beaconLoop_ok_conservation

end audit.trio.deposit.RouterDeposit
