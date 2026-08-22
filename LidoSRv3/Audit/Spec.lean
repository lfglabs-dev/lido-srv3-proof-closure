import LidoSRv3.Audit.Common.Units

/-!
# Wave 0 frozen composition interfaces

Cross-guarantee theorems may mention only these records. They do not replace
the registered parent models, do not discharge `LinksSource`,
`freshQueueCache`, or `PerfectDepositEncoding`, and do not invent new
guarantee IDs.

Later packs refine Spec → Source → Verity. Do not compose Verity to Verity.
Do not merge ALLOC into DEPOSIT. Do not fold P-ACCOUNT-1 into supply bounds.
Do not treat P-CONSOLIDATION-ETH-1 as all SRv3 ETH.
-/

namespace LidoSRv3.Audit.Spec

open LidoSRv3.Audit.Common

/-- Allocation slice used by later deposit/top-up composition. Capacity and
amount are validator counts. ALLOC ↛ executed wei remains explicit until a
proved `LinksSource` bridge exists. -/
structure Allocation where
  moduleId : Nat
  capacity : Validators
  amount : Validators
  deriving DecidableEq, Repr

/-- Reserve spend slice. This is not P-RESERVE-RELATIONAL: two states that
differ only in `depositsReserve` keeping the same finalization observables is
the supplemental relational row. -/
structure Spend where
  amount : Wei
  deriving DecidableEq, Repr

/-- Destinations the P-CONSOLIDATION-ETH-1 parent currently classifies as
approved. Extra approved paths (pack B) and VaultHub owner withdraw stay out
of this freeze. -/
inductive ApprovedDestination
  | consolidationRequest
  | refundRecipient
  deriving DecidableEq, Repr

structure EthJournalLeg where
  dest : ApprovedDestination
  wei : Wei
  deriving DecidableEq, Repr

abbrev EthJournal := List EthJournalLeg

/-- Oracle report frame. P-ACCOUNT-1 remains order-only; fee/shareRate mint
and Eugene/module-total bounds are later oracle rows, not this interface. -/
structure OracleFrame where
  balances : List Nat
  sharesMinted : Nat
  shareRateDelta : Nat
  deriving DecidableEq, Repr

/-- Spec-plane SSZ correspondence: `verify ↔ encode(d) ∈ r`, plus witness
recovery. Deposit uniqueness is the named `PerfectDepositEncoding`
hypothesis, not this interface. SHA-256 and deployed Yul stay OPEN. -/
structure SszWitness (Deposit Witness Root : Type) where
  encode : Deposit → Root
  verify : Witness → Root → Prop
  witnessOf : Deposit → Witness

/-- Named correspondence / iff: construction binds `witnessOf d` to
`encode d`, and determination recovers that witness from any verified pair
at that root. -/
def SszWitness.Correspondence (W : SszWitness Deposit Witness Root)
    (d : Deposit) : Prop :=
  W.verify (W.witnessOf d) (W.encode d) ∧
    (∀ w r, W.verify w r → r = W.encode d → w = W.witnessOf d)

end LidoSRv3.Audit.Spec
