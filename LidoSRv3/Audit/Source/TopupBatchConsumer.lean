import LidoSRv3.Audit.Source.TopupGatewayWitnessBatch
import LidoSRv3.Audit.Source.TopupRouterCommitted

/-! P-TOPUP-2's per-batch consumer at core17005714. The executed gateway
witness loop supplies the exact keys and wei limits passed to the existing
raw-module executor. The uint64 router cap is read from its packed slot and
the rounded target is computed here, never supplied as a bounded premise.
The preceding module-allocation result is arbitrary: the minimum establishes
the cap for every value that calculation can return. This is the value path;
preceding role/pause/timing/view-call admission and final history updates are
not claimed to be a full gateway execution by this module. -/
namespace LidoSRv3.Audit.Source.TopupBatchConsumer
open TrioReserve1 Live SszValidatorLeaf SszVerifierEntry SszWrapperIndex
open TopupGatewayWitnessBatch

/-- SRTypes.RouterState: uint24 lastModuleId, then uint64 block cap in slot5. -/
def blockCap (router : Address) (w : World) : Fin TopupWeiBounds.uint64Modulus :=
  ⟨(w.core.readContractSlot router.val (TopupRouterCredentials.routerRoot+5)).val / 2^24 % 2^64,
    Nat.mod_lt _ (by decide)⟩

/-- The neighboring uint24 module id and upper reserved bits cannot affect
this cap read. No assumption on a decoded configuration is supplied. -/
theorem blockCap_packed (router : Address) (w : World) (moduleId cap upper : Nat)
    (hm : moduleId < 2^24) (hc : cap < 2^64)
    (hs : (w.core.readContractSlot router.val (TopupRouterCredentials.routerRoot+5)).val =
      moduleId + cap * 2^24 + upper * 2^88) :
    (blockCap router w).val = cap := by
  simp only [blockCap,hs]
  omega

def target (router : Address) (moduleAllocation : Word) (w : World) : Word :=
  word (TopupWeiBounds.routerBudget moduleAllocation.val (blockCap router w))

theorem target_bound (router : Address) (moduleAllocation : Word) (w : World) :
    (target router moduleAllocation w).val ≤ (blockCap router w).val * 10^9 := by
  have hb : TopupWeiBounds.routerBudget moduleAllocation.val (blockCap router w) ≤
      (blockCap router w).val * TopupWeiBounds.gwei := by
    unfold TopupWeiBounds.routerBudget
    exact Nat.le_trans (Nat.sub_le _ _) (Nat.min_le_right _ _)
  have hf := TopupWeiBounds.uint64_wei_fits _ (blockCap router w).isLt
  change TopupWeiBounds.routerBudget moduleAllocation.val (blockCap router w) % 2^256 ≤ _
  rw [Nat.mod_eq_of_lt (by exact Nat.lt_of_le_of_lt hb hf)]
  exact hb

def moduleInput (out : Output) (moduleId : Word) (keyIndices operatorIds : List Word)
    (router : Address) (moduleAllocation : Word) (w : World) : TopupModuleCall.Input :=
  { moduleId
    roundedTarget := target router moduleAllocation w
    keyIndices, operatorIds
    pubkeys := out.pubkeys.map (List.map (fun b => UInt8.ofNat b.toNat))
    limits := out.limits.map word }

/-- Definitional equality of the input carried to the existing continuation.
The bound below follows the executed module and its continuation directly. -/
theorem continuation_input (out : Output) (moduleId : Word) (keys operators : List Word)
    (router : Address) (moduleAllocation : Word) (w : World) (allocations : List Word) :
    TopupModuleCall.continuationInput
      (moduleInput out moduleId keys operators router moduleAllocation w) allocations =
    routerInput out moduleId (target router moduleAllocation w) allocations := rfl

