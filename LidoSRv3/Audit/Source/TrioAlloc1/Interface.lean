import Init

/-!
Proposed ALLOC-1 producer boundary, pending orchestrator-mediated consumer agreement.
Pinned source: lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436
contracts/0.8.25/sr/SRLib.sol:493–559. This module defines a view and relation;
it does not assert Solidity memory/ABI correspondence or reachable-state bounds.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1

abbrev Word := Fin (2 ^ 256)
abbrev Address := Fin (2 ^ 160)
abbrev Byte := Fin 256
abbrev Bytes := List Byte

/-- Router ID and address are ghost identity observations, never array indices. -/
structure ModuleIdentity where
  moduleId : Word
  moduleAddress : Address
  deriving DecidableEq, Repr

/-- Config is supplied by the router's immutable fields at the public boundary. -/
structure Config where
  maxEBType1 : Word
  maxEBType2 : Word
  deriving DecidableEq, Repr

structure CapacityInput where
  config : Config
  depositsToAllocate : Word
  isTopUp : Bool
  deriving DecidableEq, Repr

/-- Both arrays use WC01 validator equivalents. No positivity/headroom premise. -/
structure CapacityOutput where
  identities : List ModuleIdentity
  allocations : List Word
  capacities : List Word
  allocations_length : allocations.length = identities.length
  capacities_length : capacities.length = identities.length

/-- Exact failure encoding/exception propagation is an execution-layer obligation. -/
inductive Failure where
  | revertData (data : Bytes)
  | decoderFailure
  | panic (code : Word)
  | exceptionalCall
  deriving DecidableEq, Repr

abbrev CapacityResult := Except Failure CapacityOutput

/-- Word reads at byte addresses; connection to actual byte memory is still open. -/
abbrev MemoryWords := Nat → Word

def ArrayAt (memory : MemoryWords) (pointer : Nat) (values : List Word) : Prop :=
  (memory pointer).val = values.length ∧
  ∀ i : Fin values.length, memory (pointer + 32 * (i.val + 1)) = values[i]

/-- Exact length-prefixed arrays, separate regions, and nonwrapping addresses. -/
def MemoryArraysRelated (memory : MemoryWords) (allocationPtr capacityPtr : Nat)
    (output : CapacityOutput) : Prop :=
  ArrayAt memory allocationPtr output.allocations ∧
  ArrayAt memory capacityPtr output.capacities ∧
  allocationPtr + 32 * (output.allocations.length + 1) ≤ 2 ^ 256 ∧
  capacityPtr + 32 * (output.capacities.length + 1) ≤ 2 ^ 256 ∧
  (allocationPtr + 32 * (output.allocations.length + 1) ≤ capacityPtr ∨
   capacityPtr + 32 * (output.capacities.length + 1) ≤ allocationPtr)

/-- Index binding is to the entire router enumeration, without status filtering. -/
def RouterOrderRelated (routerOrder : List ModuleIdentity) (output : CapacityOutput) : Prop :=
  output.identities = routerOrder

theorem output_lengths_equal (output : CapacityOutput) :
    output.allocations.length = output.capacities.length :=
  output.allocations_length.trans output.capacities_length.symm

theorem memory_lengths_equal (memory : MemoryWords) (ap cp : Nat)
    (output : CapacityOutput) (h : MemoryArraysRelated memory ap cp output) :
    (memory ap).val = (memory cp).val :=
  h.1.1.trans ((output_lengths_equal output).trans h.2.1.1.symm)

end LidoSRv3.Audit.Source.TrioAlloc1
