import audit.trio.deposit.PhysicalMetadataLedger
import LidoSRv3.Audit.Guarantees.PDeposit1PhysicalMetadata

namespace LidoSRv3.Audit.Guarantees.PDeposit1
open LidoSRv3.Audit.Source Source.TrioReserve1
open audit.trio.deposit
open audit.trio.deposit.LiveBeacon (beaconAddress)
open TopupRouterCredentials (Keccak)

/-- The executed physical metadata writes/event and same-world withdrawal/beacon
calls now compose to the exact Lido-to-beacon ledger and restored router balance.
Only the existing physical locator binding and two distinct role conditions remain;
no oracle-pointer/code-presence or supplied successful-stage conditions are added. -/
theorem actual_physical_metadata_conserves (hash : Keccak) (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : Live.External)
    (ctx : RouterDeposit.Context) (inputs : RouterDeposit.Inputs)
    (before after : PhysicalMetadata.World) (attempts : List Live.Attempt)
    (bound : WithdrawalLedgerMinimal.LocatorBound config inputs.liveContext before.live)
    (lido_ne_router : inputs.liveContext.self ≠ inputs.liveContext.sender)
    (router_ne_beacon : inputs.liveContext.sender ≠ beaconAddress ctx)
    (h : PhysicalMetadata.execute hash (Pipeline.external k config staticOther other) ctx inputs before =
      ⟨.ok (), after, attempts⟩) :
    ∃ prepared transcript,
      prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
        inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
        inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript) ∧
      CallSpec.Balances before.live.balances after.live.balances
        inputs.liveContext.self (beaconAddress ctx) (prepared.values.actualKeys * DEPOSIT_SIZE) ∧
      after.live.balances inputs.liveContext.sender = before.live.balances inputs.liveContext.sender ∧
      (prepared.values.actualKeys = 0 ∨ inputs.config.maxEBType1.val = DEPOSIT_SIZE) :=
  PhysicalMetadataLedger.execute_success_conservation hash k config staticOther other
    ctx inputs before after attempts bound lido_ne_router router_ne_beacon h

#print axioms actual_physical_metadata_conserves
end LidoSRv3.Audit.Guarantees.PDeposit1
