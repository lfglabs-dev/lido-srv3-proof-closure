import LidoSRv3.Audit.Source.TopupBeaconBatch
import LidoSRv3.Audit.Source.TopupLiveWithdrawal

namespace LidoSRv3.Audit.Verity.TopupBeaconFundedTx
open LidoSRv3.Audit.Source
open TrioReserve1 Live TopupBeaconCallee TopupBeaconBatch
open TopupTx LidoSRv3.Audit.SolidityTopup

/-! One Live.World from the concrete delivered Lido withdrawal through the
actual source-byte beacon callee loop. The old PR267 and registered TopupTx
programs are unchanged. No caller-balance projection or inserted credit.
-/

def amount (call : TopupCall) : Word := word (allocSumUnchecked call.moduleReturndata)
def routerContext (ctx : Context) : Context := ⟨ctx.sender,ctx.self⟩

def program (callee : External) (ctx : Context) (beacon : Address)
    (call : TopupCall) (hw : SourceTopupCallWellFormed call) : Exec Unit :=
  if allocSumUnchecked call.moduleReturndata = 0 then pureExec ()
  else bindExec (Live.run (TopupLiveWithdrawal.suffix callee ctx (amount call)))
    (fun _ => TopupBeaconBatch.loop (routerContext ctx) beacon
      (sourceDeposits call hw) call.moduleReturndata)

def execute (callee : External) (ctx : Context) (beacon : Address)
    (call : TopupCall) (hw : SourceTopupCallWellFormed call) : Exec Unit :=
  Live.run (program callee ctx beacon call hw)

/-- Source withdrawal's only storage writes are the Lido accounting slots,
which cannot change beacon count slot32. This is derived, not a callee frame
premise, and does not rely on the absence of callee execution. -/
theorem accounting_count (ctx : Context) (value : Word) (w : World)
    (demand reference : Nat) (beacon : Address) :
    (Pipeline.seeded ctx (word 0) (Pipeline.spent ctx value w demand reference)).core.readContractSlot
      beacon.val countSlot = w.core.readContractSlot beacon.val countSlot := by
  have hbuffer (s : Verity.ContractState) (v : Word) :
      (s.writeContractSlot ctx.self.val bufferSlot v).readContractSlot beacon.val countSlot =
        s.readContractSlot beacon.val countSlot := Pipeline.read_other_slot _ _ _ _ _ _ (by decide)
  have hnext (s : Verity.ContractState) (v : Word) :
      (s.writeContractSlot ctx.self.val nextSlot v).readContractSlot beacon.val countSlot =
        s.readContractSlot beacon.val countSlot := Pipeline.read_other_slot _ _ _ _ _ _ (by decide)
  have hreserve (s : Verity.ContractState) (v : Word) :
      (s.writeContractSlot ctx.self.val reserveSlot v).readContractSlot beacon.val countSlot =
        s.readContractSlot beacon.val countSlot := Pipeline.read_other_slot _ _ _ _ _ _ (by decide)
  simp only [Pipeline.seeded,show (word 0).val = 0 from rfl,ite_true]
  unfold Pipeline.spent Pipeline.prepared Spending.afterFrame Spending.beforeFrame
  dsimp only
  split <;> simp only [hbuffer,hnext,hreserve]

def withdrawalAttempts (c : Pipeline.Config) (ctx : Context) (w : World)
    (value : Word) (demand reference deadline time : Nat) : List Attempt :=
  Pipeline.statusTrace c ctx w ++ Pipeline.routerTrace c ctx ++ Pipeline.allocationTrace c ctx demand ++
    Pipeline.frameTrace c ctx reference deadline time ++
    [⟨⟨ctx.self,c.contracts.router,value,encode 4 0x13ae8460⟩,true,[],[]⟩]

