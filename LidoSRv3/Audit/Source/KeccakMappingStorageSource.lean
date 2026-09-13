/-! # Keccak mapping-storage source model
(shared: SRStorage/moduleRegistry, Aragon-ACL registry, WithdrawalQueue mapping decoders)

**General rule (Thomas 2026-09-13, shared keyed-mapping storage
model consumed by TOPUP-1 SR mapping, RESERVE-1 packed
StakeLimitStruct, ADDRESS-1 request/checkpoint mapping.)**

Names the keccak-derived-slot storage layout that Solidity uses for
`mapping(K => V)`, `mapping(K => Struct)`, and packed storage
positions. Under this model, mapping reads become DEFINED functions
of a source-level `MappingStorage`, not anonymous free field values.

Pinned Solidity uses keccak-hashed slot layouts (per Solidity's ABI
spec):

- For `mapping(K => V) public m`: the value at key `k` is stored at
  `keccak256(abi.encode(k, mSlot))`.
- For packed structs: each field occupies a contiguous range of the
  slot's 32-byte word.

The model deliberately does not model keccak's cryptographic
properties or the packed-slot bit-shifting arithmetic — this
scaffold names a `MappingStorage` type as an abstract key-value
function, and packed-decode as a `PackedSlotDecoder` for the packed
32-byte word. Under these models, per-guarantee downstream consumers
supply the mapping keys they need and receive named
storage-decoded values.

**Status:** first-step real derivation. Provides a shared
key-value abstraction that RESERVE-1, TOPUP-1, and ADDRESS-1
consumers can specialize. The MappingStorage functions are still
input-parameterized (`slotAt : Nat → Nat`), but the composition
SHAPE is now correct: mapping reads are functions of a named
storage state.

Residual: the concrete keccak derivation
(`slotAt k = keccak256(abi.encode(k, baseSlot))`) is out of scope
and stays under `A-KECCAK-COMMITMENT` / `A-VERITY-SCAFFOLD`. The
packed-slot bit-decode arithmetic also stays as a source-level
input for downstream consumers. -/

namespace LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-- Abstract keyed-storage state: a mapping from `Nat`-encoded keys
to `Nat`-encoded 32-byte values. Named as an audit-source model of
`mapping(K => V)` storage. -/
structure MappingStorage : Type where
  slotAt : Nat → Nat

/-- Read a mapping value at a specific key. Definition of the
Solidity mapping read `m[k]` in the source model. -/
def read (m : MappingStorage) (k : Nat) : Nat :=
  m.slotAt k

/-- The read equals the storage function value, definitionally. -/
theorem read_eq (m : MappingStorage) (k : Nat) :
    read m k = m.slotAt k := rfl

/-- Packed 32-byte slot decoder: extracts a bit-range as a `Nat`
value. Names the Solidity packed-slot decode (e.g., a `uint16`
field at bit offset). -/
structure PackedSlotDecoder : Type where
  slotWord : Nat
  extract : Nat → Nat → Nat  -- extract offset width from slotWord

/-- Decode a specific bit-range from a packed slot. Definition of
the Solidity packed-slot bit-field read in the source model. -/
def decodeField (d : PackedSlotDecoder) (bitOffset bitWidth : Nat) : Nat :=
  d.extract bitOffset bitWidth

/-- The decoded field equals the extractor's output, definitionally. -/
theorem decodeField_eq (d : PackedSlotDecoder) (bitOffset bitWidth : Nat) :
    decodeField d bitOffset bitWidth = d.extract bitOffset bitWidth := rfl

end LidoSRv3.Audit.Source.KeccakMappingStorageSource
