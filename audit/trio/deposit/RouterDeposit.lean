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

def rootInput (credentials publicKey signature : LidoSRv3.Audit.Source.TrioAlloc1.Bytes) :
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

def makeCall (ctx : Context) (credentials : LidoSRv3.Audit.Source.TrioAlloc1.Bytes)
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

/-- Line 996 assert: a successful loop must restore the pre-call router balance. -/
def finishLoop (before : World) (loop : Result) : Result :=
  match loop.outcome with
  | .error _ => loop
  | .ok () =>
    if loop.world.router.routerBalance = before.router.routerBalance then loop
    else ⟨.error .balanceAssertion, loop.world, loop.lidoAttempts⟩

/-- Solidity 0.8 48/96-byte batch-length checks after the Lido pull. -/
def batchLengthsOk (prepared : PreparedDeposit) : Except Fault Unit :=
  match checkedProduct 48 prepared.values.actualKeys with
  | .error fault => .error fault
  | .ok expectedPublicKeys =>
    if prepared.moduleData.publicKeysBatch.length != expectedPublicKeys then
      .error .invalidPublicKeysBatchLength
    else match checkedProduct 96 prepared.values.actualKeys with
    | .error fault => .error fault
    | .ok expectedSignatures =>
      if prepared.moduleData.signaturesBatch.length != expectedSignatures then
        .error .invalidSignaturesBatchLength
      else .ok ()

def runWithdrawal (external : External) (inputs : Inputs) (prepared : PreparedDeposit)
    (live : Live.World) : Live.Result Unit :=
  Live.run (Live.withdrawDepositableEther external.lido inputs.liveContext
    (Live.word prepared.values.lidoPullWei) (Live.word prepared.values.actualKeys)) live

/-- Source-ordered suffix after a successful allocation/module prefix. -/
def executePrepared (external : External) (ctx : Context) (inputs : Inputs)
    (before : World) (credentialsWord : Word) (prepared : PreparedDeposit)
    (transcript : Transcript) : Result :=
  let updatedRouter := updateModuleLastDepositState ctx prepared before.router
  let updated : World :=
    { before with allocationTranscript := transcript, router := updatedRouter }
  if prepared.values.actualKeys = 0 then ⟨.ok (), updated, []⟩
  else if before.router.routerBalance != before.live.balances inputs.liveContext.sender then
    ⟨.error .liveWorldMismatch, updated, []⟩
  else
    let withdrawal := runWithdrawal external inputs prepared before.live
    match withdrawal.outcome with
    | .error reason =>
      ⟨.error (.lidoWithdrawal reason), updated, withdrawal.attempts⟩
    | .ok () =>
      let pulled : World :=
        { updated with
          live := withdrawal.world
          router := { updatedRouter with
            routerBalance := withdrawal.world.balances inputs.liveContext.sender } }
      match batchLengthsOk prepared with
      | .error fault => ⟨.error fault, pulled, withdrawal.attempts⟩
      | .ok () =>
        finishLoop before
          (beaconLoop external ctx inputs.liveContext (encodeWord credentialsWord)
            prepared prepared.values.actualKeys 0 pulled withdrawal.attempts)

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
    match preparedResult.1 with
    | .error reason =>
      ⟨.error (.depositPrefix reason),
        { before with allocationTranscript := preparedResult.2 }, []⟩
    | .ok prepared =>
      executePrepared external ctx inputs before credentialsWord prepared preparedResult.2

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

/-- Caller hypothesis: prepared source values charge the beacon loop
`actualKeys` keys at the pinned `DEPOSIT_SIZE` each. Data-only; no post-state.
Not a consequence of ALLOC: ALLOC does not constrain `beaconPerKeyWei`. -/
structure LinksSource (prepared : PreparedDeposit) : Prop where
  perKey : prepared.values.beaconPerKeyWei = DEPOSIT_SIZE
  total : prepared.values.beaconTotalWei = prepared.values.actualKeys * DEPOSIT_SIZE

theorem updateModuleLastDepositState_preserves_balances
    (ctx : Context) (prepared : PreparedDeposit) (w : RouterWorld) :
    (updateModuleLastDepositState ctx prepared w).routerBalance = w.routerBalance ∧
      (updateModuleLastDepositState ctx prepared w).beaconBalance = w.beaconBalance := by
  simp [updateModuleLastDepositState]

theorem finishLoop_ok
    (before after : World) (attempts : List Live.Attempt) (loop : Result)
    (h : finishLoop before loop = ⟨.ok (), after, attempts⟩) :
    loop = ⟨.ok (), after, attempts⟩ ∧
      after.router.routerBalance = before.router.routerBalance := by
  cases loop with
  | mk outcome world lidoAttempts =>
    cases outcome with
    | error _ =>
      simp [finishLoop] at h
    | ok _ =>
      simp [finishLoop] at h
      split_ifs at h with hBal
      · exact ⟨h, by
          have hw := (Result.mk.inj h).2.1
          simpa [hw] using hBal⟩
      · cases h

