import audit.trio.deposit.RouterDeposit
import LidoSRv3.Audit.Verity.TopupBeaconFundedTx

/-! Live-callee suffix of `StakingRouter.deposit`.
Pinned source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
`StakingRouter.sol:943-996`, `BeaconChainDepositor.sol:24,43-63`,
`Lido.sol:869-886`, `deposit_contract.sol:101-159`.

After the executed allocation/module prefix, the concrete RESERVE-1 Lido
withdrawal (nonzero seed = returned key count) and every beacon deposit run in
ONE `Live.World`: the beacon callee is the accepted PR273 source dispatcher
(`TopupBeaconCallee.dispatch sha256`) reached through actual CALLs, not a
Boolean acceptance oracle, and the router balance is only the live ledger
entry. There is no manual debit/credit, no supplied withdrawal receipt and no
auxiliary balance counter; the line 996 assertion reads the live ledger.
`LinksSource` is derived from the executed prefix, never from ALLOC alone. -/
namespace audit.trio.deposit.LiveBeacon

set_option autoImplicit false

open audit.trio.deposit
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TopupBeaconCallee
open LidoSRv3.Audit.Source.TopupBeaconBatch
open LidoSRv3.Audit.SolidityTopup (allocSum uint256Modulus)
open LidoSRv3.Audit.Source.DepositDataRootCorrespondence (SourceDepositDataRootInput)
open audit.trio.deposit.RouterDeposit (Context Inputs LinksSource rootInput batchLengthsOk checkedProduct)

/-- The router is `msg.sender` of the Lido withdrawal and the caller of every
beacon CALL; its own `msg.sender` is the deposit security module. -/
def routerContext (liveCtx : Live.Context) (ctx : Context) : Live.Context :=
  ⟨liveCtx.sender, Verity.Core.Address.ofNat ctx.caller.val⟩

def beaconAddress (ctx : Context) : Live.Address :=
  Verity.Core.Address.ofNat ctx.depositContract.val

/-- Per-key source input: the same 48/96-byte slices and root helper as the
data-only `RouterDeposit.makeCall`. -/
def keyInput (credentials : TrioAlloc1.Bytes) (prepared : PreparedDeposit) (index : Nat) :
    SourceDepositDataRootInput :=
  rootInput credentials ((prepared.moduleData.publicKeysBatch.drop (index * 48)).take 48)
    ((prepared.moduleData.signaturesBatch.drop (index * 96)).take 96)

def keyInputs (credentials : TrioAlloc1.Bytes) (prepared : PreparedDeposit) :
    Nat → Nat → List SourceDepositDataRootInput
  | 0, _ => []
  | remaining + 1, index =>
    keyInput credentials prepared index :: keyInputs credentials prepared remaining (index + 1)

/-- Every beacon CALL carries the pinned `DEPOSIT_SIZE`; the value list is not
a module output. -/
def amounts (count : Nat) : List Nat := List.replicate count DEPOSIT_SIZE

/-- `LIDO.withdrawDepositableEther(depositsValue, actualDepositsCount)` as the
delivered RESERVE-1 executor in its own call frame. -/
def withdrawal (callee : Live.External) (liveCtx : Live.Context)
    (prepared : PreparedDeposit) : Live.Exec Unit :=
  Live.run (Live.withdrawDepositableEther callee liveCtx
    (Live.word prepared.values.lidoPullWei) (Live.word prepared.values.actualKeys))

/-- Solidity 0.8 48/96-byte batch-length checks after the Lido pull. -/
def lengthGuard (prepared : PreparedDeposit) : Live.Exec Unit := fun w =>
  match batchLengthsOk prepared with
  | .ok () => Live.pureExec () w
  | .error .arithmeticOverflow => Live.fail (.reason "Panic(0x11)") w
  | .error .invalidPublicKeysBatchLength => Live.fail (.reason "InvalidPublicKeysBatchLength") w
  | .error _ => Live.fail (.reason "InvalidSignaturesBatchLength") w

/-- The accepted PR273 loop: each key is an actual CALL with the source payload
and value, dispatched to the concrete beacon callee in the same world. -/
def beaconLoop (routerCtx : Live.Context) (beacon : Live.Address)
    (credentials : TrioAlloc1.Bytes) (prepared : PreparedDeposit) : Live.Exec Unit :=
  TopupBeaconBatch.loop routerCtx beacon
    (keyInputs credentials prepared prepared.values.actualKeys 0)
    (amounts prepared.values.actualKeys)

/-- Line 996 assert against the live router balance. -/
def finish (router : Live.Address) (oldBalance : Nat) : Live.Exec Unit := fun w =>
  if w.balances router ≠ oldBalance then Live.fail (.reason "Panic(0x01)") w
  else Live.pureExec () w

