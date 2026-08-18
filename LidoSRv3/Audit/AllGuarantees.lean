import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Guarantees.PAlloc2
import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Verity.DepositParentTx
import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Audit.Guarantees.PAccount1
import LidoSRv3.Audit.Guarantees.PReserve1
import LidoSRv3.Audit.Guarantees.PEth1
import LidoSRv3.Audit.Guarantees.PAddress1
import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Verity.Topup2Tx
import LidoSRv3.Audit.Guarantees.PConsolidation1
import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Guarantees.PDeref1

/-!
# Canonical minimal-11 public facade

`all` is deliberately the complete public surface. Its checked layers cover
the existing MODEL, ALG, SOURCE, and bounded Verity-transaction evidence; empty entries are
intentional blockers, not omitted proofs.
-/

namespace LidoSRv3.Audit.Guarantees

def all : List Guarantee :=
  [ PAlloc1.guarantee
  , PAlloc2.guarantee
  , PDeposit1.guarantee
  , PTopup1.guarantee
  , PAccount1.guarantee
  , PReserve1.guarantee
  , PEth1.guarantee
  , PAddress1.guarantee
  , PTopup2.guarantee
  , PConsolidation1.guarantee
  , PSsz1.guarantee
  ]

/-- Regression guard: changing the public count requires an intentional review. -/
example : all.length = 11 := by decide

/-- Regression guard: the public IDs and their order are the campaign's canonical 11. -/
example : all.map (fun guarantee => guarantee.id.text) =
    ["P-ALLOC-1", "P-ALLOC-2", "P-DEPOSIT-1", "P-TOPUP-1", "P-ACCOUNT-1",
     "P-RESERVE-1", "P-ETH-1", "P-ADDRESS-1", "P-TOPUP-2",
     "P-CONSOLIDATION-1", "P-SSZ-1"] := by decide

/-- Retracted transaction claims stay blocked; P-DEPOSIT-1 and P-ACCOUNT-1 now
include the composed faithful Verity transaction layer. -/
example : PDeposit1.guarantee.checkedLayers = [.model, .abstractTx, .source, .verityTx] := by decide
example : PTopup1.guarantee.checkedLayers = [.model, .abstractTx, .source] := by decide
example : PAccount1.guarantee.checkedLayers = [.model, .source, .verityTx] := by decide

/-- P-DEPOSIT-1's `.verityTx` layer is carried by a theorem that shares its
variables across both planes rather than by a conjunction of two unrelated
facts: the source configuration/input, the transaction input and the entry
`ContractState` are quantified once and linked by `LinksSource`.  Naming both
the composition and its non-vacuity witness here keeps the aggregate surface
honest if either is ever weakened. -/
example := @PDeposit1.verity_tx_composes_deposit_conservation_and_rollback

example : LidoSRv3.Audit.Verity.DepositParentTx.Preconditions
    LidoSRv3.Audit.Verity.DepositParentTx.canonicalInputs
    LidoSRv3.Audit.Verity.DepositParentTx.canonicalState :=
  PDeposit1.canonical_composition_witness.2.1

/-- Supplemental rows do not alter the immutable minimal-11 public facade. -/
def supplemental : List Guarantee := [PDeref1.guarantee]

end LidoSRv3.Audit.Guarantees