/-- Successful `executePrepared` restores the pre-call router balance (line 996,
or the zero-key early return) and credits the beacon with
`actualKeys * DEPOSIT_SIZE`. Failures are excluded by the `.ok` hypothesis. -/
theorem executePrepared_ok_conservation
    (external : External) (ctx : Context) (inputs : Inputs)
    (before after : World) (credentialsWord : Word) (prepared : PreparedDeposit)
    (transcript : Transcript) (attempts : List Live.Attempt)
    (h : executePrepared external ctx inputs before credentialsWord prepared transcript =
      ⟨.ok (), after, attempts⟩) :
    after.router.routerBalance = before.router.routerBalance ∧
      after.router.beaconBalance =
        before.router.beaconBalance + prepared.values.actualKeys * DEPOSIT_SIZE := by
  simp only [executePrepared] at h
  split_ifs at h with hZero hLive
  · have hw := (Result.mk.inj h).2.1
    subst after
    exact ⟨(updateModuleLastDepositState_preserves_balances ctx prepared before.router).1,
      by simp [updateModuleLastDepositState, hZero]⟩
  · cases h
  · split at h
    · cases h
    · split at h
      · cases h
      · obtain ⟨hLoopEq, hAssert⟩ := finishLoop_ok before after attempts _ h
        obtain ⟨hBeacon, _⟩ :=
          beaconLoop_ok_conservation external ctx inputs.liveContext
            (encodeWord credentialsWord) prepared prepared.values.actualKeys 0
            _ after _ attempts hLoopEq
        have hBal :=
          updateModuleLastDepositState_preserves_balances ctx prepared before.router
        exact ⟨hAssert, by simpa [hBal.2, updateModuleLastDepositState] using hBeacon⟩

private theorem execute_eq_raw_of_ok
    {external : External} {ctx : Context} {inputs : Inputs}
    {before after : World} {attempts : List Live.Attempt}
    (h : execute external ctx inputs before = ⟨.ok (), after, attempts⟩) :
    executeRaw external ctx inputs before = ⟨.ok (), after, attempts⟩ := by
  simp only [execute] at h
  cases hraw : executeRaw external ctx inputs before with
  | mk outcome world lidoAttempts =>
    cases outcome with
    | error _ => simp [hraw] at h
    | ok _ => simpa [hraw] using h

/-- Successful `executeRaw` is a successful prepared suffix of the allocation
prefix this transition actually ran. -/
theorem executeRaw_ok_conservation
    (external : External) (ctx : Context) (inputs : Inputs)
    (before after : World) (attempts : List Live.Attempt)
    (h : executeRaw external ctx inputs before = ⟨.ok (), after, attempts⟩) :
    after.router.routerBalance = before.router.routerBalance ∧
      ∃ credentialsWord prepared transcript,
        ctx.withdrawalCredentials = some credentialsWord ∧
        prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
          inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
          inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript) ∧
        executePrepared external ctx inputs before credentialsWord prepared transcript =
          ⟨.ok (), after, attempts⟩ ∧
        after.router.beaconBalance =
          before.router.beaconBalance + prepared.values.actualKeys * DEPOSIT_SIZE := by
  simp only [executeRaw] at h
  split_ifs at h
  · cases h
  · cases h
  · cases hCred : ctx.withdrawalCredentials with
    | none =>
      simp [hCred] at h
    | some credentialsWord =>
      simp [hCred] at h
      generalize hPrep :
        (prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
          inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
          inputs.obtainDepositData DEPOSIT_SIZE) = preparedResult
      simp [hPrep] at h
      match preparedResult with
      | (Except.error _, _) =>
        simp at h
      | (Except.ok prepared, transcript) =>
        simp at h
        have cons := executePrepared_ok_conservation external ctx inputs before after
          credentialsWord prepared transcript attempts h
        exact ⟨cons.1, credentialsWord, prepared, transcript, rfl, rfl, h, cons.2⟩

#print axioms executeRaw_ok_conservation

/-- Successful `execute` is the same conservation: the wrapper does not rewrite
a committed world. -/
theorem execute_ok_conservation
    (external : External) (ctx : Context) (inputs : Inputs)
    (before after : World) (attempts : List Live.Attempt)
    (h : execute external ctx inputs before = ⟨.ok (), after, attempts⟩) :
    after.router.routerBalance = before.router.routerBalance ∧
      ∃ credentialsWord prepared transcript,
        ctx.withdrawalCredentials = some credentialsWord ∧
        prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
          inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
          inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript) ∧
        after.router.beaconBalance =
          before.router.beaconBalance + prepared.values.actualKeys * DEPOSIT_SIZE := by
  obtain ⟨hBal, credentialsWord, prepared, transcript, hCred, hPrep, _, hBeacon⟩ :=
    executeRaw_ok_conservation external ctx inputs before after attempts (execute_eq_raw_of_ok h)
  exact ⟨hBal, credentialsWord, prepared, transcript, hCred, hPrep, hBeacon⟩

#print axioms execute_ok_conservation

