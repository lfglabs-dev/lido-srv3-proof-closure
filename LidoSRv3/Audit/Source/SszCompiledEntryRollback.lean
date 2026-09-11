import LidoSRv3.Audit.Source.SszCompiledClEntry
import LidoSRv3.Audit.Guarantees.PSsz1CompiledClEntry

/-!
Rollback of the selected compiled CL entry
(`SszRootCallHarness.verify` → `_verifyValidator`,
`CLValidatorVerifier.sol:44-57`, selector `0x2e77b4ba`,
IR `inspected-cl-entry-ir.yul` 43-417).

`PSsz1.actual_compiled_cl_entry_tree` already relates one successful
`SszCompiledClEntry.run` to its root, index, leaf and proof loop. This
file is the complementary error arm: a proof-loop or root-comparison
failure produces no committed `EVM.State`, hence no committed storage
write, event, returned memory or value. Success and that failure share
the definitional prefix `beforeRoot` then `rootCall` (EIP-4788 read,
decode, leaf inputs from calldata).

EIP-4788 authenticity/freshness remain declared premises. Compilation,
crypto, gas and consensus stay outside. Additive: no existing file is
edited.
-/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.SszCompiledEntryRollback

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source.SszCompiledClEntry
open LidoSRv3.Audit.Source.TrioReserve1

/-- Committed post-state of the compiled entry, if any. An error outcome
has none. -/
def committedState (r : Result) : Option EVM.State :=
  match r.outcome with
  | .ok st => some st
  | .error _ => none

/-- Proof-loop (`SSZ.verifyProof`, IR after 332) or root-comparison
(`decodeRoot`, IR 146-166 / `_getParentBlockRoot` 103-107) failure. -/
def Error.isProofOrRoot : Error → Prop
  | .proof _ => True
  | .reply _ => True
  | _ => False

end LidoSRv3.Audit.Source.SszCompiledEntryRollback
