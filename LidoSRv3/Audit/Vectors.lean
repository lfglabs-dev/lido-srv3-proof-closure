import LidoSRv3.Audit.StrategyProofs

namespace LidoSRv3.Audit.MinFirst.Vectors

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n
private def b (id allocation capacity : Nat) (active := true)
    (credentialType := CredentialType.wc02) : Bucket :=
  ⟨word id, active, credentialType, allocation, capacity⟩

example : candidate? [b 0 5 10, b 1 0 10] = some (b 1 0 10) := by decide
example : candidate? [b 0 0 10, b 1 0 10] = some (b 0 0 10) := by decide
example : candidate? [b 0 10 10, b 1 1 10] = some (b 1 1 10) := by decide
example : candidate? [b 0 0 10 false, b 1 1 10] = some (b 1 1 10) := by decide
example : candidate? [b 0 0 10 true .wc01, b 1 1 10] = some (b 0 0 10 true .wc01) := by decide
example : allocate 1 [b 0 11 10, b 1 0 1] = [b 0 11 10, b 1 1 1] := by decide
example : allocate 3 [b 0 0 1, b 1 0 1] = [b 0 1 1, b 1 1 1] := by decide
example :
    allocate 1 [b 0 0 10, b 1 0 10] = [b 0 1 10, b 1 0 10] ∧
    allocate 1 [b 1 0 10, b 0 0 10] = [b 1 1 10, b 0 0 10] := by decide

end LidoSRv3.Audit.MinFirst.Vectors