/-- Source-ordered suffix after the prepared prefix: line 978 zero-key return,
Lido pull, batch-length checks, beacon loop, balance assertion. -/
def suffix (callee : Live.External) (ctx : Context) (liveCtx : Live.Context)
    (credentialsWord : Word) (prepared : PreparedDeposit) : Live.Exec Unit := fun before =>
  if prepared.values.actualKeys = 0 then Live.pureExec () before
  else
    Live.bindExec (withdrawal callee liveCtx prepared) (fun _ =>
      Live.bindExec (lengthGuard prepared) (fun _ =>
        Live.bindExec (beaconLoop (routerContext liveCtx ctx) (beaconAddress ctx)
            (encodeWord credentialsWord) prepared) (fun _ =>
          finish liveCtx.sender (before.balances liveCtx.sender)))) before

/-- Router module metadata written before the zero-key return. Physical router
storage for these fields remains an open obligation. -/
structure Metadata where
  lastDepositAt : Nat
  lastDepositBlock : Nat
  depositedEvents : List (Word × Nat) := []
  deriving DecidableEq, Repr

/-- The allocation transcript, the Lido/router/beacon ledger and the router's
module metadata are one root-transaction world. -/
structure World where
  allocationTranscript : Transcript
  live : Live.World
  metadata : Metadata

inductive Fault where
  | notAuthorized | moduleNotActive | unsupportedWithdrawalCredentials
  | depositPrefix (reason : DepositFailure)
  | live (reason : Live.Fault)
  deriving DecidableEq, Repr

structure Result where
  outcome : Except Fault Unit
  world : World
  attempts : List Live.Attempt := []

def recordDeposit (ctx : Context) (prepared : PreparedDeposit) (m : Metadata) : Metadata :=
  { m with
    lastDepositAt := ctx.timestamp % 2^64
    lastDepositBlock := ctx.blockNumber % 2^64
    depositedEvents := m.depositedEvents ++ [(prepared.moduleId, prepared.values.lidoPullWei)] }

def liftOutcome : Except Live.Fault Unit → Except Fault Unit
  | .ok () => .ok ()
  | .error reason => .error (.live reason)

/-- Authorization, allocation, returned keys, the live Lido withdrawal and every
beacon CALL as one transition; a late failure keeps the earlier live effects. -/
def executeRaw (callee : Live.External) (ctx : Context) (inputs : Inputs)
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
      let r := suffix callee ctx inputs.liveContext credentialsWord prepared before.live
      ⟨liftOutcome r.outcome,
        ⟨preparedResult.2, r.world, recordDeposit ctx prepared before.metadata⟩, r.attempts⟩

/-- Root rollback restores the allocation transcript, the whole live ledger
(storage, balances, logs) and the router metadata together. -/
def execute (callee : Live.External) (ctx : Context) (inputs : Inputs)
    (before : World) : Result :=
  let result := executeRaw callee ctx inputs before
  match result.outcome with
  | .ok () => result
  | .error fault => ⟨.error fault, before, result.attempts⟩

theorem failure_restores (callee : Live.External) (ctx : Context) (inputs : Inputs)
    (before after : World) (fault : Fault) (attempts : List Live.Attempt)
    (h : execute callee ctx inputs before = ⟨.error fault, after, attempts⟩) :
    after = before := by
  simp only [execute] at h
  generalize rawEq : executeRaw callee ctx inputs before = raw at h
  cases outcomeEq : raw.outcome with
  | ok value =>
      have impossible := congrArg Result.outcome h
      simp [outcomeEq] at impossible
  | «error» reason =>
      simp only [outcomeEq] at h
      exact (Result.mk.inj h).2.1.symm

#print axioms failure_restores

/-- Line 978: a zero-key module result returns before any Lido or beacon CALL. -/
theorem zero_keys_no_calls (callee : Live.External) (ctx : Context) (liveCtx : Live.Context)
    (credentialsWord : Word) (prepared : PreparedDeposit) (before : Live.World)
    (hz : prepared.values.actualKeys = 0) :
    suffix callee ctx liveCtx credentialsWord prepared before = ⟨.ok (), before, []⟩ := by
  simp [suffix, hz, Live.pureExec]

theorem depositSize_admitted :
    10^18 ≤ DEPOSIT_SIZE ∧ DEPOSIT_SIZE % 10^9 = 0 ∧ DEPOSIT_SIZE / 10^9 ≤ 2^64 - 1 ∧
      DEPOSIT_SIZE < uint256Modulus ∧ DEPOSIT_SIZE / 10^9 = 32 * 10^9 ∧ DEPOSIT_SIZE ≠ 0 := by
  decide

