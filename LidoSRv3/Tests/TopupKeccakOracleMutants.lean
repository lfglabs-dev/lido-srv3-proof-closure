import LidoSRv3.Audit.Source.TopupKeccakOracle
import LidoSRv3.Audit.Guarantees.PTopup2Verity

/-! Concrete witnesses and kill-lines for the P-TOPUP-2 keccak oracle
boundary. Decoder-only: no always-success stub, no renamed TOPUP premise,
no claim that keccak correspondence is closed. -/
set_option autoImplicit false
namespace LidoSRv3.Tests.TopupKeccakOracleMutants

open Verity
open LidoSRv3.Audit.Source.TopupKeccakOracle
open LidoSRv3.Audit.Verity.Topup2DistributionTx

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n

private def words (xs : List Nat) : List Word := xs.map word

/-- Same two-validator batch as `Topup2DistributionTxMutants` happy path. -/
def sampleEffective : List Word := words [32, 40]
def samplePending : List Word := words [0, 0]
def sampleRequested : List Word := words [6, 8]
def sampleLimits : List Word := words [32, 24]

def sampleState : ContractState :=
  stateFor sampleEffective samplePending sampleRequested sampleLimits defaultState

def sampleTarget : Word := word 64
def sampleMinTopUp : Word := word 1
def sampleRemaining : Word := word 10
def sampleModuleLimit : Word := word 100
def sampleValue : Word := word 100

/-- The public `readArray` recovers the `stateFor` effective column. -/
theorem sample_readArray_effective :
    readArray sampleState "effective" effectiveBase sampleEffective.length =
      some sampleEffective := by
  native_decide

theorem sample_readArray_pending :
    readArray sampleState "pending" pendingBase samplePending.length =
      some samplePending := by
  native_decide

theorem sample_readArray_requested :
    readArray sampleState "requested" requestedBase sampleRequested.length =
      some sampleRequested := by
  native_decide

theorem sample_readArray_limits :
    readArray sampleState "topUpLimits" limitsBase sampleLimits.length =
      some sampleLimits := by
  native_decide

/-- Two oracles that differ only on keccak agree on every parent decode. -/
theorem sample_readArray_independent_of_keccak :
    readArrayWith zeroKeccakOracle sampleState "effective" effectiveBase
        sampleEffective.length = some sampleEffective ∧
      readArrayWith nonzeroKeccakOracle sampleState "effective" effectiveBase
        sampleEffective.length = some sampleEffective ∧
      readArrayWith zeroKeccakOracle sampleState "pending" pendingBase
        samplePending.length = some samplePending ∧
      readArrayWith nonzeroKeccakOracle sampleState "pending" pendingBase
        samplePending.length = some samplePending ∧
      readArrayWith zeroKeccakOracle sampleState "requested" requestedBase
        sampleRequested.length = some sampleRequested ∧
      readArrayWith nonzeroKeccakOracle sampleState "requested" requestedBase
        sampleRequested.length = some sampleRequested ∧
      readArrayWith zeroKeccakOracle sampleState "topUpLimits" limitsBase
        sampleLimits.length = some sampleLimits ∧
      readArrayWith nonzeroKeccakOracle sampleState "topUpLimits" limitsBase
        sampleLimits.length = some sampleLimits := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · simpa [readArray_eq_readArrayWith zeroKeccakOracle] using sample_readArray_effective
  · simpa [readArray_eq_readArrayWith nonzeroKeccakOracle] using sample_readArray_effective
  · simpa [readArray_eq_readArrayWith zeroKeccakOracle] using sample_readArray_pending
  · simpa [readArray_eq_readArrayWith nonzeroKeccakOracle] using sample_readArray_pending
  · simpa [readArray_eq_readArrayWith zeroKeccakOracle] using sample_readArray_requested
  · simpa [readArray_eq_readArrayWith nonzeroKeccakOracle] using sample_readArray_requested
  · simpa [readArray_eq_readArrayWith zeroKeccakOracle] using sample_readArray_limits
  · simpa [readArray_eq_readArrayWith nonzeroKeccakOracle] using sample_readArray_limits

