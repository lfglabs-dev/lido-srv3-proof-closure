import LidoSRv3.Audit.Source.SszWitnessAbi

namespace LidoSRv3.Tests.SszWitnessAbiMutants
open EvmYul EvmYul.EVM LidoSRv3.Audit.Source
open SszWitnessAbi SszProofCalldataStep

deriving instance DecidableEq for SszWitnessAbi.Slice

private abbrev w (n : Nat) : UInt256 := UInt256.ofNat n
private def words (ns : List Nat) : ByteArray := wordStream (ns.map w)
private def raw (negative : Bool) (balance slashed keyLength proofRelative : Nat) : ByteArray :=
  ⟨#[0x3b,0xd2,0x27,0xc1]⟩ ++
  words [if negative then 256 else 128,123,456,513] ++
  (if negative then words [keyLength,1,2,0] else ByteArray.empty) ++
  words [proofRelative,if negative then 2^256-128 else 320,balance,11,22,33,44,slashed] ++
  words [1,789,keyLength,1,2]
private def st (negative : Bool) (balance slashed keyLength proofRelative : Nat) : EVM.State :=
  {(default : EVM.State) with
    gasAvailable := w 1000000
    executionEnv := {(default : EVM.State).executionEnv with
      calldata := raw negative balance slashed keyLength proofRelative
      depth := 1024}}
private def tag (result : Except SszWitnessAbi.Error EVM.State) : Option SszWitnessAbi.Error :=
  match result with | .ok _ => none | .error e => some e

set_option maxRecDepth 16384 in
example : header (st false 100 1 48 256) = .ok (w 128) := by
  have h0 : (st false 100 1 48 256).calldataload (w 0) = w (0x3bd227c1 * 2^224) := by
    unfold EvmYul.State.calldataload
    rw [calldata_read_fit _ _ (by decide +kernel)]
    decide +kernel
  have h4 : (st false 100 1 48 256).calldataload (w 4) = w 128 := by
    unfold EvmYul.State.calldataload
    rw [calldata_read_fit _ _ (by decide +kernel)]
    decide +kernel
  simp only [header]
  rw [h0, h4]
  decide +kernel
set_option maxRecDepth 16384 in
example : header (st true 100 1 48 256) = .ok (w 256) := by
  have h0 : (st true 100 1 48 256).calldataload (w 0) = w (0x3bd227c1 * 2^224) := by
    unfold EvmYul.State.calldataload
    rw [calldata_read_fit _ _ (by decide +kernel)]
    decide +kernel
  have h4 : (st true 100 1 48 256).calldataload (w 4) = w 256 := by
    unfold EvmYul.State.calldataload
    rw [calldata_read_fit _ _ (by decide +kernel)]
    decide +kernel
  simp only [header]
  rw [h0, h4]
  decide +kernel

-- Compiler allows a signed relative offset-128. The actual key pointer wraps
-- into earlier calldata, not into a separately supplied decoded witness.
set_option maxRecDepth 16384 in
theorem negative_key_slice :
    (tail (st true 100 1 48 256) (w 256) (w 36) 1).map
      (fun s => (s.offset.toNat,s.length)) = .ok (164,48) := by
  simp (disch := decide +kernel) only [tail, read64, readBool, EvmYul.State.calldataload, calldata_read_fit]
  decide +kernel
set_option maxRecDepth 16384 in
example : (tail (st false 100 1 48 256) (w 128) (w 36) 1).map
    (fun s => (s.offset.toNat,s.length)) = .ok (484,48) := by
  simp (disch := decide +kernel) only [tail, read64, readBool, EvmYul.State.calldataload, calldata_read_fit]
  decide +kernel
set_option maxRecDepth 16384 in
example : (tail (st false 100 1 48 256) (w 128) (w 4) 32).map
    (fun s => (s.offset.toNat,s.length)) = .ok (420,1) := by
  simp (disch := decide +kernel) only [tail, read64, readBool, EvmYul.State.calldataload, calldata_read_fit]
  decide +kernel

-- Guarded raw fields preserve upper uint64 and reject dirty uint64/Bool bits.
set_option maxRecDepth 16384 in
example : read64 (st false (2^64-1) 1 48 256) (w 196) = .ok (BitVec.ofNat 64 (2^64-1)) := by
  simp (disch := decide +kernel) only [tail, read64, readBool, EvmYul.State.calldataload, calldata_read_fit]
  decide +kernel
