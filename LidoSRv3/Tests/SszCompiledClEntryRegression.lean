import LidoSRv3.Audit.Guarantees.PSsz1CompiledClEntry

/-! Kernel regressions for the compiled CL entry's pure prefix: the literal Solady
`fls`, the compiled generalized-index words on the pinned constructor, and the
decoder's word arithmetic. The machine-level phases execute the opaque SHA FFI
and are covered by the theorems, not by kernel evaluation (as for the existing
compiled increments). -/
namespace LidoSRv3.Tests.SszCompiledClEntryRegression
open LidoSRv3.Audit.Source LidoSRv3.Audit.Source.SszSoladyFls LidoSRv3.Audit.Source.SszCompiledGIndex
open LidoSRv3.Audit.Source.SszWrapperIndex

/-- The literal bit-trick `fls` on the header index, the pinned validator base, a
mid-tree index, zero and the top word. -/
theorem fls_header : sourceFls 11 = 3 := by decide +kernel
theorem fls_pinned_base : sourceFls (150 * 2 ^ 40) = 47 := by decide +kernel
theorem fls_pinned_validator : sourceFls (150 * 2 ^ 40 + 1234) = 47 := by decide +kernel
theorem fls_zero_sentinel : sourceFls 0 = 256 := by decide +kernel
theorem fls_top : sourceFls (2 ^ 256 - 1) = 255 := by decide +kernel
theorem fls_power_boundary : sourceFls (2 ^ 128) = 128 ∧ sourceFls (2 ^ 128 - 1) = 127 := by
  decide +kernel

/-- Constructor words of the pinned configuration are the IR immutables. -/
theorem pinned_immutables :
    cfgWords (pinnedConfiguration ⟨0, by decide⟩) = ⟨2819, 0x96000000000028, 0x96000000000028, 0⟩ :=
  pinned_words _

/-- The compiled index of validator offset 1234 at slot 100 is the packed word of
the typed result `1430 * 2^40 + 1234` with power 40 (SSZ314's pinned value). -/
theorem compiled_index_pinned :
    wrapper (cfgWords (pinnedConfiguration ⟨0, by decide⟩)) 100 1234 =
      .ok ((1430 * 2 ^ 40 + 1234) * 256 + 40) := by
  decide +kernel

/-- The proof loop's `shr(8, ·)` of that word is the typed index. -/
theorem compiled_index_decoded :
    ((1430 * 2 ^ 40 + 1234) * 256 + 40) / 256 = 1430 * 2 ^ 40 + 1234 := by decide +kernel

/-- Offsets outside the configured subtree are rejected by the compiled range guard. -/
theorem compiled_index_out_of_range :
    wrapper (cfgWords (pinnedConfiguration ⟨0, by decide⟩)) 100 (2 ^ 40) = .error .indexOutOfRange := by
  decide +kernel

/-- The aligned pinned base has zero remainder, so a maximal offset reaches
the range guard without overflowing the first checked addition. -/
theorem compiled_index_max_out_of_range :
    wrapper (cfgWords (pinnedConfiguration ⟨0, by decide⟩)) 100 (2 ^ 256 - 1) = .error .indexOutOfRange := by
  decide +kernel

/-- A nonaligned base makes the first checked addition overflow before the range guard. -/
theorem compiled_index_wraps :
    wrapper ⟨2819, (150 * 2^40 + 1) * 256 + 40,
      (150 * 2^40 + 1) * 256 + 40, 0⟩ 100 (2^256-1) = .error .panic11 := by
  decide +kernel

/-- Decoder arithmetic on words: `sub(add(data, len), data)` and the signed compare. -/
theorem decoder_words :
    EvmYul.UInt256.ofNat 192 + EvmYul.UInt256.ofNat 34 - EvmYul.UInt256.ofNat 192 = EvmYul.UInt256.ofNat 34 ∧
    EvmYul.UInt256.sltBool (EvmYul.UInt256.ofNat 31) (EvmYul.UInt256.ofNat 32) = true ∧
    EvmYul.UInt256.sltBool (EvmYul.UInt256.ofNat 34) (EvmYul.UInt256.ofNat 32) = false := by
  decide +kernel

/-- The repair target selector of the inspected entry. -/
theorem entry_selector : (0x2e77b4ba : Nat) ≠ 0x3bd227c1 := by decide

#print axioms fls_top
#print axioms compiled_index_pinned
#print axioms compiled_index_out_of_range
end LidoSRv3.Tests.SszCompiledClEntryRegression
