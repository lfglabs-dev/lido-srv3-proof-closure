import LidoSRv3.Audit.Source.TopupRouterCredentials
import LidoSRv3.Audit.Verity.TopupBeaconFundedTx

/-! Pinned StakingRouter.sol:721–758, starting at the actual post-module world.
Inputs are typed memory/calldata values; the module and parent ABI are outside
this continuation. It executes every guard and reads credentials after the
withdrawal. No well-formedness, accepted Boolean or desired result is supplied
to execution. Semantic faults/events do not claim their complete EVM ABI. -/
namespace LidoSRv3.Audit.Source.TopupRouterContinuation
open TrioReserve1 Live TopupBeaconCallee TopupBeaconBatch
open LidoSRv3.Audit.Verity.TopupTx LidoSRv3.Audit.SolidityTopup
open DepositDataRootCorrespondence
open LidoSRv3.Audit.Verity

structure Input where
  moduleId : Word
  roundedTarget : Word
  pubkeys : List (List UInt8)
  limits : List Word
  allocations : List Word

def values (xs : List Word) : List Nat := xs.map (·.val)
def keys (xs : List (List UInt8)) : List (List Nat) := xs.map (List.map UInt8.toNat)

/-- The checked element is aligned before the limits read; addition is the
source uint256 unchecked update. An overlong array has no invented precheck. -/
def guardSum : List Nat → List Nat → Nat → Except Fault Nat
  | [], _, acc => .ok acc
  | a::as, limits, acc =>
    if a % 1000000000 ≠ 0 then .error (.reason "AmountNotAlignedToGwei")
    else match limits with
    | [] => .error (.reason "Panic(0x32)")
    | l::ls => if a > l then .error (.reason "AllocationExceedsLimit")
      else guardSum as ls ((acc+a) % uint256Modulus)

theorem guardSum_spec (amounts : List Nat) : ∀ limits acc total,
    guardSum amounts limits acc = .ok total →
    TopupWeiBounds.allocationGuards amounts limits ∧
      total = TopupWeiBounds.uncheckedSum acc amounts := by
  induction amounts with
  | nil => intro ls acc total h; simp [guardSum] at h; subst total; exact ⟨trivial,rfl⟩
  | cons a as ih =>
    intro ls acc total h
    by_cases ha : a % 1000000000 = 0
    · cases ls with
      | nil => simp [guardSum,ha] at h
      | cons l ls =>
        by_cases hl : a ≤ l
        · simp only [guardSum,ha,ne_eq,not_true_eq_false,if_false,Nat.not_lt.mpr hl] at h
          obtain ⟨hg,he⟩ := ih ls _ total h
          exact ⟨⟨ha,hl,hg⟩,he⟩
        · simp [guardSum,ha,Nat.lt_of_not_ge hl] at h
    · simp [guardSum,ha] at h

theorem guardSum_run (amounts : List Nat) : ∀ limits acc,
    TopupWeiBounds.allocationGuards amounts limits →
    guardSum amounts limits acc = .ok (TopupWeiBounds.uncheckedSum acc amounts) := by
  induction amounts with
  | nil => intros; rfl
  | cons a as ih =>
    intro ls acc h
    cases ls with
    | nil => contradiction
    | cons l ls =>
      obtain ⟨ha,hl,ht⟩ := h
      change a % 1000000000 = 0 at ha
      simpa [guardSum,ha,Nat.not_lt.mpr hl,TopupWeiBounds.uncheckedSum,
        TopupWeiBounds.wordModulus,uint256Modulus] using ih ls ((acc+a)%uint256Modulus) ht