/-- The source gateway's uint64/count/allocation bounds can discharge the
sum's word representation. This does not postulate any initial asset bound. -/
theorem gateway_amount_exact (cfg : TopupWeiBounds.GatewayConfig)
    (validators : List TopupWeiBounds.ValidatorInput) (limits : List Nat) (call : TopupCall)
    (hc : validators.length ≤ cfg.maxValidators.val)
    (hl : TopupWeiBounds.limits cfg validators = some limits)
    (hg : TopupWeiBounds.allocationGuards call.moduleReturndata (TopupWeiBounds.weiLimits limits)) :
    allocSum call.moduleReturndata < uint256Modulus ∧
      (amount call).val = allocSum call.moduleReturndata := by
  obtain ⟨hfit,he⟩ := TopupFundedSource.gateway_sum_exact cfg validators limits call.moduleReturndata hc hl hg
  exact ⟨hfit,by unfold amount; rw [he]; exact word_val hfit⟩

set_option maxRecDepth 4096 in
/-- Concrete withdrawal and every actual beacon callee execute successfully
from source/physical inputs. Initial count+nonzeroCount derives all insertion
capacities; same moduleReturndata determines pull, payloads and every value.
The word-fit condition applies to the summed pull, not to a fabricated credit.
-/
theorem positive_conservation (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External)
    (ctx : Context) (beacon : Address) (before : World)
    (call : TopupCall) (hw : SourceTopupCallWellFormed call)
    (demand reference deadline time : Nat) (b : Pipeline.Bound c ctx before)
    (hb : Queue.isBunkerModeActive c.contracts.queue before = false)
    (hp : (before.core.readContractSlot ctx.self.val activeSlot).val ≠ 0)
    (hauth : ctx.sender = c.contracts.router)
    (hn : allocSum call.moduleReturndata ≠ 0)
    (hfit : allocSum call.moduleReturndata < uint256Modulus)
    (hq : Queue.unfinalizedStETH k c.contracts.queue before = .ok demand)
    (hamount : (amount call).val ≤ (QueueCalls.allocationValues ctx before demand).deposits +
      (QueueCalls.allocationValues ctx before demand).unreserved)
    (hf : Consensus.compute c.frame
      (Pipeline.prepared ctx (amount call) before demand).core.blockTimestamp.val
      ((Pipeline.prepared ctx (amount call) before demand).core.readContractSlot
        c.consensus.val c.frame.frameSlot).val = .ok (reference,deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time)
    (hfunds : (amount call).val ≤ before.balances ctx.self)
    (hlido : ctx.self = c.lido)
    (hrcode : (before.core.codeSize c.contracts.router.val).val ≠ 0)
    (hbcode : (before.core.codeSize beacon.val).val ≠ 0)
    (hlr : ctx.self ≠ c.contracts.router) (hlb : ctx.self ≠ beacon)
    (hrb : c.contracts.router ≠ beacon)
    (hg : AmountsAdmitted call.moduleReturndata)
    (hcap : (before.core.readContractSlot beacon.val countSlot).val +
      nonzeroCount call.moduleReturndata ≤ maxCount) :
    let result := execute (Pipeline.external k c staticOther other) ctx beacon call hw before
    result.outcome = .ok () ∧
      result.world.balances c.contracts.router = before.balances c.contracts.router ∧
      result.world.balances ctx.self + allocSum call.moduleReturndata = before.balances ctx.self ∧
      result.world.balances beacon = before.balances beacon + allocSum call.moduleReturndata ∧
      (∀ account, account ≠ ctx.self → account ≠ c.contracts.router → account ≠ beacon →
        result.world.balances account = before.balances account) ∧
      CallSpec.Balances before.balances result.world.balances ctx.self beacon (allocSum call.moduleReturndata) ∧
      (result.world.core.readContractSlot beacon.val countSlot).val =
        (before.core.readContractSlot beacon.val countSlot).val + nonzeroCount call.moduleReturndata ∧
      result.attempts = withdrawalAttempts c ctx before (amount call) demand reference deadline time ++
        attempts (routerContext ctx) beacon (sourceDeposits call hw) call.moduleReturndata ∧
      (∃ withdrawn : World, TopupLiveWithdrawal.Callback ctx.self c.contracts.router (amount call)
        withdrawn (withdrawalAttempts c ctx before (amount call) demand reference deadline time) ∧
        Effects (routerContext ctx) beacon (sourceDeposits call hw) call.moduleReturndata withdrawn result.world) ∧
      (∀ (accounts : List Address) (limit : Nat),
        BalanceSpec.Bounded before.balances accounts limit → ctx.self ∈ accounts → beacon ∈ accounts →
        BalanceSpec.Bounded result.world.balances accounts limit ∧
        BalanceSpec.mass result.world.balances accounts = BalanceSpec.mass before.balances accounts) := by
  have hexact := allocSumUnchecked_eq_allocSum hfit
  have hval : (amount call).val = allocSum call.moduleReturndata := by
    unfold amount; rw [hexact]; exact word_val hfit
  have hnword : (amount call).val ≠ 0 := by rwa [hval]
  have hnwrapped : allocSumUnchecked call.moduleReturndata ≠ 0 := by rwa [hexact]
  let ext := Pipeline.external k c staticOther other
  let withdrawn := Live.run (TopupLiveWithdrawal.suffix ext ctx (amount call)) before
  obtain ⟨hs,hbalances,hcallback⟩ := TopupLiveWithdrawal.positive_success k c staticOther other
    ctx before (amount call) demand reference deadline time b hb hp hauth hnword hq hamount hf ht
    hfunds hlido hrcode hlr
  change withdrawn.outcome = .ok () at hs
  change TopupLiveWithdrawal.Balances before.balances withdrawn.world.balances
    ctx.self c.contracts.router (amount call).val at hbalances
  change TopupLiveWithdrawal.Callback ctx.self c.contracts.router (amount call)
    withdrawn.world withdrawn.attempts at hcallback
  have hseed : ((Pipeline.spent ctx (amount call) before demand reference).core.readContractSlot
      ctx.self.val seedSlot).val % width + (word 0).val < Verity.Core.UINT256_MODULUS := by
    have hm := Nat.mod_lt
      ((Pipeline.spent ctx (amount call) before demand reference).core.readContractSlot ctx.self.val seedSlot).val
      (show 0 < width by decide)
    change _ % width + 0 < 2^256
    unfold width at hm ⊢
    omega
  have he := Pipeline.success k c staticOther other ctx before (amount call) (word 0)
    demand reference deadline time b hb hp hauth hnword hq hamount hf ht hseed hfunds hlido hrcode
  have hwithdrawCode : withdrawn.world.core.codeSize = before.core.codeSize := by
    dsimp only [withdrawn,ext]
    simp only [TopupLiveWithdrawal.suffix,if_neg hnword,he]
    exact Pipeline.final_code ctx (amount call) (word 0) before demand reference
  have hwithdrawCount : withdrawn.world.core.readContractSlot beacon.val countSlot =
      before.core.readContractSlot beacon.val countSlot := by
    dsimp only [withdrawn,ext]
    simp only [TopupLiveWithdrawal.suffix,if_neg hnword,he]
    exact accounting_count ctx (amount call) before demand reference beacon
  have hwithdrawTrace : withdrawn.attempts =
      withdrawalAttempts c ctx before (amount call) demand reference deadline time := by
    dsimp only [withdrawn,ext]
    simp only [TopupLiveWithdrawal.suffix,if_neg hnword,he]
    rfl
  have hrouter : withdrawn.world.balances (routerContext ctx).self =
      before.balances c.contracts.router + allocSum call.moduleReturndata := by
    change withdrawn.world.balances ctx.sender = _
    rw [hauth,hbalances.router_credit,hval]
  obtain ⟨after,hloop,hbLoop,hcount,_hcode,effects⟩ := TopupBeaconBatch.loop_success
    (routerContext ctx) beacon call.moduleReturndata (sourceDeposits call hw) withdrawn.world
    (sourceDeposits_admissible call hw hg) (by simpa [routerContext,hauth] using hrb)
    (by rwa [hwithdrawCode]) (by rw [hrouter]; omega) (by rwa [hwithdrawCount])
  have hprogram : program ext ctx beacon call hw before =
      ⟨.ok (),after,withdrawn.attempts ++ attempts (routerContext ctx) beacon (sourceDeposits call hw) call.moduleReturndata⟩ := by
    simp only [program,if_neg hnwrapped,bindExec]
    dsimp only [withdrawn] at hs hloop ⊢
    rw [hs,hloop]
  have hexe : execute ext ctx beacon call hw before =
      ⟨.ok (),after,withdrawn.attempts ++ attempts (routerContext ctx) beacon (sourceDeposits call hw) call.moduleReturndata⟩ := by
    simp [execute,Live.run,hprogram]
  have htotal : CallSpec.Balances before.balances after.balances ctx.self beacon
      (allocSum call.moduleReturndata) := by
    intro account
    have hl : withdrawn.world.balances account + (if account = ctx.self then allocSum call.moduleReturndata else 0) =
        before.balances account + (if account = c.contracts.router then allocSum call.moduleReturndata else 0) := by
      by_cases h1 : account = ctx.self
      · subst account
        simp [hlr,← hval,hbalances.lido_debit]
      · by_cases h2 : account = c.contracts.router
        · subst account
          simp [h1,hval,hbalances.router_credit]
        · simp [h1,h2,hbalances.other_accounts account h1 h2]
    have hb' := hbLoop account
    change after.balances account + (if account = ctx.sender then allocSum call.moduleReturndata else 0) = _ at hb'
    rw [hauth] at hb'
    split_ifs at hl hb' ⊢ <;> omega
  change let result := execute ext ctx beacon call hw before; _
  rw [hexe]
  dsimp only
  refine ⟨rfl,?_,?_,?_,?_,htotal,?_,?_,?_,?_⟩
  · have h := htotal c.contracts.router
    simpa [CallSpec.Balances,Ne.symm hlr,hrb] using h
  · have h := htotal ctx.self
    simpa [CallSpec.Balances,hlb] using h
  · have h := htotal beacon
    simpa [CallSpec.Balances,Ne.symm hlb] using h
  · intro account hl _ hr
    have h := htotal account
    simpa [CallSpec.Balances,hl,hr] using h
  · rwa [hwithdrawCount] at hcount
  · rw [hwithdrawTrace]
  · exact ⟨withdrawn.world,by rwa [← hwithdrawTrace],effects⟩
  · intro accounts limit hbounded hs hb
    exact BalanceSpec.preserves _ _ _ _ _ _ _ hbounded hs hb htotal

/-- Preserve the source's full wrapped-zero domain, including nonzero
mathematical sums which wrap to zero. No withdrawal or beacon call is made. -/
theorem wrapped_zero (callee : External) (ctx : Context) (beacon : Address)
    (call : TopupCall) (hw : SourceTopupCallWellFormed call) (before : World)
    (hz : allocSumUnchecked call.moduleReturndata = 0) :
    execute callee ctx beacon call hw before = ⟨.ok (),before,[]⟩ := by
  simp [execute,program,hz,Live.run,pureExec]

theorem failure_restores (callee : External) (ctx : Context) (beacon : Address)
    (call : TopupCall) (hw : SourceTopupCallWellFormed call) (before : World) (fault : Fault)
    (h : (execute callee ctx beacon call hw before).outcome = .error fault) :
    (execute callee ctx beacon call hw before).world = before := by
  unfold execute Live.run at *
  dsimp only at *
  split <;> simp_all

end LidoSRv3.Audit.Verity.TopupBeaconFundedTx