set_option maxRecDepth 16384 in
example : read64 (st false (2^64) 1 48 256) (w 196) = .error .abi := by
  simp (disch := decide +kernel) only [tail, read64, readBool, EvmYul.State.calldataload, calldata_read_fit]
  decide +kernel
set_option maxRecDepth 16384 in
example : readBool (st false 100 2 48 256) (w 356) = .error .abi := by
  simp (disch := decide +kernel) only [tail, read64, readBool, EvmYul.State.calldataload, calldata_read_fit]
  decide +kernel

-- Actual consumer reaches the raw key call before dirty later fields/tails.
-- Depth1024 executes the primitive's rejection; no fake SHA reply is supplied.
set_option maxRecDepth 16384 in
theorem key_failure_before_dirty_fields :
    tag (run 0 (st false (2^64) 2 48 (2^64-1))) = some (.bls .sha256PrecompileFailed) := by
  have hh : header (st false (2^64) 2 48 (2^64-1)) = .ok (w 128) := by
    have h0 : (st false (2^64) 2 48 (2^64-1)).calldataload (w 0) = w (0x3bd227c1 * 2^224) := by
      unfold EvmYul.State.calldataload
      rw [calldata_read_fit _ _ (by decide +kernel)]
      decide +kernel
    have h4 : (st false (2^64) 2 48 (2^64-1)).calldataload (w 4) = w 128 := by
      unfold EvmYul.State.calldataload
      rw [calldata_read_fit _ _ (by decide +kernel)]
      decide +kernel
    simp only [header]
    rw [h0, h4]
    decide +kernel
  have ht : tail (st false (2^64) 2 48 (2^64-1)) (w 128) (w 36) 1 = .ok ⟨w 484,48⟩ := by
    simp (disch := decide +kernel) only [tail, EvmYul.State.calldataload, calldata_read_fit]
    decide +kernel
  simp only [run, hh, bind, Except.bind]
  rw [ht]
  rfl
set_option maxRecDepth 16384 in
example :
    tag (run 0 (st false (2^64) 2 47 (2^64-1))) = some (.bls .invalidPubkeyLength) := by
  have hh : header (st false (2^64) 2 47 (2^64-1)) = .ok (w 128) := by
    have h0 : (st false (2^64) 2 47 (2^64-1)).calldataload (w 0) = w (0x3bd227c1 * 2^224) := by
      unfold EvmYul.State.calldataload
      rw [calldata_read_fit _ _ (by decide +kernel)]
      decide +kernel
    have h4 : (st false (2^64) 2 47 (2^64-1)).calldataload (w 4) = w 128 := by
      unfold EvmYul.State.calldataload
      rw [calldata_read_fit _ _ (by decide +kernel)]
      decide +kernel
    simp only [header]
    rw [h0, h4]
    decide +kernel
  have ht : tail (st false (2^64) 2 47 (2^64-1)) (w 128) (w 36) 1 = .ok ⟨w 484,47⟩ := by
    simp (disch := decide +kernel) only [tail, EvmYul.State.calldataload, calldata_read_fit]
    decide +kernel
  simp only [run, hh, bind, Except.bind]
  rw [ht]
  rfl
set_option maxRecDepth 16384 in
example :
    tag (run 0 (st true (2^64) 2 48 (2^64-1))) = some (.bls .sha256PrecompileFailed) := by
  have hh : header (st true (2^64) 2 48 (2^64-1)) = .ok (w 256) := by
    have h0 : (st true (2^64) 2 48 (2^64-1)).calldataload (w 0) = w (0x3bd227c1 * 2^224) := by
      unfold EvmYul.State.calldataload
      rw [calldata_read_fit _ _ (by decide +kernel)]
      decide +kernel
    have h4 : (st true (2^64) 2 48 (2^64-1)).calldataload (w 4) = w 256 := by
      unfold EvmYul.State.calldataload
      rw [calldata_read_fit _ _ (by decide +kernel)]
      decide +kernel
    simp only [header]
    rw [h0, h4]
    decide +kernel
  have ht : tail (st true (2^64) 2 48 (2^64-1)) (w 256) (w 36) 1 = .ok ⟨w 164,48⟩ := by
    simp (disch := decide +kernel) only [tail, EvmYul.State.calldataload, calldata_read_fit]
    decide +kernel
  simp only [run, hh, bind, Except.bind]
  rw [ht]
  rfl

#print axioms negative_key_slice
#print axioms key_failure_before_dirty_fields
#print axioms run_success_origin
end LidoSRv3.Tests.SszWitnessAbiMutants