/-- Covered value path: actual length guards, actual witness/limit loop, then
raw module CALL/decode/withdrawal/beacon execution on the same World. Limits
and target are computed by this consumer, rather than accepted from a caller.
The arbitrary preceding allocation value imposes no restriction on the bound. -/
def run (hash : TopupRouterCredentials.Keccak) (moduleExternal withdrawalExternal : External)
    (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (gi : Configuration) (beacon : BeaconData) (divisor : Index) (credentials : Digest)
    (gateway : Address) (ctx : Context) (depositContract : Address) (moduleId : Word)
    (keyIndices operatorIds : List Word) (rows : List Row)
    (moduleAllocation : Word) (before : World) : Except GatewayFault (Result Unit) := do
  let cfg := TopupGatewayConfigWords.readConfig gateway before
  checkLengths cfg rows.length keyIndices.length operatorIds.length rows.length rows.length
  let out ← loop precompile oracle scratch gi cfg beacon divisor credentials none 0 rows
  pure (TopupModuleCall.execute hash moduleExternal withdrawalExternal ctx depositContract
    (moduleInput out moduleId keyIndices operatorIds ctx.sender moduleAllocation before) before)

private theorem bind_success {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β} (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | «error» e => cases h
  | ok x => exact ⟨x,rfl,h⟩

/-- The genuine module reply and its decoded allocations are bounded by the
packed router cap read before the call. This covers zero totals, empty returned
allocations, arbitrary module effects and every admitted gateway configuration.
No no-wrap, exact-total, count-bound or independent limit/target premise. -/
theorem run_success_exact_effects (hash : TopupRouterCredentials.Keccak)
    (moduleExternal withdrawalExternal : External) (precompile : Precompile)
    (oracle : RootOracle) (scratch : Fin 32 → Byte) (gi : Configuration)
    (beacon : BeaconData) (divisor : Index) (credentials : Digest)
    (gateway : Address) (ctx : Context) (depositContract : Address) (moduleId : Word)
    (keyIndices operatorIds : List Word) (rows : List Row) (moduleAllocation : Word)
    (before : World) (result : Result Unit)
    (h : run hash moduleExternal withdrawalExternal precompile oracle scratch gi beacon divisor
      credentials gateway ctx depositContract moduleId keyIndices operatorIds rows moduleAllocation before = .ok result)
    (hs : result.outcome = .ok ()) :
    ∃ out raw afterModule trace allocations,
      loop precompile oracle scratch gi (TopupGatewayConfigWords.readConfig gateway before)
        beacon divisor credentials none 0 rows = .ok out ∧
      TopupModuleCall.call hash moduleExternal
        (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
        (moduleInput out moduleId keyIndices operatorIds ctx.sender moduleAllocation before) before =
          ⟨.ok raw,afterModule,trace⟩ ∧
      TopupModuleCall.decodeReturn raw = .ok allocations ∧
      (TopupRouterContinuation.values allocations).sum ≤ (blockCap ctx.sender before).val * 10^9 ∧
      let ci := TopupModuleCall.continuationInput
        (moduleInput out moduleId keyIndices operatorIds ctx.sender moduleAllocation before) allocations
      let suffix := TopupRouterContinuation.program hash withdrawalExternal ctx depositContract ci afterModule
      result.world = suffix.world ∧ result.attempts = trace ++ suffix.attempts ∧
      (((TopupRouterContinuation.values allocations).sum = 0 ∧
        suffix = ⟨.ok (), {afterModule with logs := afterModule.logs ++
          [TopupRouterContinuation.topUpEvent ctx.sender ci 0]}, []⟩) ∨
       TopupRouterCommitted.PositiveEffects hash withdrawalExternal ctx depositContract ci afterModule suffix
         (TopupRouterContinuation.values allocations).sum) := by
  let cfg := TopupGatewayConfigWords.readConfig gateway before
  unfold run at h
  dsimp only at h
  obtain ⟨u,hc,h⟩ := bind_success h
  cases u
  obtain ⟨out,hl,h⟩ := bind_success h
  change Except.ok _ = Except.ok result at h
  cases h
  have hcount : rows.length ≤ cfg.maxValidators.val :=
    ((checkLengths_iff cfg _ _ _ _ _).mp hc).2.2.2.2.2
  obtain ⟨ns,heval,_,hlimits,_⟩ := loop_spec precompile oracle scratch gi cfg beacon divisor credentials rows none 0 out hl
  obtain ⟨raw,afterModule,trace,allocations,total,hcall,hdecode,hguard,htarget,hworld,htrace,heffects⟩ :=
    TopupRouterCommitted.module_execute_success hash moduleExternal withdrawalExternal ctx depositContract
      (moduleInput out moduleId keyIndices operatorIds ctx.sender moduleAllocation before) before hs
  have hwords : TopupRouterContinuation.values
      (moduleInput out moduleId keyIndices operatorIds ctx.sender moduleAllocation before).limits =
      TopupWeiBounds.weiLimits ns := by
    change TopupRouterContinuation.values (out.limits.map word) = _
    rw [hlimits,wei_word_values]
  obtain ⟨hguards,hsum⟩ := TopupRouterContinuation.guardSum_spec _ _ _ _ hguard
  rw [hwords] at hguards
  have he := TopupWeiBounds.router_unchecked_sum_exact cfg (rows.map fields) ns
    (TopupRouterContinuation.values allocations) (by simpa using hcount) heval hguards
  have ht : total = (TopupRouterContinuation.values allocations).sum := hsum.trans he
  refine ⟨out,raw,afterModule,trace,allocations,hl,hcall,hdecode,?_,hworld,htrace,?_⟩
  · rw [← ht]
    exact Nat.le_trans htarget (target_bound ctx.sender moduleAllocation before)
  · simpa only [ht] using heffects

/-- The genuine module reply and its decoded allocations are bounded by the
packed router cap read before the call. This covers zero totals, empty returned
allocations, arbitrary module effects and every admitted gateway configuration.
No no-wrap, exact-total, count-bound or independent limit/target premise. -/
theorem run_success_bound (hash : TopupRouterCredentials.Keccak)
    (moduleExternal withdrawalExternal : External) (precompile : Precompile)
    (oracle : RootOracle) (scratch : Fin 32 → Byte) (gi : Configuration)
    (beacon : BeaconData) (divisor : Index) (credentials : Digest)
    (gateway : Address) (ctx : Context) (depositContract : Address) (moduleId : Word)
    (keyIndices operatorIds : List Word) (rows : List Row) (moduleAllocation : Word)
    (before : World) (result : Result Unit)
    (h : run hash moduleExternal withdrawalExternal precompile oracle scratch gi beacon divisor
      credentials gateway ctx depositContract moduleId keyIndices operatorIds rows moduleAllocation before = .ok result)
    (hs : result.outcome = .ok ()) :
    ∃ out raw afterModule trace allocations,
      loop precompile oracle scratch gi (TopupGatewayConfigWords.readConfig gateway before)
        beacon divisor credentials none 0 rows = .ok out ∧
      TopupModuleCall.call hash moduleExternal
        (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
        (moduleInput out moduleId keyIndices operatorIds ctx.sender moduleAllocation before) before =
          ⟨.ok raw,afterModule,trace⟩ ∧
      TopupModuleCall.decodeReturn raw = .ok allocations ∧
      (TopupRouterContinuation.values allocations).sum ≤ (blockCap ctx.sender before).val * 10^9 := by
  obtain ⟨out,raw,afterModule,trace,allocations,hl,hcall,hdecode,hbound,_⟩ :=
    run_success_exact_effects hash moduleExternal withdrawalExternal precompile oracle scratch gi beacon divisor
      credentials gateway ctx depositContract moduleId keyIndices operatorIds rows moduleAllocation before result h hs
  exact ⟨out,raw,afterModule,trace,allocations,hl,hcall,hdecode,hbound⟩

#print axioms blockCap_packed
#print axioms target_bound
#print axioms continuation_input
#print axioms run_success_exact_effects
#print axioms run_success_bound
end LidoSRv3.Audit.Source.TopupBatchConsumer
