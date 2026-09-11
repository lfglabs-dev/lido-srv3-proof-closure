import LidoSRv3.Audit.Verity.Topup2DistributionTx
import Verity.Core.Model.Denote

/-!
P-TOPUP-2 keccak memory-array oracle boundary.

The registered Verity parent `PTopup2.verity_tx_simulates_topup2_spec`
decodes its four input arrays through `readArray` → `readWord` →
`evalExpr (.memoryArrayElement ...)`. That arm is a direct word-addressed
memory read (`Verity.Core.Model.Denote` 634–640). It does not call
`DenoteOracle.keccakMemorySlice`. The keccak hook is used only by
`.keccak256` (`Denote` 991–994).

The private stub in `Topup2DistributionTx`
(`keccakMemorySlice := fun _ _ _ => 0`) is therefore unused by the parent.
This file makes that boundary a theorem rather than a fidelity note. It
does **not** close the keccak gap: Solidity mapping-slot keccak and any
`.keccak256` expression remain unmodeled.

Additive lot: no existing Lean, registry, Trust, or import-DAG file is edited.
-/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupKeccakOracle

open Verity
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open LidoSRv3.Audit.Verity.Topup2DistributionTx

/-- Same dummy mapping hook as `Topup2DistributionTx`'s private oracle;
keccak always returns 0. -/
def zeroKeccakOracle : DenoteOracle where
  mappingSlot := fun _ _ => 0
  keccakMemorySlice := fun _ _ _ => 0

/-- Differs from `zeroKeccakOracle` only on `keccakMemorySlice`. -/
def nonzeroKeccakOracle : DenoteOracle where
  mappingSlot := fun _ _ => 0
  keccakMemorySlice := fun _ _ _ => 1

/-- Public analogue of `Topup2DistributionTx.readWord` with an explicit oracle. -/
def readWordWith (oracle : DenoteOracle) (state : ContractState) (name : String)
    (base length index : Nat) : Option Word :=
  (evalExpr oracle [] (arrayState state name base length)
    (.memoryArrayElement name (.literal index))).map Verity.Core.Uint256.ofNat

def readArrayWith (oracle : DenoteOracle) (state : ContractState) (name : String)
    (base length : Nat) : Option (List Word) :=
  (List.range length).mapM (readWordWith oracle state name base length)

/-- `.keccak256` denotation; this is the arm that *does* consult the oracle. -/
def evalKeccak (oracle : DenoteOracle) (state : ContractState) (off size : Nat) :
    Option Nat :=
  evalExpr oracle [] { world := state, bindings := [] }
    (.keccak256 (.literal off) (.literal size))

end LidoSRv3.Audit.Source.TopupKeccakOracle
