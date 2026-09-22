import LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel
import LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-! Compose the shared derived-fuel result with the explicit Bus ceiling.
The underlying dispatcher and its proofs are defined once in the imported
Verity module, so both entry points can coexist in the trust environment. -/
namespace LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel

open _root_.Verity
open _root_.Verity.MultiContract
open LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx
open LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversal

/-! ## General-rule composition (Thomas 2026-09-12): batchSize under mainnet Bus ceiling

The registered Verity parent's exhaustion arm at `batchSize ≥ 29`
(chantier 5 disclosed) is a `fuelBudget = 32` frame-count artifact
of the abstract dispatcher — the mainnet Bus `batchSize` ceiling is
200, so batches of 29-199 that exhaust the model DO commit on chain.

Under the general rule (Thomas 2026-09-12): name the pinned Bus
ceiling as an explicit premise, and prove that under it the derived-
fuel success arm holds for any admitted `batchSize`. The composition
below is the derived consumer that fires under the mainnet Bus
ceiling; the model's `fuelBudget = 32` artifact remains disclosed as
a scope narrowing in `fidelity.missing`. -/

/-- The pinned mainnet ConsolidationBus `batchSize` ceiling. Sourced
from the deployed Bus contract's per-transaction limit (documented
in `audit/eth1-unbounded-fuel/README.md` alongside grok #410). -/
def mainnetBusBatchCeiling : Nat := 200

/-- **General-rule composition (Thomas 2026-09-12): derived-fuel
success under mainnet Bus batchSize ceiling.**

The chantier 5 grok #410 consumer
`verity_tx_success_shape_unbounded` proves success at derived fuel
`batchSize + 4` for any word-sized batch. Under the pinned
`mainnetBusBatchCeiling = 200`, `batchSize + 4 ≤ 204`, so the derived
fuel is a small constant — matching what the mainnet Bus admits in a
single transaction. The registered parent's `fuelBudget = 32`
artifact contradicts this ceiling (200 ≫ 28); the composition below
names the real bound the code imposes and delivers success under it. -/
theorem verity_tx_success_at_derived_fuel_under_bus_ceiling
    (mv n fee : Nat)
    (_hBusCeiling : n ≤ mainnetBusBatchCeiling)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv) :
    observe (runWithFuel (n + 4) honest mv n fee) = successShape mv n fee :=
  verity_tx_success_shape_unbounded mv n fee hpos hmv hnM hfee hnf hle

end LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel

#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.verity_tx_success_shape_unbounded
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.registered_parent_is_instance_at_32
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.registered_parent_recovered_at_32
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.unbounded_covers_funded_batch_29
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.truncated_fuel_batchSize_plus_three_exhausted
#print axioms LidoSRv3.Audit.Verity.ConsolidationEthUnboundedFuel.truncated_fuel_batchSize_plus_three_refuses_success
