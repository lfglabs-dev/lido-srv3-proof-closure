import LidoSRv3.Audit.Source.TopupCorrespondence

/-! # Kill-lines for `TopupCorrespondence.pinnedConfig` constants

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned StakingRouter / BeaconChainDepositor constants:
pubkey lengths, `1 gwei`, `1 ether` MIN_DEPOSIT, uint64 upper bound. -/

namespace LidoSRv3.Tests.TopupPinnedConfigKillLines

open LidoSRv3.Audit.SolidityTopup

/-- **Kill-line: `pubkeyLength = 48` (StakingRouter.PUBKEY_LENGTH).** -/
theorem pinnedConfig_pubkeyLength :
    pinnedConfig.pubkeyLength = 48 := rfl

/-- **Kill-line: `publicKeyLength = 48`
(BeaconChainDepositor.PUBLIC_KEY_LENGTH).** -/
theorem pinnedConfig_publicKeyLength :
    pinnedConfig.publicKeyLength = 48 := rfl

/-- **Kill-line: `1 gwei = 10^9`.** -/
theorem pinnedConfig_gwei :
    pinnedConfig.gwei = 1000000000 := rfl

/-- **Kill-line: `MIN_DEPOSIT = 1 ether = 10^18`.** -/
theorem pinnedConfig_minDeposit :
    pinnedConfig.minDeposit = 1000000000000000000 := rfl

/-- **Kill-line: `uint64Max = 2^64 - 1 = 18446744073709551615`.** -/
theorem pinnedConfig_uint64Max :
    pinnedConfig.uint64Max = 18446744073709551615 := rfl

/-- **Kill-line: `1 gwei` is exactly 10^9 (as decimal).** -/
theorem pinnedConfig_gwei_decimal :
    pinnedConfig.gwei = 10 ^ 9 := by decide

/-- **Kill-line: `1 ether = 10^18`.** -/
theorem pinnedConfig_minDeposit_decimal :
    pinnedConfig.minDeposit = 10 ^ 18 := by decide

/-- **Kill-line: `uint64Max = 2^64 - 1`.** -/
theorem pinnedConfig_uint64Max_arithmetic :
    pinnedConfig.uint64Max = 2 ^ 64 - 1 := by decide

/-- **Kill-line: pinned gwei is non-zero (totality guard for source-line-706
modulo).** -/
theorem pinnedConfig_gwei_ne_zero_kill :
    pinnedConfig.gwei ≠ 0 := pinnedConfig_gwei_ne_zero

/-- **Kill-line: pubkey lengths agree between StakingRouter and Depositor.** -/
theorem pinnedConfig_pubkey_lengths_agree_kill :
    pinnedConfig.publicKeyLength = pinnedConfig.pubkeyLength :=
  pinnedConfig_pubkey_lengths_agree

#print axioms pinnedConfig_pubkeyLength
#print axioms pinnedConfig_gwei
#print axioms pinnedConfig_minDeposit
#print axioms pinnedConfig_uint64Max
#print axioms pinnedConfig_gwei_decimal
#print axioms pinnedConfig_gwei_ne_zero_kill

end LidoSRv3.Tests.TopupPinnedConfigKillLines
