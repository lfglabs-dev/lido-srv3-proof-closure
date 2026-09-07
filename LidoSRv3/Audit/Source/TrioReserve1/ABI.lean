import LidoSRv3.Audit.Source.TrioReserve1.Live
import Init.Data.Nat.Mod
import Lean.Elab.Tactic.Omega

/-! Byte-level binding for the actual source-shaped encoder and decoder.
Out-of-range inputs are explicitly reduced; exact round trips require bounds. -/
namespace LidoSRv3.Audit.Source.TrioReserve1.ABI
open Live

theorem encode_length (size n : Nat) : (encode size n).length = size := by
  simp [encode]

theorem encode_succ (size n : Nat) :
    encode (size + 1) n = encode size (n / 256) ++ [UInt8.ofNat (n % 256)] := by
  unfold encode
  rw [List.range_succ, List.map_append]
  congr 1
  · apply List.map_congr_left
    intro i hi
    have hi' : i < size := List.mem_range.mp hi
    have he : size + 1 - 1 - i = (size - 1 - i) + 1 := by omega
    simp only [he, Nat.pow_succ, Nat.div_div_eq_div_mul]
    rw [Nat.mul_comm (256 ^ (size - 1 - i)) 256]
  · simp

theorem decode_append_byte (data : Bytes) (b : UInt8) :
    decode (data ++ [b]) = decode data * 256 + b.toNat := by
  simp [decode, List.foldl_append]

theorem decode_encode (size n : Nat) :
    decode (encode size n) = n % 256 ^ size := by
  induction size generalizing n with
  | zero => simp [encode, decode, Nat.mod_one]
  | succ size ih =>
    rw [encode_succ, decode_append_byte, ih]
    simp only [UInt8.toNat_ofNat', Nat.reducePow, Nat.mod_mod]
    rw [Nat.pow_succ, Nat.mul_comm (256 ^ size) 256, Nat.mod_mul]
    omega

theorem decode_encode_bounded (size n : Nat) (h : n < 256 ^ size) :
    decode (encode size n) = n := by
  rw [decode_encode, Nat.mod_eq_of_lt h]

theorem decode_word (n : Nat) (suffix : Bytes) (w : World) :
    decodeWord (encode 32 n ++ suffix) 0 w = ⟨.ok (word n), w, []⟩ := by
  have hlen : (encode 32 n ++ suffix).length ≥ 32 := by
    simp only [List.length_append, encode_length]
    omega
  have htake : (encode 32 n ++ suffix).take 32 = encode 32 n := by
    simpa only [encode_length] using (List.take_left (l₁ := encode 32 n) (l₂ := suffix))
  simp only [decodeWord, Nat.zero_add, List.drop_zero, htake, decode_encode]
  simp [require, bind, pure, bindExec, pureExec, encode_length, word,
    Verity.Core.Uint256.ofNat, Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS]

theorem decode_second_word (a b : Nat) (suffix : Bytes) (w : World) :
    decodeWord (encode 32 a ++ encode 32 b ++ suffix) 32 w =
      ⟨.ok (word b), w, []⟩ := by
  have hlen : (encode 32 a ++ encode 32 b ++ suffix).length ≥ 64 := by
    simp only [List.length_append, encode_length]
    omega
  have hdrop : (encode 32 a ++ encode 32 b ++ suffix).drop 32 = encode 32 b ++ suffix := by
    rw [List.append_assoc]
    simpa only [encode_length] using (List.drop_left (l₁ := encode 32 a) (l₂ := encode 32 b ++ suffix))
  have htake : (encode 32 b ++ suffix).take 32 = encode 32 b := by
    simpa only [encode_length] using (List.take_left (l₁ := encode 32 b) (l₂ := suffix))
  simp only [decodeWord, hdrop, htake, decode_encode]
  simp only [show 32 + 32 = 64 from rfl, require, hlen, decide_true, ite_true, bind, pure, bindExec, pureExec]
  simp [word,
    Verity.Core.Uint256.ofNat, Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS]

end LidoSRv3.Audit.Source.TrioReserve1.ABI
