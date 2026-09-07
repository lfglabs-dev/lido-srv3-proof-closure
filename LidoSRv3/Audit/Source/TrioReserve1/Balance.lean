import LidoSRv3.Audit.Source.TrioReserve1.BalanceSpec
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalCalls

namespace LidoSRv3.Audit.Source.TrioReserve1.Balance
open Live

/-- An explicit finite-support aggregate invariant is preserved by every funded
provisional CALL transfer, including self-transfers. It bounds every resulting
account balance, not only the receiver. No artificial saturation is introduced. -/
theorem transfer_preserves (before : World) (sender recipient : Address) (amount : Nat)
    (accounts : List Address) (limit : Nat)
    (hb : BalanceSpec.Bounded before.balances accounts limit)
    (hs : sender ∈ accounts) (hr : recipient ∈ accounts) (hf : amount ≤ before.balances sender) :
    BalanceSpec.Bounded (transfer before sender recipient amount).balances accounts limit ∧
      BalanceSpec.mass (transfer before sender recipient amount).balances accounts = BalanceSpec.mass before.balances accounts :=
  BalanceSpec.preserves before.balances _ sender recipient amount accounts limit hb hs hr
    (CallFlow.transfer_balances before sender recipient amount hf)

theorem transfer_uint256 (before : World) (sender recipient : Address) (amount : Nat)
    (accounts : List Address)
    (hb : BalanceSpec.Bounded before.balances accounts Verity.Core.UINT256_MODULUS)
    (hs : sender ∈ accounts) (hr : recipient ∈ accounts) (hf : amount ≤ before.balances sender)
    (account : Address) : (transfer before sender recipient amount).balances account < Verity.Core.UINT256_MODULUS :=
  BalanceSpec.account_bound _ accounts _ (transfer_preserves before sender recipient amount accounts _ hb hs hr hf).1 account

/-- No prior support-membership premise is needed: both CALL participants can be
added without changing the initial mass, including a fresh zero-balance receiver. -/
theorem transfer_finite (before : World) (sender recipient : Address) (amount : Nat)
    (accounts : List Address) (limit : Nat)
    (hb : BalanceSpec.Bounded before.balances accounts limit)
    (hf : amount ≤ before.balances sender) :
    ∃ support, BalanceSpec.Bounded (transfer before sender recipient amount).balances support limit ∧
      BalanceSpec.mass (transfer before sender recipient amount).balances support =
        BalanceSpec.mass before.balances accounts := by
  let first := BalanceSpec.includeAccount sender accounts
  let support := BalanceSpec.includeAccount recipient first
  have hfirst := BalanceSpec.include_bounded before.balances sender accounts limit hb
  have hsupport := BalanceSpec.include_bounded before.balances recipient first limit hfirst.1
  have hs : sender ∈ support := BalanceSpec.include_retains recipient sender first
    (BalanceSpec.include_member sender accounts)
  have hr : recipient ∈ support := BalanceSpec.include_member recipient first
  have result := transfer_preserves before sender recipient amount support limit hsupport.1 hs hr hf
  exact ⟨support, result.1, result.2.trans (hsupport.2.trans hfirst.2)⟩

theorem transfer_finite_uint256 (before : World) (sender recipient : Address) (amount : Nat)
    (accounts : List Address)
    (hb : BalanceSpec.Bounded before.balances accounts Verity.Core.UINT256_MODULUS)
    (hf : amount ≤ before.balances sender) (account : Address) :
    (transfer before sender recipient amount).balances account < Verity.Core.UINT256_MODULUS := by
  obtain ⟨support, bounded, _⟩ := transfer_finite before sender recipient amount accounts _ hb hf
  exact BalanceSpec.account_bound _ support _ bounded account

end LidoSRv3.Audit.Source.TrioReserve1.Balance
