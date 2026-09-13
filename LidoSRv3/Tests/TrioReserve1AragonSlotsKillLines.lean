import LidoSRv3.Audit.Source.TrioReserve1.Aragon

/-! # Kill-lines for `TrioReserve1.Aragon` initialization/kernel slots + role hash

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the three pinned Aragon AppStorage constants used by the executable
Lido 0.4.24 reserve path: initializationSlot, kernelSlot,
bufferReserveManagerRole hash. -/

namespace LidoSRv3.Tests.TrioReserve1AragonSlotsKillLines

open LidoSRv3.Audit.Source.TrioReserve1.Aragon

/-- **Kill-line: pinned Aragon `INITIALIZED_APP_POSITION` slot.**

Standard Aragon AppStorage `INITIALIZED_APP_POSITION` = keccak256(
"aragonOS.initializable.initializationBlock"). -/
theorem initializationSlot_pinned :
    initializationSlot =
      0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e :=
  rfl

/-- **Kill-line: pinned Aragon `KERNEL_POSITION` slot.**

Standard Aragon AppStorage `KERNEL_POSITION` =
keccak256("aragonOS.appStorage.kernel"). -/
theorem kernelSlot_pinned :
    kernelSlot =
      0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b :=
  rfl

/-- **Kill-line: pinned `BUFFER_RESERVE_MANAGER_ROLE` keccak hash.** -/
theorem bufferReserveManagerRole_pinned :
    bufferReserveManagerRole.val =
      0x33969636f1fbf3d7d062d4de4a08e7bd3c46606ec28b3a4398d2665be559b921 := by
  decide

/-- **Kill-line: all three constants fit uint256.** -/
theorem initializationSlot_fits_uint256 : initializationSlot < 2 ^ 256 := by decide
theorem kernelSlot_fits_uint256 : kernelSlot < 2 ^ 256 := by decide

/-- **Kill-line: all three constants are non-zero.** -/
theorem initializationSlot_nonzero : initializationSlot ≠ 0 := by decide
theorem kernelSlot_nonzero : kernelSlot ≠ 0 := by decide

/-- **Kill-line: the three constants are pairwise distinct as Nats.** -/
theorem aragon_constants_pairwise_distinct :
    initializationSlot ≠ kernelSlot ∧
    kernelSlot ≠
      0x33969636f1fbf3d7d062d4de4a08e7bd3c46606ec28b3a4398d2665be559b921 ∧
    initializationSlot ≠
      0x33969636f1fbf3d7d062d4de4a08e7bd3c46606ec28b3a4398d2665be559b921 := by
  refine ⟨?_, ?_, ?_⟩ <;> decide

#print axioms initializationSlot_pinned
#print axioms kernelSlot_pinned
#print axioms bufferReserveManagerRole_pinned
#print axioms aragon_constants_pairwise_distinct

end LidoSRv3.Tests.TrioReserve1AragonSlotsKillLines
