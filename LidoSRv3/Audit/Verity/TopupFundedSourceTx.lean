import LidoSRv3.Audit.Source.TopupFundedSource
import LidoSRv3.Audit.Source.TopupLiveWithdrawal

namespace LidoSRv3.Audit.Verity.TopupFundedSourceTx
open _root_.Verity
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Source
open TopupTx TopupFundedSource TrioReserve1

/-! Caller-side composition, pin 17005714f151e5502c559932319a3f2f74ac2436.
The withdrawal executes its real delivered callee chain. Beacon pushes execute
the existing caller-side primitive, which debits and journals but does not run
the beacon callee. Therefore the result proves Lido debit, router restoration
and emitted call values, not beacon balances/storage or total-world ETH mass.
Live.attempts records the withdrawal calls; beacon frames are in core.calls.
Preserving the final withdrawal callback does not make it the last global call.
Generic cfg results concern the local caller model. Pinned-source field/unit
correspondence uses pinnedConfig; Guards alone does not require gwei alignment.
-/

/-- Read the actual ledger into the local caller view; no credit is inserted. -/
def project (router : Live.Address) (w : Live.World) : ContractState :=
  {w.core with selfBalance := Live.word (w.balances router)}

/-- Write the actual local result back to its one ledger account. -/
def commit (router : Live.Address) (w : Live.World) (localState : ContractState) : Live.World :=
  {w with
    core := localState
    balances := fun a => if a = router then localState.selfBalance.val else w.balances a}

theorem project_balance (router : Live.Address) (w : Live.World)
    (h : w.balances router < uint256Modulus) :
    (project router w).selfBalance.val = w.balances router := word_val h

theorem ledger_roundtrip (router : Live.Address) (w : Live.World)
    (h : w.balances router < uint256Modulus) :
    (commit router w (project router w)).balances = w.balances := by
  funext a
  by_cases ha : a = router <;> simp [commit, ha, project_balance router w h]

/-- Uses the modern loop on precisely the source inputs constructed from this
call. The caller view retains all prior storage and call records. -/
def push (cfg : SourceTopupConfig) (router : Live.Address) (call : TopupCall)
    (hw : SourceTopupCallWellFormed call) : Live.Exec Unit := fun w =>
  match sourcePushLoop cfg (sourceDeposits call hw) call.moduleReturndata (project router w) with
  | .success _ after => ⟨.ok (), commit router w after, []⟩
  | .revert reason _ => ⟨.error (.reason reason), w, []⟩

def program (callee : Live.External) (ctx : Live.Context) (cfg : SourceTopupConfig)
    (call : TopupCall) (hw : SourceTopupCallWellFormed call) : Live.Exec Unit :=
  let total := allocSumUnchecked call.moduleReturndata
  if total = 0 then Live.pureExec ()
  else Live.bindExec
    (Live.run (TopupLiveWithdrawal.suffix callee ctx (Live.word total)))
    (fun _ => push cfg ctx.sender call hw)

def execute (callee : Live.External) (ctx : Live.Context) (cfg : SourceTopupConfig)
    (call : TopupCall) (hw : SourceTopupCallWellFormed call) : Live.Exec Unit :=
  Live.run (program callee ctx cfg call hw)

def amount (call : TopupCall) : Live.Word := Live.word (allocSumUnchecked call.moduleReturndata)

/-- An alternative discharge of the projection bound: source-sized gateway
limits first derive the exact sum; funding plus an independent initial two-
account asset bound then covers the old router balance as well. Reachability of
that initial asset invariant is not asserted. -/
theorem gateway_projection_bound (cfg : TopupWeiBounds.GatewayConfig)
    (validators : List TopupWeiBounds.ValidatorInput) (limits : List Nat)
    (call : TopupCall) (before : Live.World) (lido router : Live.Address)
    (hc : validators.length ≤ cfg.maxValidators.val)
    (hl : TopupWeiBounds.limits cfg validators = some limits)
    (hg : TopupWeiBounds.allocationGuards call.moduleReturndata (TopupWeiBounds.weiLimits limits))
    (hfund : (amount call).val ≤ before.balances lido)
    (hassets : before.balances lido + before.balances router < uint256Modulus) :
    before.balances router + allocSum call.moduleReturndata < uint256Modulus := by
  obtain ⟨hfit, hexact⟩ := gateway_sum_exact cfg validators limits call.moduleReturndata hc hl hg
  have hval : (amount call).val = allocSum call.moduleReturndata := by
    unfold amount
    rw [hexact]
    exact word_val hfit
  rw [hval] at hfund
  omega

