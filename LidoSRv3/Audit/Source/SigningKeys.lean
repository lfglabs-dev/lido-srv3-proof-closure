import EvmYul.SharedStateOps
import Mathlib.Tactic.NormNum

/-!
[`SigningKeys.loadKeysSigs`](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/lib/SigningKeys.sol#L147-L174)
as an unmetered block using the existing EvmYul `mstore` primitive. The five
storage reads use the computed key slot and wrapping consecutive addresses.
The key's overlapping writes retain their source order; no buffer bounds check
is inserted into assembly. Pointers refer to Solidity bytes length headers.

`keyOffset` is the storage-address producer boundary (the source hashes packed
position/operator/key-index words). It threads the producer's memory effects;
the actual ABI encoder and hash still need instantiation. `storage` is the entry storage snapshot.
Binding these inputs to account storage, the actual hash implementation and
Solidity allocation remains required. These primitives do not execute gas/OOG
or the compiler's control flow; finite recursion represents the source loop.
-/
namespace LidoSRv3.Audit.Source.SigningKeys
open EvmYul

abbrev Storage := UInt256 → UInt256
abbrev KeyOffset := MachineState → UInt256 → UInt256 → UInt256 → UInt256 × MachineState

private def u (n : Nat) : UInt256 := UInt256.ofNat n

/-- In a live source iteration, incrementing the loop counter cannot wrap:
the count is itself a word and the guard requires index < count. This is
distinct from the potentially wrapping start-index and destination additions. -/
theorem loop_index_increment (index count : UInt256)
    (guard : index.toNat < count.toNat) :
    (u (index.toNat + 1)).toNat = index.toNat + 1 ∧
      (u (index.toNat + 1)).toNat ≤ count.toNat := by
  have bound := count.val.isLt
  change count.toNat < UInt256.size at bound
  have next : index.toNat + 1 < UInt256.size := by omega
  change (index.toNat + 1) % UInt256.size = index.toNat + 1 ∧
    (index.toNat + 1) % UInt256.size ≤ count.toNat
  rw [Nat.mod_eq_of_lt next]
  exact ⟨rfl, by omega⟩

/-- One source iteration after `getKeyOffset`, including all five memory stores.
The second public-key word contributes only its high sixteen storage bytes. -/
def loadOne (machine : MachineState) (storage : Storage)
    (slot pubkeys signatures bufferOffset index : UInt256) : MachineState :=
  let destinationIndex := u (bufferOffset.toNat + index.toNat)
  let keyDestination := u (pubkeys.toNat + 32 + destinationIndex.toNat * 48)
  let signatureDestination := u (signatures.toNat + 32 + destinationIndex.toNat * 96)
  let machine := machine.mstore (u (keyDestination.toNat + 16))
    (u ((storage (u (slot.toNat + 1))).toNat / 2^128))
  let machine := machine.mstore keyDestination (storage slot)
  let machine := machine.mstore signatureDestination (storage (u (slot.toNat + 2)))
  let machine := machine.mstore (u (signatureDestination.toNat + 32))
    (storage (u (slot.toNat + 3)))
  machine.mstore (u (signatureDestination.toNat + 64)) (storage (u (slot.toNat + 4)))

/-- Thread ABI encoding/hash memory effects before the assembly key copy. -/
def loadIteration (machine : MachineState) (storage : Storage) (keyOffset : KeyOffset)
    (position operator start pubkeys signatures bufferOffset index : UInt256) : MachineState :=
  let (slot, encoded) := keyOffset machine position operator (u (start.toNat + index.toNat))
  loadOne encoded storage slot pubkeys signatures bufferOffset index

def loadLoop (storage : Storage) (keyOffset : KeyOffset)
    (position operator start pubkeys signatures bufferOffset : UInt256) :
    Nat → UInt256 → MachineState → MachineState
  | 0, _, machine => machine
  | remaining + 1, index, machine =>
    let next := loadIteration machine storage keyOffset position operator start
      pubkeys signatures bufferOffset index
    loadLoop storage keyOffset position operator start pubkeys signatures bufferOffset
      remaining (u (index.toNat + 1)) next

def loadKeysSigs (machine : MachineState) (storage : Storage) (keyOffset : KeyOffset)
    (position operator start count pubkeys signatures bufferOffset : UInt256) : MachineState :=
  loadLoop storage keyOffset position operator start pubkeys signatures bufferOffset
    count.toNat (u 0) machine

/-- Source while-loop relation, with the actual word guard and increment.
This relation shares the primitive body; it does not certify compiler lowering. -/
inductive LoadExecution (storage : Storage) (keyOffset : KeyOffset)
    (position operator start count pubkeys signatures bufferOffset : UInt256) :
    UInt256 → MachineState → MachineState → Prop where
  | done (index : UInt256) (machine : MachineState)
      (stop : count.toNat ≤ index.toNat) :
      LoadExecution storage keyOffset position operator start count pubkeys signatures
        bufferOffset index machine machine
  | step (index : UInt256) (machine after : MachineState)
      (guard : index.toNat < count.toNat)
      (tail : LoadExecution storage keyOffset position operator start count pubkeys signatures
        bufferOffset (u (index.toNat + 1))
        (loadIteration machine storage keyOffset position operator start
          pubkeys signatures bufferOffset index) after) :
      LoadExecution storage keyOffset position operator start count pubkeys signatures
        bufferOffset index machine after

private theorem loadLoop_execution (storage : Storage) (keyOffset : KeyOffset)
    (position operator start count pubkeys signatures bufferOffset : UInt256)
    (remaining : Nat) (index : UInt256) (machine : MachineState)
    (distance : index.toNat + remaining = count.toNat) :
    LoadExecution storage keyOffset position operator start count pubkeys signatures
      bufferOffset index machine
      (loadLoop storage keyOffset position operator start pubkeys signatures bufferOffset
        remaining index machine) := by
  induction remaining generalizing index machine with
  | zero => exact .done index machine (by omega)
  | succ remaining ih =>
    have guard : index.toNat < count.toNat := by omega
    apply LoadExecution.step index machine _ guard
    apply ih
    have advance := (loop_index_increment index count guard).1
    omega

/-- The executable recursion consumes exactly the source loop, for every word
count. No caller-supplied iteration bound or post-state is assumed. -/
theorem loadKeysSigs_execution (machine : MachineState) (storage : Storage)
    (keyOffset : KeyOffset) (position operator start count pubkeys signatures bufferOffset : UInt256) :
    LoadExecution storage keyOffset position operator start count pubkeys signatures bufferOffset
      (u 0) machine
      (loadKeysSigs machine storage keyOffset position operator start count pubkeys signatures bufferOffset) :=
  loadLoop_execution storage keyOffset position operator start count pubkeys signatures bufferOffset
    count.toNat (u 0) machine (by change 0 + count.toNat = count.toNat; omega)

theorem loadKeysSigs_zero (machine : MachineState) (storage : Storage) (keyOffset : KeyOffset)
    (position operator start pubkeys signatures bufferOffset : UInt256) :
    loadKeysSigs machine storage keyOffset position operator start (u 0)
      pubkeys signatures bufferOffset = machine := rfl

end LidoSRv3.Audit.Source.SigningKeys