/-- Successful `execute` under the caller `LinksSource` hypothesis: the beacon
credit is the prepared source `beaconTotalWei`. `LinksSource` is not derived
from ALLOC; the caller supplies it for whichever prefix `execute` ran. -/
theorem execute_ok_conservation_of_linkssource
    (external : External) (ctx : Context) (inputs : Inputs)
    (before after : World) (attempts : List Live.Attempt)
    (hLink : ∀ prepared,
      (prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
          inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
          inputs.obtainDepositData DEPOSIT_SIZE).1 = .ok prepared →
        LinksSource prepared)
    (h : execute external ctx inputs before = ⟨.ok (), after, attempts⟩) :
    after.router.routerBalance = before.router.routerBalance ∧
      ∃ prepared,
        (prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
            inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
            inputs.obtainDepositData DEPOSIT_SIZE).1 = .ok prepared ∧
          LinksSource prepared ∧
            after.router.beaconBalance =
              before.router.beaconBalance + prepared.values.beaconTotalWei := by
  obtain ⟨hBal, _, prepared, _, _, hPrep, hBeacon⟩ :=
    execute_ok_conservation external ctx inputs before after attempts h
  have hOk : (prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
      inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
      inputs.obtainDepositData DEPOSIT_SIZE).1 = .ok prepared :=
    congrArg Prod.fst hPrep
  exact ⟨hBal, prepared, hOk, hLink prepared hOk, (hLink prepared hOk).total ▸ hBeacon⟩

#print axioms execute_ok_conservation_of_linkssource

/-- Under the caller `LinksSource` hypothesis, the beacon credit is the
prepared source `beaconTotalWei`. `LinksSource` is not derived from ALLOC. -/
theorem executePrepared_ok_conservation_of_linkssource
    (external : External) (ctx : Context) (inputs : Inputs)
    (before after : World) (credentialsWord : Word) (prepared : PreparedDeposit)
    (transcript : Transcript) (attempts : List Live.Attempt)
    (hLink : LinksSource prepared)
    (h : executePrepared external ctx inputs before credentialsWord prepared transcript =
      ⟨.ok (), after, attempts⟩) :
    after.router.routerBalance = before.router.routerBalance ∧
      after.router.beaconBalance =
        before.router.beaconBalance + prepared.values.beaconTotalWei := by
  obtain ⟨hBal, hBeacon⟩ :=
    executePrepared_ok_conservation external ctx inputs before after credentialsWord
      prepared transcript attempts h
  exact ⟨hBal, hLink.total ▸ hBeacon⟩

#print axioms executePrepared_ok_conservation_of_linkssource

/-- `LinksSource` is derived from the executed callee: a successful
`prepareDepositABI` prefix at the pinned `DEPOSIT_SIZE` composes its beacon
values from that literal, so the caller hypothesis of PR #277 is discharged
by the prefix `executeRaw` actually ran. Still not derived from ALLOC alone:
the equation comes from `composeValues` after the module call and the
alignment/over-target/product guards. -/
theorem linksSource_of_prepareDepositABI
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (config : Config)
    (amount : Word) (before after : Transcript) (moduleId : Word) (limits : DepositLimits)
    (obtainDepositData : ObtainDepositData) (prepared : PreparedDeposit)
    (executed : prepareDepositABI layout storage oracle config amount before moduleId
      limits obtainDepositData DEPOSIT_SIZE = (.ok prepared, after)) :
    LinksSource prepared :=
  let facts := prepareDepositABI_composes_beacon_values layout storage oracle config amount
    before after moduleId limits obtainDepositData DEPOSIT_SIZE prepared executed
  ⟨facts.1, facts.2.1⟩

#print axioms linksSource_of_prepareDepositABI

/-- Successful `execute` without any caller hypothesis: the beacon credit is
the prepared source `beaconTotalWei`, with `LinksSource` derived from the
executed prefix rather than supplied. -/
theorem execute_ok_conservation_derived
    (external : External) (ctx : Context) (inputs : Inputs)
    (before after : World) (attempts : List Live.Attempt)
    (h : execute external ctx inputs before = ⟨.ok (), after, attempts⟩) :
    after.router.routerBalance = before.router.routerBalance ∧
      ∃ prepared transcript,
        prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
          inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
          inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript) ∧
        LinksSource prepared ∧
        after.router.beaconBalance =
          before.router.beaconBalance + prepared.values.beaconTotalWei := by
  obtain ⟨hBal, _, prepared, transcript, _, hPrep, hBeacon⟩ :=
    execute_ok_conservation external ctx inputs before after attempts h
  have hLink := linksSource_of_prepareDepositABI inputs.layout inputs.storage inputs.oracle
    inputs.config inputs.requested before.allocationTranscript transcript inputs.moduleId
    inputs.limits inputs.obtainDepositData prepared hPrep
  exact ⟨hBal, prepared, transcript, hPrep, hLink, hLink.total ▸ hBeacon⟩

#print axioms execute_ok_conservation_derived

end audit.trio.deposit.RouterDeposit