theorem accounting_calls (ctx : Live.Context) (a : Live.Word) (before : Live.World)
    (demand reference : Nat) :
    (Pipeline.seeded ctx (Live.word 0) (Pipeline.spent ctx a before demand reference)).core.calls =
      before.core.calls := by
  have hwrite (st : ContractState) (account location : Nat) (value : Uint256) :
      (st.writeContractSlot account location value).calls = st.calls := by
    unfold ContractState.writeContractSlot
    split <;> rfl
  simp only [Pipeline.seeded, show (Live.word 0).val = 0 from rfl, ↓reduceIte]
  unfold Pipeline.spent Pipeline.prepared Spending.afterFrame Spending.beforeFrame
  dsimp only
  split <;> simp only [hwrite]

/-- Ledger writes read back the loop's real result. The sum is not used by the
implementation to manufacture a debit; it appears only in this derived law. -/
theorem push_run (cfg : SourceTopupConfig) (router : Live.Address) (call : TopupCall)
    (hw : SourceTopupCallWellFormed call) (w : Live.World)
    (hg : Guards cfg call.moduleReturndata)
    (hwidth : w.balances router < uint256Modulus)
    (hfund : allocSum call.moduleReturndata ≤ w.balances router) :
    push cfg router call hw w =
      ⟨.ok (), {w with
        core := {w.core with
          selfBalance := ((w.balances router - allocSum call.moduleReturndata : Nat) : Uint256)
          calls := w.core.calls ++ journal (sourceDeposits call hw) call.moduleReturndata}
        balances := fun a => if a = router then w.balances router - allocSum call.moduleReturndata
          else w.balances a}, []⟩ := by
  have hb := project_balance router w hwidth
  unfold push
  rw [source_deposits_run cfg call hw (project router w) hg (by rwa [hb])]
  have hfit : w.balances router - allocSum call.moduleReturndata < uint256Modulus :=
    Nat.lt_of_le_of_lt (Nat.sub_le _ _) hwidth
  have hv : (Live.word (w.balances router)).val = w.balances router := word_val hwidth
  have hm : (w.balances router - allocSum call.moduleReturndata) % Core.Uint256.modulus =
      w.balances router - allocSum call.moduleReturndata := word_val hfit
  simp [commit, project, hv, hm]

