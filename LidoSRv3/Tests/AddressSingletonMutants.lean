import LidoSRv3.Audit.Source.AddressSingleton

/-! P-ADDRESS-1 live singleton-actor exclusion vectors. -/

namespace LidoSRv3.Tests.AddressSingletonMutants

open LidoSRv3.Audit.SolidityAddress
open LidoSRv3.Audit.Source.AddressSingleton

/-- Honest `requestWithdrawals` admits callers 1 and 2
(WithdrawalQueue.sol:125-136). -/
example :
    admitted (eligible .requestWithdrawals 1) = true ∧
      admitted (eligible .requestWithdrawals 2) = true := by decide

/-- Honest `unwrap` admits callers 1 and 2 (WstETH.sol:69-75). -/
example :
    admitted (eligible .unwrap 1) = true ∧
      admitted (eligible .unwrap 2) = true := by decide

/-- Honest `claimWithdrawalsTo` admits distinct request owners
(WithdrawalQueueBase.sol:467). -/
example :
    admitted (eligible .claimWithdrawalsTo 1) = true ∧
      admitted (eligible .claimWithdrawalsTo 2) = true := by decide

/-- Honest owner-operated `transferFrom` admits distinct owners
(WithdrawalQueueERC721.sol:241-245). -/
example :
    admitted (eligible .transferFrom 1) = true ∧
      admitted (eligible .transferFrom 2) = true := by decide

/-- Fixed-owner mutant admits caller 7 and rejects caller 1 on an otherwise
eligible `requestWithdrawals`. -/
example :
    admittedFixedOwner (eligible .requestWithdrawals 7) = true ∧
      admittedFixedOwner (eligible .requestWithdrawals 1) = false := by decide

#print axioms LidoSRv3.Audit.Source.AddressSingleton.no_fixed_actor
#print axioms LidoSRv3.Audit.Source.AddressSingleton.fixed_owner_mutant_requires_actor
#print axioms LidoSRv3.Audit.Source.AddressSingleton.parent_omission_is_definitional

end LidoSRv3.Tests.AddressSingletonMutants
