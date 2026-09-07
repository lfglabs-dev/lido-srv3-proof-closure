import LidoSRv3.Audit.Source.TrioAlloc2.Step

namespace LidoSRv3.Tests.TrioAlloc2
open LidoSRv3.Audit.Source.TrioAlloc2

private def w (n : Nat) : Word := ⟨n % 2 ^ 256, Nat.mod_lt _ (by decide)⟩

example : ceilDiv zero zero = .ok zero := by rfl
example : ceilDiv one zero = .error .divisionByZero := by rfl
example : ceilDiv maxWord one = .ok maxWord := by rfl
example : checkedAdd maxWord one = .error .arithmetic := by rfl
example : checkedSub zero one = .error .arithmetic := by rfl
example : step [w 7] [] zero = .ok ⟨zero, [w 7]⟩ := by rfl
example : step [zero] [] one = .error .arrayBounds := by rfl
example : step [zero] [w 5, zero] (w 3) = .ok ⟨w 3, [w 3]⟩ := by rfl
example : step [w 9] [w 8] (w 3) = .ok ⟨zero, [w 9]⟩ := by rfl
example : step [w 9998, w 70, zero] [w 10000, w 101, w 100] (w 101) =
    .ok ⟨w 70, [w 9998, w 70, w 70]⟩ := by rfl
example : step [w 9998, w 70, w 70] [w 10000, w 101, w 100] (w 31) =
    .ok ⟨w 16, [w 9998, w 86, w 70]⟩ := by rfl

end LidoSRv3.Tests.TrioAlloc2
