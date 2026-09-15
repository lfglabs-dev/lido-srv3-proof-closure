import LidoSRv3.Tests.DepositDsmCall

namespace LidoSRv3.Tests.DepositAllocation
set_option maxRecDepth 16384
open LidoSRv3.Audit.Source TrioReserve1 audit.trio.deposit
open audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest

/-- Reuse the explicitly colliding test hash; the registered parent uses real
Keccak. One physical count row is enough to expose the real underflow path. -/
def initial : Live.World :=
  let core := DepositDsmCall.before.core.writeContractSlot
    liveCtx.sender.val (TopupRouterCredentials.routerRoot+1) (Live.word 1)
  {DepositDsmCall.before with core := core}
def badSummary : TrioAlloc1.StaticOracle := fun _ _ => .returned
  (TrioAlloc1.encodeWord (sw 1) ++ TrioAlloc1.encodeWord (sw 0) ++ TrioAlloc1.encodeWord (sw 0))
def cfg : TrioAlloc1.Config := ⟨sw DEPOSIT_SIZE,sw (2048*10^18)⟩
def execute (c : RouterDeposit.Context := DepositDsmCall.supplied) :=
  LidoSRv3.Audit.Source.DepositAllocation.execute DepositDsmCall.query DepositDsmCall.locator
    DepositDsmCall.cursor hash badSummary cfg (sw DEPOSIT_SIZE) reject reject c liveCtx input initial

/-- A nonzero supplied selected amount cannot bypass actual allocation failure.
No obtainDepositData or downstream value CALL occurs after the bad summary. -/
theorem allocation_failure_blocks_module :
    (execute).outcome = .error (.bubbled (Live.encode 4 0x4e487b71 ++ Live.encode 32 0x11)) ∧
    (execute).attempts = [] ∧ (execute).allocationAttempts.length = 1 := by decide +kernel

theorem unauthorized_precedes_allocation :
    (execute {DepositDsmCall.supplied with caller := ⟨8,by decide⟩}).outcome =
      .error (.reason "NotAuthorized") ∧
    (execute {DepositDsmCall.supplied with caller := ⟨8,by decide⟩}).allocationAttempts = [] := by
  decide +kernel

/-- Separated fixture locations, not a production hash/deployment claim. -/
def separatedHash : TopupRouterCredentials.Keccak := fun bytes =>
  if bytes.length = 32 then Live.word 100
  else if bytes = Live.encode 32 input.moduleId.val ++ Live.encode 32 (TopupRouterCredentials.routerRoot+2)
    then Live.word 80 else Live.word 90

def positiveWorld : Live.World :=
  let core := initial.core.writeContractSlot 2 80 (Live.word 1)
  let core := core.writeContractSlot 2 100 (Live.word input.moduleId.val)
  let core := core.writeContractSlot 2 90 (Live.word (40+10000*2^192))
  {initial with core := core}
def honest : TrioAlloc1.StaticOracle := fun _ _ => .returned
  (TrioAlloc1.encodeWord (sw 0) ++ TrioAlloc1.encodeWord (sw 0) ++ TrioAlloc1.encodeWord (sw 1))

/-- Zero supplied selected is overwritten by the executed one-validator
allocation. The real module CALL requests one key and consumes its empty reply. -/
private def checkProducedAllocation : IO Unit := do
  let result := LidoSRv3.Audit.Source.DepositAllocation.execute
    DepositDsmCall.query DepositDsmCall.locator DepositDsmCall.cursor separatedHash honest cfg
    (sw DEPOSIT_SIZE) (answer (ModuleCall.encodeReturn [] [])) reject
    DepositDsmCall.supplied liveCtx {input with selected := sw 0} positiveWorld
  match result.outcome with
  | .error reason => throw (IO.userError s!"unexpected deposit failure: {repr reason}")
  | .ok () =>
    unless result.attempts.map (fun a => a.request.payload) = [ModuleCall.payload 1 input.depositCalldata] do
      throw (IO.userError "allocation did not feed actual module CALL")
    unless result.allocationAttempts.length = 1 do
      throw (IO.userError "missing executed allocation summary call")
#eval checkProducedAllocation

/-- Malformed successful STATICCALL bytes fail in the allocation decoder. They
cannot be mistaken for a zero allocation or reach an otherwise accepting module. -/
def malformedSummary : TrioAlloc1.StaticOracle := fun _ _ => .returned []

def malformedExecution := LidoSRv3.Audit.Source.DepositAllocation.execute
  DepositDsmCall.query DepositDsmCall.locator DepositDsmCall.cursor separatedHash malformedSummary cfg
  (sw DEPOSIT_SIZE) (answer (ModuleCall.encodeReturn [] [])) reject
  DepositDsmCall.supplied liveCtx input positiveWorld

theorem malformed_summary_blocks_module :
    malformedExecution.outcome = .error .empty ∧
    malformedExecution.attempts = [] ∧
    malformedExecution.allocationAttempts.length = 1 := by decide +kernel

/-- The registered parent's new conjunct is universal in callbacks and World;
this specialization checks that the parent actually exports terminality. -/
example (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (oracle : TrioAlloc1.StaticOracle) (config : TrioAlloc1.Config) (available : TrioAlloc1.Word)
    (m w : Live.External) (ctx : RouterDeposit.Context) (liveCtx : Live.Context)
    (i : ModuleCall.Input) (before : Live.World) :
    LidoSRv3.Audit.Source.DepositAllocation.AllocationFailureStops q locator cursor
      LidoSRv3.Audit.Guarantees.PDeposit1.depositPhysicalKeccak oracle config available
      m w ctx liveCtx i before :=
  ((LidoSRv3.Audit.Guarantees.PDeposit1.actual_deposit_call_slot_success_and_revert
    q locator cursor m w ctx liveCtx i before).2 oracle config available).2

#print axioms allocation_failure_blocks_module
#print axioms unauthorized_precedes_allocation
end LidoSRv3.Tests.DepositAllocation