/-- Allocation admission derives alignment and uint64-gwei width from actual
uint64 gateway limits; the minimum remains a genuine later helper condition. -/
theorem guards_fields (cfg : TopupWeiBounds.GatewayConfig)
    (amounts ns : List Nat) (hb : ∀ n ∈ ns, n ≤ cfg.target.val)
    (hg : TopupWeiBounds.allocationGuards amounts (TopupWeiBounds.weiLimits ns)) :
    ∀ a ∈ amounts, a % 1000000000 = 0 ∧ a / 1000000000 ≤ 2^64-1 := by
  induction amounts generalizing ns with
  | nil => simp
  | cons a as ih =>
    cases ns with
    | nil => contradiction
    | cons n ns =>
      obtain ⟨ha,hl,ht⟩ := hg
      have hn := hb n (by simp)
      have he := TopupWeiBounds.conversion_exact cfg n hn
      change a ≤ n * TopupWeiBounds.gwei % TopupWeiBounds.wordModulus at hl
      rw [he] at hl
      have hle : a ≤ n * 1000000000 := hl
      have hd : a / 1000000000 ≤ n := (Nat.div_le_iff_le_mul_add_pred (by decide)).mpr (by omega)
      have hnlt := cfg.target.isLt
      have ht' := ih ns (fun x hx => hb x (by simp [hx])) ht
      intro x hx
      rcases List.mem_cons.mp hx with rfl | hx
      · exact ⟨ha,by unfold TopupWeiBounds.uint64Modulus at hnlt; omega⟩
      · exact ht' x hx

def callAt (hash : TopupRouterCredentials.Keccak) (router : Address) (i : Input) (w : World) : TopupCall :=
  { roundedTarget := i.roundedTarget.val
    routerWithdrawalCredentials := TopupRouterCredentials.octets (TopupRouterCredentials.raw router w)
    withdrawalCredentialsType := TopupRouterCredentials.credentialType hash router i.moduleId w
    pubkeys := keys i.pubkeys
    keyIndices := []
    operatorIds := []
    topUpLimits := values i.limits
    moduleReturndata := values i.allocations }

/-- Typed octets/words allow construction even for malformed key widths. The
helper's executable guard, not a proof argument, decides their admission. -/
def inputAt (hash : TopupRouterCredentials.Keccak) (router : Address) (i : Input) (w : World)
    (pk : List UInt8) (amount : Word) : SourceDepositDataRootInput :=
  sourceDepositInput (callAt hash router i w) (pk.map UInt8.toNat) amount.val
    (TopupRouterCredentials.octets_length _) (TopupRouterCredentials.typeOf_bound _)
    (TopupRouterCredentials.octets_bounded _) (by
      intro b hb
      obtain ⟨v,_,rfl⟩ := List.mem_map.mp hb
      exact v.toNat_lt) amount.isLt

def inputsAt (hash : TopupRouterCredentials.Keccak) (router : Address) (i : Input) (w : World) :
    List SourceDepositDataRootInput :=
  (i.pubkeys.zip i.allocations).map fun p => inputAt hash router i w p.1 p.2

/-- Source helper length check is after the withdrawal and current WC read.
Empty pubkeys returns before length checking, exactly as source line73. -/
def helper (hash : TopupRouterCredentials.Keccak) (ctx : Context) (beacon : Address) (i : Input) : Exec Unit := fun w =>
  if i.pubkeys = [] then pureExec () w
  else if i.pubkeys.length ≠ i.allocations.length then fail (.reason "ArrayLengthMismatch") w
  else TopupBeaconBatch.loop ctx beacon (inputsAt hash ctx.self i w) (values i.allocations) w

def topUpEvent (router : Address) (i : Input) (total : Nat) : Log :=
  ⟨router,"StakingRouterETHTopUp",[i.moduleId,word total]⟩

def finish (router : Address) (i : Input) (total oldBalance : Nat) : Exec Unit := fun w =>
  if w.balances router ≠ oldBalance then fail (.reason "Panic(0x01)") w
  else ⟨.ok (),{w with logs := w.logs ++ [topUpEvent router i total]},[]⟩

def program (hash : TopupRouterCredentials.Keccak) (callee : External) (ctx : Context)
    (beacon : Address) (i : Input) : Exec Unit := fun before =>
  match guardSum (values i.allocations) (values i.limits) 0 with
  | .error e => fail e before
  | .ok total =>
    if total > i.roundedTarget.val then fail (.reason "ModuleReturnExceedTarget") before
    else if total = 0 then ⟨.ok (),{before with logs := before.logs ++ [topUpEvent ctx.sender i total]},[]⟩
    else bindExec (Live.run (TopupLiveWithdrawal.suffix callee ctx (word total)))
      (fun _ => bindExec (helper hash (TopupBeaconFundedTx.routerContext ctx) beacon i)
        (fun _ => finish ctx.sender i total (before.balances ctx.sender))) before

