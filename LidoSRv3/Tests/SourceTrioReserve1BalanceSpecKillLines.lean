import LidoSRv3.Audit.Source.TrioReserve1.BalanceSpec

/-!
Kill-lines pinning `TrioReserve1.BalanceSpec` `mass` folding
identity, `member_bound`, and `account_bound` invariants for
finite-account worlds.
-/

namespace LidoSRv3.Tests.SourceTrioReserve1BalanceSpecKillLines

open LidoSRv3.Audit.Source.TrioReserve1.BalanceSpec

/-! ## `mass` empty base case. -/

theorem mass_empty {Address : Type} (balances : Address → Nat) :
    mass balances ([] : List Address) = 0 := rfl

/-! ## `mass` cons reduction. -/

theorem mass_cons {Address : Type}
    (balances : Address → Nat) (a : Address) (rest : List Address) :
    mass balances (a :: rest) = balances a + mass balances rest := rfl

/-! ## `member_bound` — restated. -/

theorem member_bound_restated {Address : Type}
    (balances : Address → Nat) (accounts : List Address)
    (account : Address) (h : account ∈ accounts) :
    balances account ≤ mass balances accounts :=
  member_bound balances accounts account h

/-! ## `account_bound` — restated. -/

theorem account_bound_restated {Address : Type}
    (balances : Address → Nat) (accounts : List Address)
    (limit : Nat) (h : Bounded balances accounts limit)
    (account : Address) :
    balances account < limit :=
  account_bound balances accounts limit h account

/-! ## Concrete `mass` on a two-element ledger. -/

theorem mass_two_elements :
    mass (fun (n : Nat) => n * 10) [1, 2] = 30 := by
  simp [mass]

end LidoSRv3.Tests.SourceTrioReserve1BalanceSpecKillLines
