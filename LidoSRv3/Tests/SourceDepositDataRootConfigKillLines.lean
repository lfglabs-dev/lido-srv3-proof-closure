import LidoSRv3.Audit.Source.DepositDataRootCorrespondence

/-!
Kill-lines pinning `Source.DepositDataRootCorrespondence` pinned
constants and Solidity-range witness theorems. Consumed by the
P-TOPUP-1 beacon-callee via BeaconChainDepositor.sol.
-/

namespace LidoSRv3.Tests.SourceDepositDataRootConfigKillLines

open LidoSRv3.Audit.Source.DepositDataRootCorrespondence

/-! ## `pinnedConfig` — SHA256_DIGEST_LENGTH, PUBKEY_LENGTH,
    WITHDRAWAL_CREDENTIALS_LENGTH, SIGNATURE_LENGTH,
    DEPOSIT_DATA_LENGTH. -/

theorem pinnedConfig_sha256_digest_length :
    SHA256_DIGEST_LENGTH pinnedConfig = 32 := rfl

theorem pinnedConfig_pubkey_length :
    PUBKEY_LENGTH pinnedConfig = 48 := rfl

theorem pinnedConfig_wc_length :
    WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig = 32 := rfl

theorem pinnedConfig_signature_length :
    SIGNATURE_LENGTH pinnedConfig = 96 := rfl

theorem pinnedConfig_deposit_data_length :
    DEPOSIT_DATA_LENGTH pinnedConfig = 184 := rfl

/-! ## Solidity-range projections from the input structure. -/

theorem withdrawalCredentials_solidity_range_restated
    (input : SourceDepositDataRootInput) :
    ∀ byte ∈ input.withdrawalCredentials, byte < 256 :=
  withdrawalCredentials_solidity_range input

theorem publicKey_solidity_range_restated
    (input : SourceDepositDataRootInput) :
    ∀ byte ∈ input.publicKey, byte < 256 :=
  publicKey_solidity_range input

theorem signature_solidity_range_restated
    (input : SourceDepositDataRootInput) :
    ∀ byte ∈ input.signature, byte < 256 :=
  signature_solidity_range input

theorem amountGwei_solidity_range_restated
    (input : SourceDepositDataRootInput) :
    input.amountGwei < 2 ^ 256 :=
  amountGwei_solidity_range input

end LidoSRv3.Tests.SourceDepositDataRootConfigKillLines
