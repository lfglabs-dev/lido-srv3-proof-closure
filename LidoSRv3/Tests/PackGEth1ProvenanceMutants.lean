import LidoSRv3.Audit.Provenance.ConsolidationRequest
import LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-!
# Pack G-ETH1 fail-closed vectors

A mutant rewrite that maps ensemble 5 to `0xDEAD` is not the canonical
observe rewrite. `A-CANONICAL-REQUEST-ADDRESS` stays OPEN. The registered
Verity parent is unchanged and still journals ensemble 5.
-/

namespace LidoSRv3.Tests.PackGEth1ProvenanceMutants

open LidoSRv3.Audit.Provenance.ConsolidationRequest
open LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-- Mutant observe rewrite: ensemble 5 maps to `0xDEAD`, not the canonical
EIP-7251 predeploy. -/
def rewriteToDead (addr : Nat) : Nat :=
  if addr = ensembleRequestAddr then 0xDEAD else addr

/-- Kill-line: the dead rewrite is not the canonical rewrite at ensemble 5. -/
theorem dead_rewrite_kill_line_refutes_canonical_rewrite :
    rewriteToDead ensembleRequestAddr ≠
      rewriteToCanonical ensembleRequestAddr ∧
      rewriteToDead ensembleRequestAddr = 0xDEAD ∧
      rewriteToCanonical ensembleRequestAddr = canonicalRequestAddress := by
  decide

/-- The mutant function is not `rewriteToCanonical`. -/
theorem dead_rewrite_is_not_canonical_rewrite :
    rewriteToDead ≠ rewriteToCanonical := by
  intro h
  have h5 := congrArg (fun f => f ensembleRequestAddr) h
  exact dead_rewrite_kill_line_refutes_canonical_rewrite.1 h5

/-- Honest rewrite still maps ensemble 5 to the parent pin. -/
example :
    rewriteToCanonical ensembleRequestAddr = canonicalRequestAddress :=
  rewrite_maps_ensemble_to_canonical

end LidoSRv3.Tests.PackGEth1ProvenanceMutants
