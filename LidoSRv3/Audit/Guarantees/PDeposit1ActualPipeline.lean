import audit.trio.deposit.LiveBeaconCommitted

/-! P-DEPOSIT-1 current source consumer. The historical public theorem pair is
retained. This source result consumes actual Lido and beacon ledger effects;
physical allocation/module-prefix and metadata-order correspondence remain open. -/
namespace LidoSRv3.Audit.Guarantees.PDeposit1
open audit.trio.deposit audit.trio.deposit.LiveBeacon
open LidoSRv3.Audit.Source LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TopupBeaconCallee

/-- Successful modeled deposit execution preserves pointwise ETH accounting
from Lido to beacon. A nonempty success derives the configured 32-ether amount
from the actual withdrawal/beacon calls and the final router balance assertion.
It assumes only the existing source pipeline binding and distinct roles shown
below; no funding, prepared transcript, capacity or per-key amount premise. -/
theorem actual_live_pipeline_conservation (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : Live.External)
    (ctx : RouterDeposit.Context) (inputs : RouterDeposit.Inputs)
    (before after : World) (attempts : List Live.Attempt)
    (bound : Pipeline.Bound config inputs.liveContext before.live)
    (lido_ne_router : inputs.liveContext.self ≠ inputs.liveContext.sender)
    (router_ne_beacon : inputs.liveContext.sender ≠ beaconAddress ctx)
    (h : execute (Pipeline.external k config staticOther other) ctx inputs before =
      ⟨.ok (), after, attempts⟩) :
    ∃ prepared transcript,
      prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
        inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
        inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript) ∧
      CallSpec.Balances before.live.balances after.live.balances
        inputs.liveContext.self (beaconAddress ctx) (prepared.values.actualKeys * DEPOSIT_SIZE) ∧
      (prepared.values.actualKeys = 0 ∨ inputs.config.maxEBType1.val = DEPOSIT_SIZE) :=
  audit.trio.deposit.LiveBeaconCommitted.execute_pipeline_success_conservation
    k config staticOther other ctx inputs before after attempts bound lido_ne_router router_ne_beacon h

#print axioms actual_live_pipeline_conservation
end LidoSRv3.Audit.Guarantees.PDeposit1
