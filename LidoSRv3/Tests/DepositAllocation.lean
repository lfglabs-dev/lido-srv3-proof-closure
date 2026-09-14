import LidoSRv3.Tests.DepositDsmCall

namespace LidoSRv3.Tests.DepositAllocation
set_option maxRecDepth 16384
open LidoSRv3.Audit.Source TrioReserve1 audit.trio.deposit
open audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest

/-- Reuse the explicitly colliding test hash; the registered parent uses real
Keccak. One physical count row is enough to expose the real underflow path. -/
def initial : Live.World :=
  {DepositDsmCall.before with core := DepositDsmCall.before.core.writeContractSlot
    liveCtx.sender.val (TopupRouterCredentials.routerRoot+1) (Live.word 1)}
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

#print axioms allocation_failure_blocks_module
#print axioms unauthorized_precedes_allocation
end LidoSRv3.Tests.DepositAllocation
