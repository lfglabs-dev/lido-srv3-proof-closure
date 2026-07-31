/-!
# Minimal-11 public guarantee registry

This is an interface registry, not a proof-progress registry.  A nonempty
`checkedLayers` list names only the Lean evidence already declared by the
campaign registry; an empty list deliberately does not manufacture a theorem.
-/

namespace LidoSRv3.Audit.Guarantees

inductive Id
  | pAlloc1 | pAlloc2 | pDeposit1 | pTopup1 | pAccount1 | pReserve1
  | pEth1 | pAddress1 | pTopup2 | pConsolidation1 | pSsz1
  deriving DecidableEq, Repr

def Id.text : Id → String
  | .pAlloc1 => "P-ALLOC-1"
  | .pAlloc2 => "P-ALLOC-2"
  | .pDeposit1 => "P-DEPOSIT-1"
  | .pTopup1 => "P-TOPUP-1"
  | .pAccount1 => "P-ACCOUNT-1"
  | .pReserve1 => "P-RESERVE-1"
  | .pEth1 => "P-ETH-1"
  | .pAddress1 => "P-ADDRESS-1"
  | .pTopup2 => "P-TOPUP-2"
  | .pConsolidation1 => "P-CONSOLIDATION-1"
  | .pSsz1 => "P-SSZ-1"

inductive CheckedLayer
  | model
  | abstractTx
  deriving DecidableEq, Repr

structure Guarantee where
  id : Id
  checkedLayers : List CheckedLayer

end LidoSRv3.Audit.Guarantees
