import LidoSRv3.Audit.Verity.TopupFundedSourceTx
import LidoSRv3.Tests.TopupLiveWithdrawalMutants

namespace LidoSRv3.Tests.TopupFundedSourceMutants
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Verity TopupTx TopupFundedSourceTx
open TrioReserve1 Live
namespace Fixture
open LidoSRv3.Tests.TopupLiveWithdrawalMutants

def ether : Nat := 10^18
def key (b : Nat) : List Nat := b :: List.replicate 47 0
def call : TopupCall :=
  ⟨3 * ether, List.replicate 32 0, 2, [key 1, key 9, key 2], [0, 1, 2],
    [0, 0, 0], [ether, 0, 2 * ether], [ether, 0, 2 * ether]⟩
theorem wellFormed : SourceTopupCallWellFormed call := by decide

def funded : World := { before with
  core := before.core.writeContractSlot 1 bufferSlot (word (100 * ether))
  balances := fun a => if a = address 1 then 100 * ether else if a = address 2 then 7 else 11 }
def result := TopupFundedSourceTx.execute LidoSRv3.Tests.TopupLiveWithdrawalMutants.external context pinnedConfig call wellFormed funded

end Fixture
open Fixture LidoSRv3.Tests.TopupLiveWithdrawalMutants
set_option maxRecDepth 8192
set_option maxHeartbeats 1000000

/-- Positive end-to-end caller-side composition, with old router funds. -/
example : result.outcome = .ok () := by rfl
example : result.world.balances (address 1) = 97 * ether ∧
    result.world.balances (address 2) = 7 := by decide
example : (result.world.core.calls.map (·.value)) = [ether, 2 * ether] := by rfl

/-- Two actual public keys survive the zero skip; no scheduled IDs replace
their leading ABI word. The opaque source-derived digest remains in calldata. -/
example : (result.world.core.calls.map (fun c => c.calldata[6]?)) =
    [some (256^31), some (2 * 256^31)] := by rfl
example : (result.world.core.calls.map (fun c => c.calldata[0]?)) =
    [some 0x22895118, some 0x22895118] := by rfl
example : (result.world.core.calls.map (fun c => c.calldata[5]?)) =
    [some 48, some 48] := by rfl

/-- The core caller balance is read from the real ledger, not its stale local
field; both agree again after the actual loop debit. -/
example : funded.core.selfBalance.val = 0 ∧
    result.world.core.selfBalance.val = result.world.balances (address 2) := by decide

/-- Existing event and seed behavior from the concrete withdrawal survives. -/
example : (result.world.core.readContractSlot 1 seedSlot).val = 9 := by decide
example : result.attempts.getLast?.map (fun a => a.request.value.val) = some (3 * ether) := by decide

def badCall : TopupCall := { Fixture.call with moduleReturndata := [ether, 1, 2 * ether] }
theorem badWellFormed : SourceTopupCallWellFormed badCall := by decide
def failed := TopupFundedSourceTx.execute LidoSRv3.Tests.TopupLiveWithdrawalMutants.external context pinnedConfig badCall badWellFormed funded

/-- A real late minimum-deposit guard fails after withdrawal and one push;
the outer snapshot restores both account balances and the committed journal. -/
example : failed.outcome = .error (.reason "DepositAmountTooLow") := by rfl
example : failed.world.balances (address 1) = 100 * ether ∧
    failed.world.balances (address 2) = 7 ∧ failed.world.core.calls = [] := by
  constructor
  · rfl
  · constructor <;> rfl

def wrapCall : TopupCall := { Fixture.call with
  pubkeys := [key 1, key 2]
  moduleReturndata := [2^256 - 1, 1] }
theorem wrapWellFormed : SourceTopupCallWellFormed wrapCall := by decide

/-- The old wrapped-zero domain remains present; no amount/guard assertion
silently changes it into a positive withdrawal or a beacon loop. -/
example : allocSum wrapCall.moduleReturndata = 2^256 ∧
    allocSumUnchecked wrapCall.moduleReturndata = 0 := by decide
example : TopupFundedSourceTx.execute reject context pinnedConfig wrapCall wrapWellFormed funded =
    ⟨.ok (), funded, []⟩ := wrapped_zero reject context pinnedConfig wrapCall wrapWellFormed funded (by decide)

/-- A natural-number balance at 2^256 cannot round-trip through a uint256
caller view. This rejects an unrestricted ledger/projection theorem. -/
example : (project (address 2) {funded with balances := fun _ => 2^256}).selfBalance.val = 0 := by decide

end LidoSRv3.Tests.TopupFundedSourceMutants

#print axioms LidoSRv3.Audit.Source.TopupFundedSource.loop_run
#print axioms LidoSRv3.Audit.Source.TopupFundedSource.journal_value
#print axioms LidoSRv3.Audit.Source.TopupFundedSource.gateway_sum_exact
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.ledger_roundtrip
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.gateway_projection_bound
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.positive_conservation
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.wrapped_zero
#print axioms LidoSRv3.Audit.Verity.TopupFundedSourceTx.failure_restores