def execute (hash : TopupRouterCredentials.Keccak) (callee : External) (ctx : Context)
    (beacon : Address) (i : Input) : Exec Unit := Live.run (program hash callee ctx beacon i)


/-- The runtime-produced inputs satisfy the independent per-call admission
predicate under the genuine successful-helper domain; no root is supplied. -/
theorem inputs_admissible (hash : TopupRouterCredentials.Keccak) (router : Address)
    (i : Input) (w : World) (hlen : i.pubkeys.length = i.allocations.length)
    (hkeys : ∀ pk ∈ i.pubkeys, pk.length = 48)
    (hg : AmountsAdmitted (values i.allocations)) :
    List.Forall₂ Admissible (inputsAt hash router i w) (values i.allocations) := by
  have general : ∀ (pks : List (List UInt8)) (amounts : List Word),
      pks.length = amounts.length → (∀ pk ∈ pks, pk.length = 48) →
      AmountsAdmitted (values amounts) →
      List.Forall₂ Admissible
        ((pks.zip amounts).map fun p => inputAt hash router i w p.1 p.2) (values amounts) := by
    intro pks
    induction pks with
    | nil =>
      intro amounts hl _ _
      have hz : amounts = [] := List.length_eq_zero_iff.mp hl.symm
      subst amounts
      exact .nil
    | cons pk pks ih =>
      intro amounts hl hk hg
      cases amounts with
      | nil => simp at hl
      | cons a amounts =>
        apply List.Forall₂.cons
        · refine ⟨?_,?_,?_,rfl,a.isLt,?_⟩
          · simpa [inputAt,sourceDepositInput] using hk pk (by simp)
          · exact routerWithdrawalCredentials_length _ (TopupRouterCredentials.octets_length _)
          · simp [inputAt,sourceDepositInput,dummySignature]
          · exact hg a.val (by simp [values])
        · apply ih amounts (by simpa using hl)
            (fun key hkey => hk key (by simp [hkey]))
          exact fun x hx => hg x (by simp only [values,List.map_cons,List.mem_cons] at *; exact Or.inr hx)
  exact general _ _ hlen hkeys hg

/-- Actual checked-loop success supplies every arithmetic premise subsequently
used by the funded consumer. The checked result is not a callee/final outcome. -/
theorem checked_fields (cfg : TopupWeiBounds.GatewayConfig)
    (validators : List TopupWeiBounds.ValidatorInput) (ns : List Nat) (i : Input) (total : Nat)
    (hc : validators.length ≤ cfg.maxValidators.val)
    (hl : TopupWeiBounds.limits cfg validators = some ns)
    (hlimits : values i.limits = TopupWeiBounds.weiLimits ns)
    (hcheck : guardSum (values i.allocations) (values i.limits) 0 = .ok total)
    (hmin : ∀ a ∈ values i.allocations, a ≠ 0 → 10^18 ≤ a) :
    total = allocSum (values i.allocations) ∧ total < uint256Modulus ∧
      AmountsAdmitted (values i.allocations) := by
  obtain ⟨hg,he⟩ := guardSum_spec _ _ _ _ hcheck
  rw [hlimits] at hg
  obtain ⟨hfit,_⟩ := TopupFundedSource.gateway_sum_exact cfg validators ns (values i.allocations) hc hl hg
  have hsum := TopupWeiBounds.router_unchecked_sum_exact cfg validators ns (values i.allocations) hc hl hg
  have heq : total = allocSum (values i.allocations) := by
    rw [he,hsum,← TopupFundedSource.allocSum_eq_sum]
  obtain ⟨_,hb⟩ := TopupWeiBounds.limits_bounds cfg validators ns hl
  have hf := guards_fields cfg (values i.allocations) ns hb hg
  exact ⟨heq,heq.symm ▸ hfit,fun a ha hn => ⟨hmin a ha hn,(hf a ha).1,(hf a ha).2⟩⟩

theorem zero_event (hash : TopupRouterCredentials.Keccak) (callee : External)
    (ctx : Context) (beacon : Address) (i : Input) (before : World)
    (hz : guardSum (values i.allocations) (values i.limits) 0 = .ok 0) :
    execute hash callee ctx beacon i before =
      ⟨.ok (),{before with logs := before.logs ++ [topUpEvent ctx.sender i 0]},[]⟩ := by
  simp [execute,program,hz,Live.run]