/-- Same allocation list determines the real Lido pull and every byte-bearing
beacon frame. On this stated word-representable positive domain, execution
returns the router to its arbitrary entry balance. The independent journal sum
accounts for exactly the Lido debit; it is not a beacon callee-credit theorem. -/
theorem positive_conservation (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : Live.External)
    (ctx : Live.Context) (before : Live.World) (cfg : SourceTopupConfig)
    (call : TopupCall) (hw : SourceTopupCallWellFormed call)
    (demand reference deadline time : Nat) (b : Pipeline.Bound c ctx before)
    (hb : Queue.isBunkerModeActive c.contracts.queue before = false)
    (hp : (before.core.readContractSlot ctx.self.val Live.activeSlot).val ≠ 0)
    (hauth : ctx.sender = c.contracts.router)
    (hn : allocSum call.moduleReturndata ≠ 0)
    (hq : Queue.unfinalizedStETH k c.contracts.queue before = .ok demand)
    (hamount : (amount call).val ≤ (QueueCalls.allocationValues ctx before demand).deposits +
      (QueueCalls.allocationValues ctx before demand).unreserved)
    (hf : Consensus.compute c.frame
      (Pipeline.prepared ctx (amount call) before demand).core.blockTimestamp.val
      ((Pipeline.prepared ctx (amount call) before demand).core.readContractSlot
        c.consensus.val c.frame.frameSlot).val = .ok (reference, deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time)
    (hfunds : (amount call).val ≤ before.balances ctx.self)
    (hlido : ctx.self = c.lido)
    (hrcode : (before.core.codeSize c.contracts.router.val).val ≠ 0)
    (hd : ctx.self ≠ c.contracts.router)
    (hg : Guards cfg call.moduleReturndata)
    (hwidth : before.balances c.contracts.router + allocSum call.moduleReturndata < uint256Modulus) :
    let result := execute (Pipeline.external k c staticOther other) ctx cfg call hw before
    result.outcome = .ok () ∧
      result.world.balances c.contracts.router = before.balances c.contracts.router ∧
      result.world.balances ctx.self + allocSum call.moduleReturndata = before.balances ctx.self ∧
      result.world.core.calls = before.core.calls ++ journal (sourceDeposits call hw) call.moduleReturndata ∧
      ((journal (sourceDeposits call hw) call.moduleReturndata).map (·.value)).sum =
        allocSum call.moduleReturndata ∧
      TopupLiveWithdrawal.Callback ctx.self c.contracts.router (amount call)
        result.world result.attempts := by
  have hfit : allocSum call.moduleReturndata < uint256Modulus := by omega
  have hexact := allocSumUnchecked_eq_allocSum hfit
  have hval : (amount call).val = allocSum call.moduleReturndata := by
    unfold amount
    rw [hexact]
    exact word_val hfit
  have hnword : (amount call).val ≠ 0 := by rwa [hval]
  have hnwrapped : allocSumUnchecked call.moduleReturndata ≠ 0 := by rwa [hexact]
  let ext := Pipeline.external k c staticOther other
  let withdrawn := Live.run (TopupLiveWithdrawal.suffix ext ctx (amount call)) before
  obtain ⟨hs, hbalances, hcallback⟩ := TopupLiveWithdrawal.positive_success k c staticOther other
    ctx before (amount call) demand reference deadline time b hb hp hauth hnword hq hamount hf ht
    hfunds hlido hrcode hd
  change withdrawn.outcome = .ok () at hs
  change TopupLiveWithdrawal.Balances before.balances withdrawn.world.balances
    ctx.self c.contracts.router (amount call).val at hbalances
  change TopupLiveWithdrawal.Callback ctx.self c.contracts.router (amount call)
    withdrawn.world withdrawn.attempts at hcallback
  have hr : withdrawn.world.balances ctx.sender =
      before.balances c.contracts.router + allocSum call.moduleReturndata := by
    rw [hauth, hbalances.router_credit, hval]
  have hloop := push_run cfg ctx.sender call hw withdrawn.world hg
    (by rw [hr]; exact hwidth) (by rw [hr]; omega)
  let finalWorld : Live.World := {withdrawn.world with
    core := {withdrawn.world.core with
      selfBalance := ((withdrawn.world.balances ctx.sender - allocSum call.moduleReturndata : Nat) : Uint256)
      calls := withdrawn.world.core.calls ++ journal (sourceDeposits call hw) call.moduleReturndata}
    balances := fun a => if a = ctx.sender then
      withdrawn.world.balances ctx.sender - allocSum call.moduleReturndata else withdrawn.world.balances a}
  change push cfg ctx.sender call hw withdrawn.world = ⟨.ok (), finalWorld, []⟩ at hloop
  have hprogram : program ext ctx cfg call hw before = ⟨.ok (), finalWorld, withdrawn.attempts⟩ := by
    simp only [program, if_neg hnwrapped, Live.bindExec]
    dsimp only [withdrawn, amount] at hs hloop
    rw [hs, hloop]
    simp only [List.append_nil]
    rfl
  have hseed : ((Pipeline.spent ctx (amount call) before demand reference).core.readContractSlot
      ctx.self.val Live.seedSlot).val % Live.width + (Live.word 0).val < Core.UINT256_MODULUS := by
    have hm := Nat.mod_lt
      ((Pipeline.spent ctx (amount call) before demand reference).core.readContractSlot
        ctx.self.val Live.seedSlot).val (show 0 < Live.width by decide)
    change _ % Live.width + 0 < 2^256
    unfold Live.width at hm ⊢
    omega
  have he := Pipeline.success k c staticOther other ctx before (amount call) (Live.word 0)
    demand reference deadline time b hb hp hauth hnword hq hamount hf ht hseed hfunds hlido hrcode
  have hcalls : withdrawn.world.core.calls = before.core.calls := by
    dsimp only [withdrawn, ext]
    simp only [TopupLiveWithdrawal.suffix, if_neg hnword, he]
    exact accounting_calls ctx (amount call) before demand reference
  have hexe : execute ext ctx cfg call hw before = ⟨.ok (), finalWorld, withdrawn.attempts⟩ := by
    simp [execute, Live.run, hprogram]
  change let result := execute ext ctx cfg call hw before; _
  rw [hexe]
  dsimp only
  refine ⟨rfl, ?_, ?_, ?_, ?_, ?_⟩
  · simp [finalWorld, ← hauth, hr]
  · have hne : ctx.self ≠ ctx.sender := by rwa [hauth]
    simpa [finalWorld, hne, ← hval] using hbalances.lido_debit
  · simp [finalWorld, hcalls]
  · exact journal_value call.moduleReturndata _ (sourceDeposits_length call hw)
      (by simpa using hw.2.2.2.2.2)
  · exact hcallback

/-- Entire suffix no-op for the source's wrapped zero total, even when the
mathematical sum is nonzero. This preserves that explicit older input domain. -/
theorem wrapped_zero (callee : Live.External) (ctx : Live.Context) (cfg : SourceTopupConfig)
    (call : TopupCall) (hw : SourceTopupCallWellFormed call) (w : Live.World)
    (hz : allocSumUnchecked call.moduleReturndata = 0) :
    execute callee ctx cfg call hw w = ⟨.ok (), w, []⟩ := by
  simp [execute, program, hz, Live.run, Live.pureExec]

/-- A late local failure rolls back the same shared-world snapshot as the
withdrawal. Attempt records remain diagnostics, not committed beacon effects. -/
theorem failure_restores (callee : Live.External) (ctx : Live.Context) (cfg : SourceTopupConfig)
    (call : TopupCall) (hw : SourceTopupCallWellFormed call)
    (before after : Live.World) (fault : Live.Fault) (attempts : List Live.Attempt)
    (h : execute callee ctx cfg call hw before = ⟨.error fault, after, attempts⟩) :
    after = before := by
  unfold execute Live.run at h
  dsimp only at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.TopupFundedSourceTx
