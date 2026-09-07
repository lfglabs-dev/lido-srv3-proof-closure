import LidoSRv3.Audit.Source.TrioReserve1.Live
import Lean.Elab.Tactic.Omega

namespace LidoSRv3.Audit.Source.TrioReserve1.Transfers
open Live

theorem sender_debit (w : World) (sender recipient : Address) (amount : Nat)
    (hd : sender ≠ recipient) :
    (transfer w sender recipient amount).balances sender = w.balances sender - amount := by
  simp [transfer, hd]

theorem recipient_credit (w : World) (sender recipient : Address) (amount : Nat)
    (hd : sender ≠ recipient) :
    (transfer w sender recipient amount).balances recipient = w.balances recipient + amount := by
  simp [transfer, Ne.symm hd]

theorem other_balance (w : World) (sender recipient account : Address) (amount : Nat)
    (hs : account ≠ sender) (hr : account ≠ recipient) :
    (transfer w sender recipient amount).balances account = w.balances account := by
  simp [transfer, hs, hr]

/-- No balance is created when a contract calls itself with value. This is
distinct from summing two balances at an aliased address. -/
theorem self_transfer_balance (w : World) (account : Address) (amount : Nat)
    (hfunds : amount ≤ w.balances account) :
    (transfer w account account amount).balances = w.balances := by
  funext a
  by_cases ha : a = account
  · subst a
    simp only [transfer, ↓reduceIte]
    omega
  · simp [transfer, ha]

/-- Exact two-account ETH conservation follows from CALL's balance check.
Neither truncation nor an artificial saturating credit is used. -/
theorem conserves (w : World) (sender recipient : Address) (amount : Nat)
    (hd : sender ≠ recipient) (hfunds : amount ≤ w.balances sender) :
    (transfer w sender recipient amount).balances sender +
      (transfer w sender recipient amount).balances recipient =
        w.balances sender + w.balances recipient := by
  rw [sender_debit w sender recipient amount hd, recipient_credit w sender recipient amount hd]
  omega

/-- Conditional bridge to bounded EVM balances. A bound on the aggregate
available ETH, not separate per-account bounds, suffices to rule out credit
overflow. Establishing that aggregate bound from an EVM world remains an
explicit upstream obligation; small test vectors do not prove it. -/
theorem credit_bound_from_aggregate (w : World) (sender recipient : Address)
    (amount bound : Nat) (hd : sender ≠ recipient)
    (hfunds : amount ≤ w.balances sender)
    (haggregate : w.balances sender + w.balances recipient < bound) :
    (transfer w sender recipient amount).balances recipient < bound := by
  rw [recipient_credit w sender recipient amount hd]
  omega

end LidoSRv3.Audit.Source.TrioReserve1.Transfers