theorem failure_restores (hash : TopupRouterCredentials.Keccak) (callee : External)
    (ctx : Context) (beacon : Address) (i : Input) (before : World) (e : Fault)
    (h : (execute hash callee ctx beacon i before).outcome = .error e) :
    (execute hash callee ctx beacon i before).world = before := by
  unfold execute Live.run at *
  dsimp only at *
  split <;> simp_all

/-- Independent postcondition: pointwise ledger conservation plus chronological
callback/deposit effects and one final event. Execution success is a separate
conclusion. The deposit effects end before the router's final event. -/
def Postcondition (hash : TopupRouterCredentials.Keccak) (ctx : Context)
    (beacon : Address) (i : Input) (before : World) (result : Result Unit) (total : Nat) : Prop :=
  CallSpec.Balances before.balances result.world.balances ctx.self beacon total ∧
  result.world.balances ctx.sender = before.balances ctx.sender ∧
  result.world.balances ctx.self + total = before.balances ctx.self ∧
  result.world.balances beacon = before.balances beacon + total ∧
  (result.world.core.readContractSlot beacon.val countSlot).val =
    (before.core.readContractSlot beacon.val countSlot).val + nonzeroCount (values i.allocations) ∧
  ∃ withdrawn deposited trace,
    TopupLiveWithdrawal.Callback ctx.self ctx.sender (word total) withdrawn trace ∧
    Effects (TopupBeaconFundedTx.routerContext ctx) beacon
      (inputsAt hash ctx.sender i withdrawn) (values i.allocations) withdrawn deposited ∧
    result.world.core = deposited.core ∧ result.world.balances = deposited.balances ∧
    result.world.logs = deposited.logs ++ [topUpEvent ctx.sender i total] ∧
    result.attempts = trace ++ attempts (TopupBeaconFundedTx.routerContext ctx) beacon
      (inputsAt hash ctx.sender i withdrawn) (values i.allocations)

