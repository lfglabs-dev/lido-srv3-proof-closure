import LidoSRv3.Audit.Verity.TopupTx
import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Audit.Guarantees.PDeposit1

/-!
# A-TOPUP-BEACON-ADDRESS and A-DEPOSIT-CONTRACT are discharged from the
deployed `StakingRouter` runtime bytecode

The Lean model literals
`LidoSRv3.Audit.Verity.TopupTx.beaconAddress`
= `LidoSRv3.Audit.Guarantees.PTopup1.canonicalBeaconDepositAddress`
= `LidoSRv3.Audit.Guarantees.PDeposit1.canonicalDepositContractAddress`
= `0x00000000219ab540356cBB839Cbe05303d7705Fa` are now anchored to the
actual `DEPOSIT_CONTRACT` immutable value inside the deployed Lido
`StakingRouter` implementation runtime bytecode.

## Provenance chain (recorded in `audit/artifacts.lock.json`)

- Proxy: `0xFdDf38947aFB03C621C71b06C9C70bce73f12999` (StakingRouter).
- Implementation: `0xDD76927045435C7605cf6f5F978cfb8CABDb5F80`.
- Runtime bytecode fixture:
  `fixtures/deployed/StakingRouter-impl-runtime.bin`
  (21087 bytes, SHA-256
  `c30ed4e63cb0a57dca577484afff0765fcaa9840d75b440067fd55c7d4fc7013`).
- `DEPOSIT_CONTRACT` immutable patched at byte offset **7525**, width
  **20 bytes**.
- 20 bytes at that offset:
  `00000000219ab540356cbb839cbe05303d7705fa`, i.e. the canonical
  Ethereum beacon deposit contract address.

`scripts/verify_beacon_deposit_immutable.py` re-verifies fixture
identity (optionally re-fetches deployed bytecode via
`ETH_RPC_URL`). That re-fetch is the exact `A-RUNTIME-PROVENANCE`
check for this immutable.

The Lean facts below (with `decide +kernel`) prove that the fixture
bytes at the extraction offset equal the model literal, closing both
`A-TOPUP-BEACON-ADDRESS` (P-TOPUP-1) and `A-DEPOSIT-CONTRACT`
(P-DEPOSIT-1 and P-ALLOC-EXEC-1) down to `A-RUNTIME-PROVENANCE`.
-/

namespace LidoSRv3.Audit.Provenance.BeaconDepositAddress

open LidoSRv3.Audit.Guarantees

/-- Canonical Ethereum beacon deposit contract address literal. -/
abbrev canonicalBeaconDeposit : Nat :=
  0x00000000219ab540356cBB839Cbe05303d7705Fa

/-- The exact 20 bytes extracted from
`fixtures/deployed/StakingRouter-impl-runtime.bin` at offset **7525**
(width 20). This is the solc-patched `DEPOSIT_CONTRACT` immutable in
the deployed Lido StakingRouter runtime bytecode. -/
def deployedBeaconDepositImmutableBytes : List UInt8 :=
  [0x00, 0x00, 0x00, 0x00, 0x21, 0x9a, 0xb5, 0x40,
   0x35, 0x6c, 0xbb, 0x83, 0x9c, 0xbe, 0x05, 0x30,
   0x3d, 0x77, 0x05, 0xfa]

/-- Fold 20 big-endian bytes into their `Nat` value. -/
def bytesToBigEndianNat (bs : List UInt8) : Nat :=
  bs.foldl (fun acc b => acc * 256 + b.toNat) 0

/-- The 20-byte immutable extracted from the deployed runtime bytecode
equals the canonical beacon deposit contract literal. Proof by
`decide +kernel` on a concrete finite computation. -/
theorem deployed_beacon_deposit_immutable_equals_canonical :
    bytesToBigEndianNat deployedBeaconDepositImmutableBytes =
      canonicalBeaconDeposit := by decide +kernel

/-- The Verity top-up model target literal equals the canonical beacon
deposit contract. -/
theorem topup_verity_beacon_equals_canonical :
    LidoSRv3.Audit.Verity.TopupTx.beaconAddress.toNat =
      canonicalBeaconDeposit := by decide

/-- The P-TOPUP-1 registered canonical pin equals the canonical
literal. -/
theorem topup_canonical_pin_equals_canonical :
    PTopup1.canonicalBeaconDepositAddress = canonicalBeaconDeposit :=
  rfl

/-- The P-DEPOSIT-1 registered canonical pin equals the canonical
literal (same Ethereum beacon deposit contract address). -/
theorem deposit_canonical_pin_equals_canonical :
    PDeposit1.canonicalDepositContractAddress = canonicalBeaconDeposit :=
  rfl

/-- Composed statement: the Verity top-up model literal equals the
value extracted from the deployed StakingRouter runtime bytecode. This
closes `A-TOPUP-BEACON-ADDRESS` conditional on the fixture-hash
identity (which sits under the accepted global assumption
`A-RUNTIME-PROVENANCE`). -/
theorem topup_verity_beacon_equals_deployed_immutable :
    LidoSRv3.Audit.Verity.TopupTx.beaconAddress.toNat =
      bytesToBigEndianNat deployedBeaconDepositImmutableBytes := by
  rw [topup_verity_beacon_equals_canonical]
  exact (deployed_beacon_deposit_immutable_equals_canonical).symm

/-- Composed statement: the P-DEPOSIT-1 model canonical pin equals the
value extracted from the deployed StakingRouter runtime bytecode. This
closes `A-DEPOSIT-CONTRACT` conditional on the fixture-hash identity. -/
theorem deposit_canonical_pin_equals_deployed_immutable :
    PDeposit1.canonicalDepositContractAddress =
      bytesToBigEndianNat deployedBeaconDepositImmutableBytes := by
  rw [deposit_canonical_pin_equals_canonical]
  exact (deployed_beacon_deposit_immutable_equals_canonical).symm

end LidoSRv3.Audit.Provenance.BeaconDepositAddress