theorem keyInput_lengths (credentials : TrioAlloc1.Bytes) (prepared : PreparedDeposit) (index : Nat)
    (hc : credentials.length = 32)
    (hpk : prepared.moduleData.publicKeysBatch.length = prepared.values.actualKeys * pubkeyLength)
    (hsig : prepared.moduleData.signaturesBatch.length = 96 * prepared.values.actualKeys)
    (hi : index < prepared.values.actualKeys) :
    (keyInput credentials prepared index).publicKey.length = 48 ∧
      (keyInput credentials prepared index).withdrawalCredentials.length = 32 ∧
      (keyInput credentials prepared index).signature.length = 96 := by
  simp only [keyInput, rootInput, List.length_map, List.length_take, List.length_drop,
    hc, hpk, hsig]
  unfold pubkeyLength at hpk ⊢
  have hd : 1 ≤ prepared.values.actualKeys - index := by omega
  have hp48 : 48 ≤ prepared.values.actualKeys * 48 - index * 48 := by
    rw [← Nat.sub_mul]
    exact Nat.mul_le_mul_right 48 hd
  have hs96 : 96 ≤ 96 * prepared.values.actualKeys - index * 96 := by
    rw [Nat.mul_comm 96, ← Nat.sub_mul]
    exact Nat.mul_le_mul_right 96 hd
  exact ⟨Nat.min_eq_left hp48, trivial, Nat.min_eq_left hs96⟩

/-- The runtime-produced inputs satisfy PR273's independent per-call admission
predicate: source slice widths, the pinned 32-ether value in gwei, and the
callee's minimum/alignment/uint64 guards. No root is supplied. -/
theorem keyInputs_admissible (credentials : TrioAlloc1.Bytes) (prepared : PreparedDeposit)
    (hc : credentials.length = 32)
    (hpk : prepared.moduleData.publicKeysBatch.length = prepared.values.actualKeys * pubkeyLength)
    (hsig : prepared.moduleData.signaturesBatch.length = 96 * prepared.values.actualKeys) :
    ∀ remaining index, index + remaining ≤ prepared.values.actualKeys →
      List.Forall₂ Admissible (keyInputs credentials prepared remaining index) (amounts remaining) := by
  intro remaining
  induction remaining with
  | zero => intro index _; exact List.Forall₂.nil
  | succ n ih =>
    intro index h
    obtain ⟨h1, h2, h3⟩ := keyInput_lengths credentials prepared index hc hpk hsig (by omega)
    obtain ⟨hmin, halign, hmax, hfit, hgwei, _⟩ := depositSize_admitted
    rw [show amounts (n + 1) = DEPOSIT_SIZE :: amounts n from rfl, keyInputs]
    refine List.Forall₂.cons ⟨h1, h2, h3, ?_, hfit, fun _ => ⟨hmin, halign, hmax⟩⟩
      (ih (index + 1) (by omega))
    show 32 * 10^9 = DEPOSIT_SIZE / 10^9
    exact hgwei.symm

theorem allocSum_amounts (count : Nat) : allocSum (amounts count) = count * DEPOSIT_SIZE := by
  induction count with
  | zero => simp [amounts, allocSum]
  | succ n ih =>
    rw [show amounts (n + 1) = DEPOSIT_SIZE :: amounts n from rfl, allocSum, ih, Nat.succ_mul,
      Nat.add_comm]

theorem nonzeroCount_amounts (count : Nat) : nonzeroCount (amounts count) = count := by
  induction count with
  | zero => rfl
  | succ n ih =>
    have hne : DEPOSIT_SIZE ≠ 0 := depositSize_admitted.2.2.2.2.2
    rw [show amounts (n + 1) = DEPOSIT_SIZE :: amounts n from rfl]
    unfold nonzeroCount at ih ⊢
    simpa only [List.filter_cons, show decide (DEPOSIT_SIZE ≠ 0) = true from by simp [hne], if_true, List.length_cons] using congrArg Nat.succ ih

/-- The journal of a successful loop is exactly one accepted CALL per key, with
the router as caller, the pinned value and the serialized source payload. -/
theorem attempts_keyInputs (routerCtx : Live.Context) (beacon : Live.Address)
    (credentials : TrioAlloc1.Bytes) (prepared : PreparedDeposit) :
    ∀ remaining index,
      attempts routerCtx beacon (keyInputs credentials prepared remaining index) (amounts remaining) =
        (keyInputs credentials prepared remaining index).map fun input =>
          ⟨⟨routerCtx.self, beacon, Live.word DEPOSIT_SIZE, TopupBeaconEffects.sourcePayload input⟩,
            true, [], []⟩ := by
  intro remaining
  induction remaining with
  | zero => intro index; rfl
  | succ n ih =>
    intro index
    have hne : DEPOSIT_SIZE ≠ 0 := depositSize_admitted.2.2.2.2.2
    rw [show amounts (n + 1) = DEPOSIT_SIZE :: amounts n from rfl]
    unfold attempts at ih ⊢
    simp [keyInputs, hne, ih]

