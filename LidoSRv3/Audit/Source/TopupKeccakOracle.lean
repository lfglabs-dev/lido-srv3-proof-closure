import LidoSRv3.Audit.Guarantees.PTopup2Verity
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

open _root_.Verity
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

/-- The allocation arrays cross the word-addressed memory boundary only.
Changing either oracle hook cannot change a `memoryArrayElement` observation;
in particular this path is not a claim about Solidity mapping-slot keccak.

Same statement as `MinFirstDistributionTx.memory_array_read_is_oracle_independent`,
for the P-TOPUP-2 `readWord` shape. -/
theorem memory_array_read_is_oracle_independent
    (oracle₁ oracle₂ : DenoteOracle) (state : ContractState) (name : String)
    (base length index : Nat) :
    readWordWith oracle₁ state name base length index =
      readWordWith oracle₂ state name base length index := by
  simp [readWordWith, evalExpr, arrayState]

theorem read_array_with_is_oracle_independent
    (oracle₁ oracle₂ : DenoteOracle) (state : ContractState) (name : String)
    (base length : Nat) :
    readArrayWith oracle₁ state name base length =
      readArrayWith oracle₂ state name base length := by
  unfold readArrayWith
  refine congrArg (List.range length).mapM ?_
  funext index
  exact memory_array_read_is_oracle_independent oracle₁ oracle₂ state name base length index

/-- The public `Topup2DistributionTx.readWord` equals the same memory lookup
under an arbitrary `DenoteOracle`. The private stub oracle is not a hidden
keccak premise. -/
theorem readWord_eq_readWordWith
    (oracle : DenoteOracle) (state : ContractState) (name : String)
    (base length index : Nat) :
    readWord state name base length index =
      readWordWith oracle state name base length index := by
  simp [readWord, readWordWith, evalExpr, arrayState]

theorem readArray_eq_readArrayWith
    (oracle : DenoteOracle) (state : ContractState) (name : String)
    (base length : Nat) :
    readArray state name base length =
      readArrayWith oracle state name base length := by
  unfold readArray readArrayWith
  refine congrArg (List.range length).mapM ?_
  funext index
  exact readWord_eq_readWordWith oracle state name base length index

/-- `.keccak256` is exactly the oracle hook. This is the arm the parent does
not take. -/
theorem evalKeccak_eq (oracle : DenoteOracle) (state : ContractState) (off size : Nat) :
    evalKeccak oracle state off size =
      some (oracle.keccakMemorySlice state.memory (wordNormalize off) (wordNormalize size)) := by
  simp [evalKeccak, evalExpr]

theorem zero_and_nonzero_disagree_on_keccak (state : ContractState) (off size : Nat) :
    evalKeccak zeroKeccakOracle state off size ≠
      evalKeccak nonzeroKeccakOracle state off size := by
  simp [evalKeccak_eq, zeroKeccakOracle, nonzeroKeccakOracle]

/-- Kill-line: agreement on every `memoryArrayElement` observation does not
imply agreement on `.keccak256`. The public P-TOPUP-2 Verity parent only
reads `memoryArrayElement`. -/
theorem memory_array_agreement_does_not_imply_keccak_agreement :
    ¬ (∀ (o1 o2 : DenoteOracle) (state : DenoteState),
        (∀ name idx,
          evalExpr o1 [] state (.memoryArrayElement name (.literal idx)) =
            evalExpr o2 [] state (.memoryArrayElement name (.literal idx))) →
        (∀ off size,
          evalExpr o1 [] state (.keccak256 (.literal off) (.literal size)) =
            evalExpr o2 [] state (.keccak256 (.literal off) (.literal size)))) := by
  intro h
  let state : DenoteState := { world := defaultState, bindings := [] }
  have hmem : ∀ name idx,
      evalExpr zeroKeccakOracle [] state (.memoryArrayElement name (.literal idx)) =
        evalExpr nonzeroKeccakOracle [] state (.memoryArrayElement name (.literal idx)) := by
    intro name idx
    simp [evalExpr]
  have hk := h zeroKeccakOracle nonzeroKeccakOracle state hmem 0 32
  simp [evalExpr, zeroKeccakOracle, nonzeroKeccakOracle] at hk

/-- The registered parent restated with an arbitrary oracle on the decode
premises. Equivalent to `verity_tx_simulates_topup2_spec` because
`readArray = readArrayWith oracle` for every oracle. The keccak hook remains
unconstrained. -/
theorem verity_tx_simulates_topup2_spec_any_oracle
    (oracle : DenoteOracle)
    (effective pending requested topUpLimits : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word)
    (state : ContractState)
    (hEff : readArrayWith oracle state "effective" effectiveBase effective.length =
      some effective)
    (hPend : readArrayWith oracle state "pending" pendingBase pending.length =
      some pending)
    (hReq : readArrayWith oracle state "requested" requestedBase requested.length =
      some requested)
    (hLimits : readArrayWith oracle state "topUpLimits" limitsBase topUpLimits.length =
      some topUpLimits)
    (hLen : effective.length = pending.length ∧ pending.length = requested.length ∧
      requested.length = topUpLimits.length)
    (hMax : requested.length ≤ maxValidatorsPerTopUp) :
    observe (List.replicate requested.length 0) remainingCap
        ((allocate requested.length target minTopUp remainingCap moduleLimit valueGwei).run
          state) =
      sourceView effective pending requested topUpLimits
        target minTopUp remainingCap moduleLimit valueGwei := by
  refine LidoSRv3.Audit.Guarantees.PTopup2.verity_tx_simulates_topup2_spec
    effective pending requested topUpLimits target minTopUp remainingCap moduleLimit
    valueGwei state ?_ ?_ ?_ ?_ hLen hMax
  · simpa [readArray_eq_readArrayWith oracle] using hEff
  · simpa [readArray_eq_readArrayWith oracle] using hPend
  · simpa [readArray_eq_readArrayWith oracle] using hReq
  · simpa [readArray_eq_readArrayWith oracle] using hLimits

#print axioms memory_array_read_is_oracle_independent
#print axioms read_array_with_is_oracle_independent
#print axioms readWord_eq_readWordWith
#print axioms readArray_eq_readArrayWith
#print axioms evalKeccak_eq
#print axioms zero_and_nonzero_disagree_on_keccak
#print axioms memory_array_agreement_does_not_imply_keccak_agreement
#print axioms verity_tx_simulates_topup2_spec_any_oracle

end LidoSRv3.Audit.Source.TopupKeccakOracle
