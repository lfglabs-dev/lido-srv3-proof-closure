import LidoSRv3.Audit.Source.NoReentry
import LidoSRv3.Audit.Guarantees.PDeposit1PhysicalLedger

/-! # P-DEPOSIT-1 under A-NO-REENTRY

`actual_physical_metadata_conserves` threads the exact worlds returned by the
pinned locator/queue/oracle/router dispatch chain and leaves the residual
interpreter `other` (module `obtainDepositData` bodies and the beacon deposit
contract) arbitrary. Under `NoReentry other [lido, router]` the ledger holds
as before and, in addition, every CALL that reaches `other` leaves Lido's and
the router's storage unchanged, never succeeds when it targets either of them,
and records no accepted nested call into them.

**Status:** corollary of the registered `actual_physical_metadata_conserves`;
the premise is the accepted assumption `A-NO-REENTRY`. -/

namespace LidoSRv3.Audit.Guarantees.PDeposit1NoReentry

open LidoSRv3.Audit.Source Source.TrioReserve1
open LidoSRv3.Audit.Source.NoReentry
open audit.trio.deposit
open audit.trio.deposit.LiveBeacon (beaconAddress)
open TopupRouterCredentials (Keccak)

theorem actual_physical_metadata_conserves_no_reentry (hash : Keccak) (k : Queue.Keccak)
    (config : Pipeline.Config) (staticOther : StaticCall.External) (other : Live.External)
    (ctx : RouterDeposit.Context) (inputs : RouterDeposit.Inputs)
    (before after : PhysicalMetadata.World) (attempts : List Live.Attempt)
    (bound : WithdrawalLedgerMinimal.LocatorBound config inputs.liveContext before.live)
    (lido_ne_router : inputs.liveContext.self ≠ inputs.liveContext.sender)
    (router_ne_beacon : inputs.liveContext.sender ≠ beaconAddress ctx)
    (hNo : NoReentry other [inputs.liveContext.self, inputs.liveContext.sender])
    (h : PhysicalMetadata.execute hash (Pipeline.external k config staticOther other) ctx inputs before =
      ⟨.ok (), after, attempts⟩) :
    (∃ prepared transcript,
      prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
        inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
        inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript) ∧
      CallSpec.Balances before.live.balances after.live.balances
        inputs.liveContext.self (beaconAddress ctx) (prepared.values.actualKeys * DEPOSIT_SIZE) ∧
      after.live.balances inputs.liveContext.sender = before.live.balances inputs.liveContext.sender ∧
      (prepared.values.actualKeys = 0 ∨ inputs.config.maxEBType1.val = DEPOSIT_SIZE)) ∧
    Confined other [inputs.liveContext.self, inputs.liveContext.sender] :=
  ⟨PDeposit1.actual_physical_metadata_conserves hash k config staticOther other ctx inputs before
      after attempts bound lido_ne_router router_ne_beacon h,
    confined_of_noReentry hNo⟩

#print axioms actual_physical_metadata_conserves_no_reentry

end LidoSRv3.Audit.Guarantees.PDeposit1NoReentry