/-- The Lido accounting and seed writes are Lido slots; they cannot change the
beacon count slot. Derived for the nonzero deposit seed, not a callee frame. -/
theorem withdrawal_count (liveCtx : Live.Context) (amount seeds : Live.Word) (w : Live.World)
    (demand reference : Nat) (beacon : Live.Address) :
    (Pipeline.seeded liveCtx seeds (Pipeline.spent liveCtx amount w demand reference)).core.readContractSlot
      beacon.val countSlot = w.core.readContractSlot beacon.val countSlot := by
  have hspent : (Pipeline.spent liveCtx amount w demand reference).core.readContractSlot
      beacon.val countSlot = w.core.readContractSlot beacon.val countSlot := by
    have h0 := LidoSRv3.Audit.Verity.TopupBeaconFundedTx.accounting_count liveCtx amount w
      demand reference beacon
    simpa [Pipeline.seeded, show (Live.word 0).val = 0 from rfl] using h0
  unfold Pipeline.seeded
  split
  · exact hspent
  · unfold WithdrawalTail.seedWorld
    dsimp only
    rw [Pipeline.read_other_slot _ _ _ _ _ _ (by decide : TopupBeaconCallee.countSlot ≠ Live.seedSlot)]
    exact hspent

/-- Concrete successful Lido withdrawal with the deposit's nonzero seed. The
router credit, Lido debit, other-account preservation, code/count preservation
and the receiver callback are derived from the RESERVE-1 pipeline. -/
theorem withdrawal_success (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : Live.External)
    (liveCtx : Live.Context) (before : Live.World) (prepared : PreparedDeposit)
    (demand reference deadline time : Nat)
    (hfit : prepared.values.lidoPullWei < 2 ^ 256)
    (hnfit : prepared.values.actualKeys < 2 ^ 256)
    (hn : prepared.values.lidoPullWei ≠ 0)
    (b : Pipeline.Bound c liveCtx before)
    (hb : Queue.isBunkerModeActive c.contracts.queue before = false)
    (hp : (before.core.readContractSlot liveCtx.self.val Live.activeSlot).val ≠ 0)
    (hauth : liveCtx.sender = c.contracts.router)
    (hq : Queue.unfinalizedStETH k c.contracts.queue before = .ok demand)
    (hamount : prepared.values.lidoPullWei ≤
      (QueueCalls.allocationValues liveCtx before demand).deposits +
        (QueueCalls.allocationValues liveCtx before demand).unreserved)
    (hf : Consensus.compute c.frame
      (Pipeline.prepared liveCtx (Live.word prepared.values.lidoPullWei) before demand).core.blockTimestamp.val
      ((Pipeline.prepared liveCtx (Live.word prepared.values.lidoPullWei) before demand).core.readContractSlot
        c.consensus.val c.frame.frameSlot).val = .ok (reference, deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time)
    (hseed : ((Pipeline.spent liveCtx (Live.word prepared.values.lidoPullWei) before demand
      reference).core.readContractSlot liveCtx.self.val Live.seedSlot).val % Live.width +
        prepared.values.actualKeys < Verity.Core.UINT256_MODULUS)
    (hfunds : prepared.values.lidoPullWei ≤ before.balances liveCtx.self)
    (hlido : liveCtx.self = c.lido)
    (hrcode : (before.core.codeSize c.contracts.router.val).val ≠ 0)
    (hlr : liveCtx.self ≠ c.contracts.router) :
    ∃ withdrawn : Live.World,
      withdrawal (Pipeline.external k c staticOther other) liveCtx prepared before =
        ⟨.ok (), withdrawn, LidoSRv3.Audit.Verity.TopupBeaconFundedTx.withdrawalAttempts c liveCtx
          before (Live.word prepared.values.lidoPullWei) demand reference deadline time⟩ ∧
      TopupLiveWithdrawal.Balances before.balances withdrawn.balances liveCtx.self
        c.contracts.router prepared.values.lidoPullWei ∧
      withdrawn.core.codeSize = before.core.codeSize ∧
      (∀ beacon : Live.Address, withdrawn.core.readContractSlot beacon.val countSlot =
        before.core.readContractSlot beacon.val countSlot) ∧
      TopupLiveWithdrawal.Callback liveCtx.self c.contracts.router
        (Live.word prepared.values.lidoPullWei) withdrawn
        (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.withdrawalAttempts c liveCtx before
          (Live.word prepared.values.lidoPullWei) demand reference deadline time) := by
  have hvAmount : (Live.word prepared.values.lidoPullWei).val = prepared.values.lidoPullWei :=
    LidoSRv3.Audit.Verity.TopupTx.word_val hfit
  have hvSeeds : (Live.word prepared.values.actualKeys).val = prepared.values.actualKeys :=
    LidoSRv3.Audit.Verity.TopupTx.word_val hnfit
  have hnword : (Live.word prepared.values.lidoPullWei).val ≠ 0 := by rwa [hvAmount]
  have he := Pipeline.success k c staticOther other liveCtx before
    (Live.word prepared.values.lidoPullWei) (Live.word prepared.values.actualKeys)
    demand reference deadline time b hb hp hauth hnword hq (by rwa [hvAmount]) hf ht
    (by rwa [hvSeeds]) (by rwa [hvAmount]) hlido hrcode
  dsimp only at he
  have hswBal := Pipeline.final_balances liveCtx (Live.word prepared.values.lidoPullWei)
    (Live.word prepared.values.actualKeys) before demand reference
  have hswCode := Pipeline.final_code liveCtx (Live.word prepared.values.lidoPullWei)
    (Live.word prepared.values.actualKeys) before demand reference
  have hbal := TopupLiveWithdrawal.transfer_balances
    (Pipeline.seeded liveCtx (Live.word prepared.values.actualKeys)
      (Pipeline.spent liveCtx (Live.word prepared.values.lidoPullWei) before demand reference))
    liveCtx.self c.contracts.router (Live.word prepared.values.lidoPullWei).val hlr
    (by rw [hswBal, hvAmount]; exact hfunds)
  rw [hswBal, hvAmount] at hbal
  let sw := Pipeline.seeded liveCtx (Live.word prepared.values.actualKeys)
    (Pipeline.spent liveCtx (Live.word prepared.values.lidoPullWei) before demand reference)
  let withdrawn : Live.World := {Live.transfer sw liveCtx.self c.contracts.router prepared.values.lidoPullWei with
    logs := sw.logs ++ [⟨c.contracts.router, "DepositableEthReceived", [Live.word prepared.values.lidoPullWei]⟩]}
  refine ⟨withdrawn, ?_, hbal, hswCode, ?_, ⟨_, rfl⟩, ⟨_, rfl⟩⟩
  · unfold withdrawal
    rw [he]
    simp only [withdrawn,sw,hvAmount,LidoSRv3.Audit.Verity.TopupBeaconFundedTx.withdrawalAttempts]
  · intro beacon
    exact withdrawal_count liveCtx (Live.word prepared.values.lidoPullWei)
      (Live.word prepared.values.actualKeys) before demand reference beacon

/-- Composition of the executed parts of the suffix. Each part is an actual
execution result, not a supplied receipt. -/
theorem suffix_success (callee : Live.External) (ctx : Context) (liveCtx : Live.Context)
    (credentialsWord : Word) (prepared : PreparedDeposit)
    (before withdrawn after : Live.World) (trace loopAttempts : List Live.Attempt)
    (hKeys : prepared.values.actualKeys ≠ 0)
    (hw : withdrawal callee liveCtx prepared before = ⟨.ok (), withdrawn, trace⟩)
    (hlen : batchLengthsOk prepared = .ok ())
    (hloop : TopupBeaconBatch.loop (routerContext liveCtx ctx) (beaconAddress ctx)
      (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0)
      (amounts prepared.values.actualKeys) withdrawn = ⟨.ok (), after, loopAttempts⟩)
    (hassert : after.balances liveCtx.sender = before.balances liveCtx.sender) :
    suffix callee ctx liveCtx credentialsWord prepared before =
      ⟨.ok (), after, trace ++ loopAttempts⟩ := by
  simp only [suffix, hKeys, if_false, Live.bindExec, hw, lengthGuard, hlen, Live.pureExec,
    beaconLoop, hloop, finish, hassert, ne_eq, not_true_eq_false, List.append_nil,
    List.nil_append]

/-- Independent postcondition of a successful live deposit: derived source link,
metadata, pointwise ledger conservation across Lido, router and beacon with all
other accounts preserved, the beacon count, the chronological journal and the
per-deposit effect chain after the receiver callback. -/
structure Postcondition (ctx : Context) (inputs : Inputs) (c : Pipeline.Config)
    (before : World) (result : Result) (credentialsWord : Word) (prepared : PreparedDeposit)
    (transcript : Transcript) (trace : List Live.Attempt) : Prop where
  linked : LinksSource prepared
  transcript : result.world.allocationTranscript = transcript
  metadata : result.world.metadata = recordDeposit ctx prepared before.metadata
  router : result.world.live.balances c.contracts.router =
    before.live.balances c.contracts.router
  lido : result.world.live.balances inputs.liveContext.self + prepared.values.beaconTotalWei =
    before.live.balances inputs.liveContext.self
  beacon : result.world.live.balances (beaconAddress ctx) =
    before.live.balances (beaconAddress ctx) + prepared.values.beaconTotalWei
  others : ∀ account, account ≠ inputs.liveContext.self → account ≠ c.contracts.router →
    account ≠ beaconAddress ctx →
    result.world.live.balances account = before.live.balances account
  ledger : CallSpec.Balances before.live.balances result.world.live.balances
    inputs.liveContext.self (beaconAddress ctx) prepared.values.beaconTotalWei
  count : (result.world.live.core.readContractSlot (beaconAddress ctx).val countSlot).val =
    (before.live.core.readContractSlot (beaconAddress ctx).val countSlot).val +
      prepared.values.actualKeys
  journal : result.attempts = trace ++
    attempts (routerContext inputs.liveContext ctx) (beaconAddress ctx)
      (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0)
      (amounts prepared.values.actualKeys)
  effects : ∃ withdrawn : Live.World,
    TopupLiveWithdrawal.Callback inputs.liveContext.self c.contracts.router
      (Live.word prepared.values.lidoPullWei) withdrawn trace ∧
    Effects (routerContext inputs.liveContext ctx) (beaconAddress ctx)
      (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0)
      (amounts prepared.values.actualKeys) withdrawn result.world.live
  bounded : ∀ (accounts : List Live.Address) (limit : Nat),
    BalanceSpec.Bounded before.live.balances accounts limit →
    inputs.liveContext.self ∈ accounts → beaconAddress ctx ∈ accounts →
    BalanceSpec.Bounded result.world.live.balances accounts limit ∧
      BalanceSpec.mass result.world.live.balances accounts =
        BalanceSpec.mass before.live.balances accounts

/-- Pointwise conservation composes the actual withdrawal and beacon ledgers. -/
theorem compose_balances (before withdrawn after : Live.Address → Nat)
    (lido router beacon : Live.Address) (total : Nat)
    (hbalances : TopupLiveWithdrawal.Balances before withdrawn lido router total)
    (hbLoop : CallSpec.Balances withdrawn after router beacon total) :
    CallSpec.Balances before after lido beacon total := by
  intro account
  have hl : withdrawn account + (if account = lido then total else 0) =
      before account + (if account = router then total else 0) := by
    by_cases h1 : account = lido
    · subst account
      have hd := hbalances.lido_debit
      by_cases h2 : lido = router
      · subst router
        have hc := hbalances.router_credit
        simp only [if_true]
        omega
      · simp only [if_true, if_neg h2, Nat.add_zero]
        exact hd
    · by_cases h2 : account = router
      · subst account
        have hc := hbalances.router_credit
        simp only [if_neg h1, if_true, Nat.add_zero]
        exact hc
      · simp only [if_neg h1, if_neg h2, Nat.add_zero]
        exact hbalances.other_accounts account h1 h2
  have hb := hbLoop account
  change after account + (if account = lido then total else 0) =
    before account + (if account = beacon then total else 0)
  split_ifs at hl hb ⊢ <;> omega

set_option maxRecDepth 4096 in
/-- Concrete Lido withdrawal and every actual beacon callee execute
successfully from source/physical inputs, in one world. `LinksSource` is
derived from the executed prefix; the pinned `maxEBType1 = DEPOSIT_SIZE`
identity (`A-DEPOSIT-32-ETHER`) stays an explicit hypothesis, because the
line 996 assertion fails without it. Signature batch width and beacon
capacity/code/distinct-account facts are honest success-domain conditions;
the returned public-key width is derived from the executed prefix. -/
theorem positive_success (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : Live.External)
    (ctx : Context) (inputs : Inputs) (before : World)
    (credentialsWord : Word) (prepared : PreparedDeposit) (transcript : Transcript)
    (demand reference deadline time : Nat)
    (hAuth : ctx.caller = ctx.depositSecurityModule) (hActive : ctx.moduleActive = true)
    (hCred : ctx.withdrawalCredentials = some credentialsWord)
    (hPrep : prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
      inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
      inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript))
    (hKeys : prepared.values.actualKeys ≠ 0)
    (hEB : inputs.config.maxEBType1.val = DEPOSIT_SIZE)
    (hSig : prepared.moduleData.signaturesBatch.length = 96 * prepared.values.actualKeys)
    (b : Pipeline.Bound c inputs.liveContext before.live)
    (hb : Queue.isBunkerModeActive c.contracts.queue before.live = false)
    (hp : (before.live.core.readContractSlot inputs.liveContext.self.val Live.activeSlot).val ≠ 0)
    (hauth : inputs.liveContext.sender = c.contracts.router)
    (hq : Queue.unfinalizedStETH k c.contracts.queue before.live = .ok demand)
    (hamount : prepared.values.lidoPullWei ≤
      (QueueCalls.allocationValues inputs.liveContext before.live demand).deposits +
        (QueueCalls.allocationValues inputs.liveContext before.live demand).unreserved)
    (hf : Consensus.compute c.frame
      (Pipeline.prepared inputs.liveContext (Live.word prepared.values.lidoPullWei)
        before.live demand).core.blockTimestamp.val
      ((Pipeline.prepared inputs.liveContext (Live.word prepared.values.lidoPullWei)
        before.live demand).core.readContractSlot c.consensus.val c.frame.frameSlot).val =
          .ok (reference, deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time)
    (hseed : ((Pipeline.spent inputs.liveContext (Live.word prepared.values.lidoPullWei)
      before.live demand reference).core.readContractSlot inputs.liveContext.self.val
        Live.seedSlot).val % Live.width + prepared.values.actualKeys < Verity.Core.UINT256_MODULUS)
    (hfunds : prepared.values.lidoPullWei ≤ before.live.balances inputs.liveContext.self)
    (hlido : inputs.liveContext.self = c.lido)
    (hrcode : (before.live.core.codeSize c.contracts.router.val).val ≠ 0)
    (hbcode : (before.live.core.codeSize (beaconAddress ctx).val).val ≠ 0)
    (hlr : inputs.liveContext.self ≠ c.contracts.router)
    (hlb : inputs.liveContext.self ≠ beaconAddress ctx)
    (hrb : c.contracts.router ≠ beaconAddress ctx)
    (hcap : (before.live.core.readContractSlot (beaconAddress ctx).val countSlot).val +
      prepared.values.actualKeys ≤ maxCount) :
    let result := execute (Pipeline.external k c staticOther other) ctx inputs before
    result.outcome = .ok () ∧
      Postcondition ctx inputs c before result credentialsWord prepared transcript
        (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.withdrawalAttempts c inputs.liveContext
          before.live (Live.word prepared.values.lidoPullWei) demand reference deadline time) := by
  obtain ⟨hPer, hTotal, hPk, hPull, hPullFit, _, _, hPos⟩ :=
    prepareDepositABI_composes_beacon_values inputs.layout inputs.storage inputs.oracle
      inputs.config inputs.requested before.allocationTranscript transcript inputs.moduleId
      inputs.limits inputs.obtainDepositData DEPOSIT_SIZE prepared hPrep
  have hLink : LinksSource prepared := ⟨hPer, hTotal⟩
  have hPullDS : prepared.values.lidoPullWei = prepared.values.actualKeys * DEPOSIT_SIZE := by
    rw [hPull, hEB]
  have hnfit : prepared.values.actualKeys < 2 ^ 256 := by
    have hle : prepared.values.actualKeys ≤ prepared.values.actualKeys * inputs.config.maxEBType1.val :=
      Nat.le_mul_of_pos_right _ hPos
    rw [← hPull] at hle
    exact Nat.lt_of_le_of_lt hle hPullFit
  have hn : prepared.values.lidoPullWei ≠ 0 := by
    rw [hPullDS]
    exact Nat.mul_ne_zero hKeys depositSize_admitted.2.2.2.2.2
  obtain ⟨withdrawn, hwd, hbalances, hwCode, hwCount, hcallback⟩ :=
    withdrawal_success k c staticOther other inputs.liveContext before.live prepared
      demand reference deadline time hPullFit hnfit hn b hb hp hauth hq hamount hf ht hseed
      hfunds hlido hrcode hlr
  have hrouter : withdrawn.balances inputs.liveContext.sender =
      before.live.balances inputs.liveContext.sender +
        prepared.values.actualKeys * DEPOSIT_SIZE := by
    rw [hauth, hbalances.router_credit, hPullDS]
  have hadm := keyInputs_admissible (encodeWord credentialsWord) prepared
    (encodeWord_length _) hPk hSig prepared.values.actualKeys 0 (by simp)
  obtain ⟨after, hloop, hbLoop, hcount, _, effects⟩ := TopupBeaconBatch.loop_success
    (routerContext inputs.liveContext ctx) (beaconAddress ctx) (amounts prepared.values.actualKeys)
    (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0) withdrawn hadm
    (by show inputs.liveContext.sender ≠ beaconAddress ctx; rw [hauth]; exact hrb)
    (by rw [hwCode]; exact hbcode)
    (by
      rw [allocSum_amounts]
      show _ ≤ withdrawn.balances inputs.liveContext.sender
      rw [hrouter]
      exact Nat.le_add_left _ _)
    (by rw [hwCount (beaconAddress ctx), nonzeroCount_amounts]; exact hcap)
  rw [allocSum_amounts] at hbLoop
  rw [hwCount (beaconAddress ctx), nonzeroCount_amounts] at hcount
  have hsender : ∀ account, (account = (routerContext inputs.liveContext ctx).self) =
      (account = c.contracts.router) := by
    intro account
    show (account = inputs.liveContext.sender) = _
    rw [hauth]
  generalize hT : prepared.values.actualKeys * DEPOSIT_SIZE = total at hbLoop hrouter hPullDS
  have htotal : CallSpec.Balances before.live.balances after.balances inputs.liveContext.self
      (beaconAddress ctx) total := by
    apply compose_balances before.live.balances withdrawn.balances after.balances
      inputs.liveContext.self c.contracts.router (beaconAddress ctx) total
    · simpa only [hPullDS] using hbalances
    · simpa only [CallSpec.Balances, routerContext, hauth] using hbLoop
  have hrouterAfter : after.balances c.contracts.router = before.live.balances c.contracts.router := by
    have h := htotal c.contracts.router
    simpa [CallSpec.Balances, Ne.symm hlr, hrb] using h
  have hassert : after.balances inputs.liveContext.sender =
      before.live.balances inputs.liveContext.sender := by
    rw [hauth]; exact hrouterAfter
  have h48 : 48 * prepared.values.actualKeys < 2 ^ 256 := by
    have hle : 48 * prepared.values.actualKeys ≤ prepared.values.actualKeys * DEPOSIT_SIZE := by
      rw [Nat.mul_comm 48]
      exact Nat.mul_le_mul_left _ (by decide)
    rw [hT] at hle
    rw [hPullDS] at hPullFit
    exact Nat.lt_of_le_of_lt hle hPullFit
  have h96 : 96 * prepared.values.actualKeys < 2 ^ 256 := by
    have hle : 96 * prepared.values.actualKeys ≤ prepared.values.actualKeys * DEPOSIT_SIZE := by
      rw [Nat.mul_comm 96]
      exact Nat.mul_le_mul_left _ (by decide)
    rw [hT] at hle
    rw [hPullDS] at hPullFit
    exact Nat.lt_of_le_of_lt hle hPullFit
  have hPk' : prepared.moduleData.publicKeysBatch.length = 48 * prepared.values.actualKeys := by
    rw [hPk, pubkeyLength, Nat.mul_comm]
  have hlen : batchLengthsOk prepared = .ok () := by
    simp only [batchLengthsOk,checkedProduct,h48,h96,if_true,hPk',hSig,
      bne_self_eq_false,Bool.false_eq_true,if_false]
  have hsuffix := suffix_success (Pipeline.external k c staticOther other) ctx inputs.liveContext
    credentialsWord prepared before.live withdrawn after _ _ hKeys hwd hlen hloop hassert
  have hraw : executeRaw (Pipeline.external k c staticOther other) ctx inputs before =
      ⟨.ok (), ⟨transcript, after, recordDeposit ctx prepared before.metadata⟩,
        LidoSRv3.Audit.Verity.TopupBeaconFundedTx.withdrawalAttempts c inputs.liveContext
          before.live (Live.word prepared.values.lidoPullWei) demand reference deadline time ++
        attempts (routerContext inputs.liveContext ctx) (beaconAddress ctx)
          (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0)
          (amounts prepared.values.actualKeys)⟩ := by
    simp only [executeRaw, hAuth, bne_self_eq_false, Bool.false_eq_true, if_false, hActive,
      Bool.not_true, hCred, hPrep, hsuffix, liftOutcome]
  have hexe : execute (Pipeline.external k c staticOther other) ctx inputs before =
      ⟨.ok (), ⟨transcript, after, recordDeposit ctx prepared before.metadata⟩,
        LidoSRv3.Audit.Verity.TopupBeaconFundedTx.withdrawalAttempts c inputs.liveContext
          before.live (Live.word prepared.values.lidoPullWei) demand reference deadline time ++
        attempts (routerContext inputs.liveContext ctx) (beaconAddress ctx)
          (keyInputs (encodeWord credentialsWord) prepared prepared.values.actualKeys 0)
          (amounts prepared.values.actualKeys)⟩ := by
    simp [execute, hraw]
  dsimp only
  rw [hexe]
  refine ⟨rfl, ?_⟩
  refine ⟨hLink, rfl, rfl, hrouterAfter, ?_, ?_, ?_, (by simpa only [hTotal,hT] using htotal), hcount, rfl,
    ⟨withdrawn, hcallback, effects⟩, ?_⟩
  · have h := htotal inputs.liveContext.self
    simpa only [CallSpec.Balances,hTotal,hT,if_true,if_neg hlb,Nat.add_zero] using h
  · have h := htotal (beaconAddress ctx)
    simpa only [CallSpec.Balances,hTotal,hT,if_true,if_neg (Ne.symm hlb),Nat.add_zero] using h
  · intro account hl _ hr
    have h := htotal account
    simpa [CallSpec.Balances, hl, hr] using h
  · intro accounts limit hbounded hs hbe
    exact BalanceSpec.preserves _ _ _ _ _ _ _ hbounded hs hbe htotal

#print axioms positive_success
#print axioms keyInputs_admissible

end audit.trio.deposit.LiveBeacon
