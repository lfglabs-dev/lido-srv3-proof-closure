import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Guarantees.PAlloc2
import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Verity.DepositParentTx
import LidoSRv3.Audit.Verity.DepositNFrameTx
import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Audit.Guarantees.PAccount1
import LidoSRv3.Audit.Guarantees.PReserve1
import LidoSRv3.Audit.Guarantees.PConsolidationEth1
import LidoSRv3.Audit.Guarantees.PAddress1
import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Verity.Topup2Tx
import LidoSRv3.Audit.Guarantees.PConsolidation1
import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Guarantees.PReserveRelationalVerity
import LidoSRv3.Audit.Guarantees.PAllocExec1
import LidoSRv3.Audit.Guarantees.PEthJournal1
import LidoSRv3.Audit.Guarantees.PVaultEth1
import LidoSRv3.Audit.Guarantees.POracleSupply1
import LidoSRv3.Audit.Guarantees.PAddressBatch1
import LidoSRv3.Audit.Guarantees.PSszLive1
import LidoSRv3.Audit.Guarantees.PConsolidationValue1
import LidoSRv3.Audit.Guarantees.PToken1

/-!
# Canonical minimal-11 public facade

`all` is deliberately the complete public surface. Its checked layers cover
the existing abstract model, Verity Lean library, and Verity Executable
Contract evidence; empty entries are intentional blockers, not omitted proofs.
-/

namespace LidoSRv3.Audit.Guarantees

def all : List Guarantee :=
  [ PAlloc1.guarantee
  , PAlloc2.guarantee
  , PDeposit1.guarantee
  , PTopup1.guarantee
  , PAccount1.guarantee
  , PReserve1.guarantee
  , PConsolidationEth1.guarantee
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
     "P-RESERVE-1", "P-CONSOLIDATION-ETH-1", "P-ADDRESS-1", "P-TOPUP-2",
     "P-CONSOLIDATION-1", "P-SSZ-1"] := by decide

/-- Retracted transaction claims stay blocked; P-DEPOSIT-1, P-TOPUP-1 and
P-ACCOUNT-1 now include the composed faithful Verity transaction layer. -/
example : PDeposit1.guarantee.checkedLayers = [.model, .abstractTx, .source, .verityTx] := by decide
example : PTopup1.guarantee.checkedLayers = [.model, .abstractTx, .source, .verityTx] := by decide
example : PAccount1.guarantee.checkedLayers = [.model, .source, .verityTx] := by decide

/-- P-DEPOSIT-1's `.verityTx` layer is carried by the universal list-batch
composition over one shared source/executable quantifier scope. -/
example := @PDeposit1.NFrame.verity_tx_composes_nframe_deposit

example : LidoSRv3.Audit.Verity.DepositParentTx.Preconditions
    LidoSRv3.Audit.Verity.DepositParentTx.canonicalInputs
    LidoSRv3.Audit.Verity.DepositParentTx.canonicalState :=
  PDeposit1.canonical_composition_witness.2.1

/-- Supplemental rows do not alter the immutable minimal-11 public facade. -/
def supplemental : List Guarantee :=
  [ PReserveRelational.guarantee
  , PAllocExec1.guarantee
  , PEthJournal1.guarantee
  , PVaultEth1.guarantee
  , POracleSupply1.guarantee
  , PAddressBatch1.guarantee
  , PSszLive1.guarantee
  , PConsolidationValue1.guarantee
  , PToken1.guarantee
  ]

/-- Regression guard: supplemental IDs stay out of the public facade. -/
example : supplemental.map (fun guarantee => guarantee.id.text) =
    ["P-RESERVE-RELATIONAL", "P-ALLOC-EXEC-1", "P-ETH-JOURNAL-1",
     "P-VAULT-ETH-1", "P-ORACLE-SUPPLY-1", "P-ADDRESS-BATCH-1", "P-SSZ-LIVE-1",
     "P-CONSOLIDATION-VALUE-1", "P-TOKEN-1"] := by decide

end LidoSRv3.Audit.Guarantees