/-- On the same `stateFor` witness the keccak hook still disagrees. -/
theorem sample_keccak_disagrees :
    evalKeccak zeroKeccakOracle sampleState 0 32 ≠
      evalKeccak nonzeroKeccakOracle sampleState 0 32 :=
  zero_and_nonzero_disagree_on_keccak sampleState 0 32

/-- The registered parent fires on this witness (observe = sourceView). -/
theorem sample_parent_holds :
    observe (List.replicate sampleRequested.length 0) sampleRemaining
        ((allocate sampleRequested.length sampleTarget sampleMinTopUp
          sampleRemaining sampleModuleLimit sampleValue).run sampleState) =
      sourceView sampleEffective samplePending sampleRequested sampleLimits
        sampleTarget sampleMinTopUp sampleRemaining sampleModuleLimit sampleValue :=
  LidoSRv3.Audit.Guarantees.PTopup2.verity_tx_simulates_topup2_spec
    sampleEffective samplePending sampleRequested sampleLimits
    sampleTarget sampleMinTopUp sampleRemaining sampleModuleLimit sampleValue
    sampleState sample_readArray_effective sample_readArray_pending
    sample_readArray_requested sample_readArray_limits
    (by native_decide) (by native_decide)

/-- Same conclusion through the oracle-quantified restatement, at the
nonzero keccak stub. -/
theorem sample_parent_any_oracle_nonzero :
    observe (List.replicate sampleRequested.length 0) sampleRemaining
        ((allocate sampleRequested.length sampleTarget sampleMinTopUp
          sampleRemaining sampleModuleLimit sampleValue).run sampleState) =
      sourceView sampleEffective samplePending sampleRequested sampleLimits
        sampleTarget sampleMinTopUp sampleRemaining sampleModuleLimit sampleValue :=
  verity_tx_simulates_topup2_spec_any_oracle nonzeroKeccakOracle
    sampleEffective samplePending sampleRequested sampleLimits
    sampleTarget sampleMinTopUp sampleRemaining sampleModuleLimit sampleValue
    sampleState
    (by simpa [readArray_eq_readArrayWith nonzeroKeccakOracle] using
      sample_readArray_effective)
    (by simpa [readArray_eq_readArrayWith nonzeroKeccakOracle] using
      sample_readArray_pending)
    (by simpa [readArray_eq_readArrayWith nonzeroKeccakOracle] using
      sample_readArray_requested)
    (by simpa [readArray_eq_readArrayWith nonzeroKeccakOracle] using
      sample_readArray_limits)
    (by native_decide) (by native_decide)

/-- Kill-line: the four `readArray` premises of
`verity_tx_simulates_topup2_spec` do not force two keccak hooks to agree.
The parent does not establish keccak correspondence. -/
theorem parent_readArray_premises_do_not_constrain_keccak :
    ¬ (∀ (state : ContractState) (effective pending requested topUpLimits : List Word)
        (off size : Nat),
        readArray state "effective" effectiveBase effective.length = some effective →
        readArray state "pending" pendingBase pending.length = some pending →
        readArray state "requested" requestedBase requested.length = some requested →
        readArray state "topUpLimits" limitsBase topUpLimits.length = some topUpLimits →
        evalKeccak zeroKeccakOracle state off size =
          evalKeccak nonzeroKeccakOracle state off size) := by
  intro h
  exact sample_keccak_disagrees
    (h sampleState sampleEffective samplePending sampleRequested sampleLimits 0 32
      sample_readArray_effective sample_readArray_pending
      sample_readArray_requested sample_readArray_limits)

#print axioms sample_readArray_independent_of_keccak
#print axioms sample_parent_holds
#print axioms parent_readArray_premises_do_not_constrain_keccak

end LidoSRv3.Tests.TopupKeccakOracleMutants