set_option maxRecDepth 4096 in
/-- Connect executed router guards to the concrete PR273 batch, derive word fit
from the real gateway widths, execute the source assertion and append its event.
Minimum and matching helper lengths are honest success-domain conditions;
execution performs the length check only after withdrawal. -/
theorem positive_success (hash : TopupRouterCredentials.Keccak)
    (cfg : TopupWeiBounds.GatewayConfig) (validators : List TopupWeiBounds.ValidatorInput)
    (ns : List Nat) (hc : validators.length ≤ cfg.maxValidators.val)
    (hl : TopupWeiBounds.limits cfg validators = some ns)
    (k : Queue.Keccak) (c : Pipeline.Config) (staticOther : StaticCall.External) (other : External)
    (ctx : Context) (beacon : Address) (before : World) (i : Input) (total : Nat)
    (hlimits : values i.limits = TopupWeiBounds.weiLimits ns)
    (hcheck : guardSum (values i.allocations) (values i.limits) 0 = .ok total)
    (htarget : total ≤ i.roundedTarget.val) (hn : total ≠ 0)
    (hlen : i.pubkeys.length = i.allocations.length) (hkeys : ∀ pk ∈ i.pubkeys, pk.length = 48)
    (hmin : ∀ a ∈ values i.allocations, a ≠ 0 → 10^18 ≤ a)
    (demand reference deadline time : Nat) (b : Pipeline.Bound c ctx before)
    (hb : Queue.isBunkerModeActive c.contracts.queue before = false)
    (hp : (before.core.readContractSlot ctx.self.val activeSlot).val ≠ 0)
    (hauth : ctx.sender = c.contracts.router)
    (hq : Queue.unfinalizedStETH k c.contracts.queue before = .ok demand)
    (hamount : total ≤ (QueueCalls.allocationValues ctx before demand).deposits +
      (QueueCalls.allocationValues ctx before demand).unreserved)
    (hf : Consensus.compute c.frame (Pipeline.prepared ctx (word total) before demand).core.blockTimestamp.val
      ((Pipeline.prepared ctx (word total) before demand).core.readContractSlot
        c.consensus.val c.frame.frameSlot).val = .ok (reference,deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time)
    (hfunds : total ≤ before.balances ctx.self)
    (hlido : ctx.self = c.lido)
    (hrcode : (before.core.codeSize c.contracts.router.val).val ≠ 0)
    (hbcode : (before.core.codeSize beacon.val).val ≠ 0)
    (hlr : ctx.self ≠ c.contracts.router) (hlb : ctx.self ≠ beacon) (hrb : c.contracts.router ≠ beacon)
    (hcap : (before.core.readContractSlot beacon.val countSlot).val +
      nonzeroCount (values i.allocations) ≤ maxCount) :
    let result := execute hash (Pipeline.external k c staticOther other) ctx beacon i before
    total = allocSum (values i.allocations) ∧ result.outcome = .ok () ∧
      Postcondition hash ctx beacon i before result total := by
  obtain ⟨heq,hfit,hg⟩ := checked_fields cfg validators ns i total hc hl hlimits hcheck hmin
  have hv : (word total).val = total := word_val hfit
  have hnword : (word total).val ≠ 0 := by rwa [hv]
  let ext := Pipeline.external k c staticOther other
  let withdrawn := Live.run (TopupLiveWithdrawal.suffix ext ctx (word total)) before
  obtain ⟨hs,hbalances,hcallback⟩ := TopupLiveWithdrawal.positive_success k c staticOther other
    ctx before (word total) demand reference deadline time b hb hp hauth hnword hq
    (by rwa [hv]) hf ht (by rwa [hv]) hlido hrcode hlr
  change withdrawn.outcome = .ok () at hs
  change TopupLiveWithdrawal.Balances before.balances withdrawn.world.balances
    ctx.self c.contracts.router (word total).val at hbalances
  change TopupLiveWithdrawal.Callback ctx.self c.contracts.router (word total)
    withdrawn.world withdrawn.attempts at hcallback
  have hseed : ((Pipeline.spent ctx (word total) before demand reference).core.readContractSlot
      ctx.self.val seedSlot).val % width + (word 0).val < Verity.Core.UINT256_MODULUS := by
    have hm := Nat.mod_lt
      ((Pipeline.spent ctx (word total) before demand reference).core.readContractSlot ctx.self.val seedSlot).val
      (show 0 < width by decide)
    change _ % width + 0 < 2^256
    unfold width at hm ⊢
    omega
  have he := Pipeline.success k c staticOther other ctx before (word total) (word 0)
    demand reference deadline time b hb hp hauth hnword hq (by rwa [hv]) hf ht hseed
    (by rwa [hv]) hlido hrcode
  have hwithdrawCode : withdrawn.world.core.codeSize = before.core.codeSize := by
    dsimp only [withdrawn,ext]
    simp only [TopupLiveWithdrawal.suffix,if_neg hnword,he]
    exact Pipeline.final_code ctx (word total) (word 0) before demand reference
  have hwithdrawCount : withdrawn.world.core.readContractSlot beacon.val countSlot =
      before.core.readContractSlot beacon.val countSlot := by
    dsimp only [withdrawn,ext]
    simp only [TopupLiveWithdrawal.suffix,if_neg hnword,he]
    exact TopupBeaconFundedTx.accounting_count ctx (word total) before demand reference beacon
  have hrouter : withdrawn.world.balances (TopupBeaconFundedTx.routerContext ctx).self =
      before.balances c.contracts.router + total := by
    change withdrawn.world.balances ctx.sender = _
    rw [hauth,hbalances.router_credit,hv]
  obtain ⟨after,hloop,hbLoop,hcount,_,effects⟩ := TopupBeaconBatch.loop_success
    (TopupBeaconFundedTx.routerContext ctx) beacon (values i.allocations)
    (inputsAt hash ctx.sender i withdrawn.world) withdrawn.world
    (inputs_admissible hash ctx.sender i withdrawn.world hlen hkeys hg)
    (by simpa [TopupBeaconFundedTx.routerContext,hauth] using hrb)
    (by rwa [hwithdrawCode]) (by rw [hrouter,← heq]; omega) (by rwa [hwithdrawCount])
  have htotal : CallSpec.Balances before.balances after.balances ctx.self beacon total := by
    intro account
    have hl : withdrawn.world.balances account + (if account = ctx.self then total else 0) =
        before.balances account + (if account = c.contracts.router then total else 0) := by
      by_cases h1 : account = ctx.self
      · subst account
        have hd := hbalances.lido_debit
        rw [hv] at hd
        simpa [hlr] using hd
      · by_cases h2 : account = c.contracts.router
        · subst account
          simp [h1,hv,hbalances.router_credit]
        · simp [h1,h2,hbalances.other_accounts account h1 h2]
    have hb' := hbLoop account
    change after.balances account + (if account = ctx.sender then allocSum (values i.allocations) else 0) = _ at hb'
    rw [hauth,← heq] at hb'
    split_ifs at hl hb' ⊢ <;> omega
  have hrouterAfter : after.balances ctx.sender = before.balances ctx.sender := by
    rw [hauth]
    have hh := htotal c.contracts.router
    simpa [CallSpec.Balances,Ne.symm hlr,hrb] using hh
  have hnonempty : i.pubkeys ≠ [] := by
    intro hz
    have hz' : i.allocations = [] := List.length_eq_zero_iff.mp (by simpa [hz] using hlen.symm)
    simp [hz',values,allocSum] at heq
    exact hn heq
  have hhelper : helper hash (TopupBeaconFundedTx.routerContext ctx) beacon i withdrawn.world =
      ⟨.ok (),after,attempts (TopupBeaconFundedTx.routerContext ctx) beacon
        (inputsAt hash ctx.sender i withdrawn.world) (values i.allocations)⟩ := by
    simpa only [helper,if_neg hnonempty,hlen,ne_eq,not_true_eq_false,if_false,
      TopupBeaconFundedTx.routerContext] using hloop
  have hprogram : program hash ext ctx beacon i before =
      ⟨.ok (),{after with logs := after.logs ++ [topUpEvent ctx.sender i total]},
        withdrawn.attempts ++ attempts (TopupBeaconFundedTx.routerContext ctx) beacon
          (inputsAt hash ctx.sender i withdrawn.world) (values i.allocations)⟩ := by
    simp only [program,hcheck,if_neg (Nat.not_lt.mpr htarget),if_neg hn,bindExec]
    dsimp only [withdrawn] at hs hhelper ⊢
    rw [hs,hhelper]
    simp [finish,hrouterAfter]
  have hexe : execute hash ext ctx beacon i before =
      ⟨.ok (),{after with logs := after.logs ++ [topUpEvent ctx.sender i total]},
        withdrawn.attempts ++ attempts (TopupBeaconFundedTx.routerContext ctx) beacon
          (inputsAt hash ctx.sender i withdrawn.world) (values i.allocations)⟩ := by
    simp [execute,Live.run,hprogram]
  change let result := execute hash ext ctx beacon i before; _
  rw [hexe]
  refine ⟨heq,rfl,htotal,hrouterAfter,?_,?_,?_,withdrawn.world,after,withdrawn.attempts,?_,effects,rfl,rfl,rfl,rfl⟩
  · simpa [CallSpec.Balances,hlb] using htotal ctx.self
  · simpa [CallSpec.Balances,Ne.symm hlb] using htotal beacon
  · rwa [hwithdrawCount] at hcount
  · rwa [hauth]


/-- Initial finite-support asset bounds remain separate from the source sum's
uint256 width. Derived conservation preserves them after the final event. -/
theorem postcondition_bounded (hash : TopupRouterCredentials.Keccak) (ctx : Context)
    (beacon : Address) (i : Input) (before : World) (result : Result Unit) (total : Nat)
    (h : Postcondition hash ctx beacon i before result total)
    (accounts : List Address) (limit : Nat) (hb : BalanceSpec.Bounded before.balances accounts limit)
    (hl : ctx.self ∈ accounts) (hd : beacon ∈ accounts) :
    BalanceSpec.Bounded result.world.balances accounts limit ∧
      BalanceSpec.mass result.world.balances accounts = BalanceSpec.mass before.balances accounts :=
  BalanceSpec.preserves _ _ _ _ _ _ _ hb hl hd h.1

end LidoSRv3.Audit.Source.TopupRouterContinuation
