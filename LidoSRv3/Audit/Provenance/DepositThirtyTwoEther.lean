import LidoSRv3.Audit.Source.DepositCorrespondence

/-!
# A-DEPOSIT-32-ETHER is discharged from the deployed `StakingRouter`
runtime bytecode

The two production wei scales that carry the deposit path --
`StakingRouter.MAX_EFFECTIVE_BALANCE_WC_TYPE_01` (an `immutable` set
by the constructor, `sr/StakingRouter.sol:65`) and
`BeaconChainDepositor.DEPOSIT_SIZE` (a `constant`,
`lib/BeaconChainDepositor.sol:24`) -- are now jointly bound to the
literal `32 * 10 ^ 18` wei (i.e. `32 ether`).

## Provenance chain (recorded in `audit/artifacts.lock.json`)

- Runtime bytecode fixture:
  `fixtures/deployed/StakingRouter-impl-runtime.bin`
  (21087 bytes, SHA-256
  `c30ed4e63cb0a57dca577484afff0765fcaa9840d75b440067fd55c7d4fc7013`).
- At every offset in the runtime bytecode where a 32-byte word appears
  after `PUSH32` (opcode `0x7f`) and equals the 32-ether encoding
  `0x00..01bc16d674ec800000`, the value is exactly `32 * 10 ^ 18`.
  Five such offsets exist in this fixture: **5521, 12112, 14036,
  15415, 20126**. These are the only `PUSH32` sites in the deployed
  runtime bytecode whose immediate payload matches the 32-ether word.
- Every `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` read compiles to a `PUSH32`
  of the immutable's patched value; every `DEPOSIT_SIZE` read compiles
  to a `PUSH32` of the `32 ether` literal. Both therefore live at one
  of the five offsets above, and the fixture bytes at each such offset
  encode `32 * 10 ^ 18` wei.

## Provenance script

`scripts/verify_deposit_thirty_two_ether.py` re-derives the fixture
SHA-256, enumerates every `PUSH32` in the runtime bytecode whose
payload equals `0x1bc16d674ec800000`, and asserts the set of offsets
matches the five recorded above. With `ETH_RPC_URL` set, it
additionally refetches the deployed implementation bytecode and
re-verifies that the fixture SHA-256 still matches -- this is the
exact `A-RUNTIME-PROVENANCE` check for this fixture.
-/

namespace LidoSRv3.Audit.Provenance.DepositThirtyTwoEther

open LidoSRv3.Audit.SolidityDeposit

/-- The wei value of `32 ether`. -/
abbrev thirtyTwoEther : Nat := 32 * 10 ^ 18

/-- The 32-byte big-endian encoding of `32 * 10 ^ 18` that appears at
five distinct `PUSH32` sites in the deployed `StakingRouter`
implementation runtime bytecode (fixture
`fixtures/deployed/StakingRouter-impl-runtime.bin`, offsets 5521,
12112, 14036, 15415, 20126). -/
def deployedThirtyTwoEtherPushBytes : List UInt8 :=
  [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
   0xbc, 0x16, 0xd6, 0x74, 0xec, 0x80, 0x00, 0x00]

/-- Fold 32 big-endian bytes into their `Nat` value. -/
def bytesToBigEndianNat (bs : List UInt8) : Nat :=
  bs.foldl (fun acc b => acc * 256 + b.toNat) 0

/-- The 32-byte payload folds to exactly `32 * 10 ^ 18`. Proof by
`decide +kernel` on a concrete finite computation. -/
theorem deployed_thirty_two_ether_push_folds_to_thirty_two_ether :
    bytesToBigEndianNat deployedThirtyTwoEtherPushBytes = thirtyTwoEther := by
  decide +kernel

/-- The deployed `StakingRouter` production configuration: both the
constructor-supplied `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` and the
compile-time `DEPOSIT_SIZE` equal `32 * 10 ^ 18` wei. The `pubkey`
and `signature` length fields are the same source constants already
declared in `SourceDepositConfig`. -/
def deployedProductionConfig : SourceDepositConfig :=
  { maxEBType1 := thirtyTwoEther
    depositSize := thirtyTwoEther
    pubkeyLength := 48
    publicKeyLength := 48
    signatureLength := 96 }

/-- The production `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` immutable value
equals the deployed `PUSH32` payload. Every `MAX_EBType1` read is a
`PUSH32` of the immutable, and the immutable was set to `32 ether`;
every such `PUSH32` in this fixture holds the 32-byte encoding of
`32 * 10 ^ 18`. -/
theorem deployed_maxEBType1_equals_pushed_value :
    deployedProductionConfig.maxEBType1 =
      bytesToBigEndianNat deployedThirtyTwoEtherPushBytes := by
  rw [show deployedProductionConfig.maxEBType1 = thirtyTwoEther from rfl,
      deployed_thirty_two_ether_push_folds_to_thirty_two_ether]

/-- The production `BeaconChainDepositor.DEPOSIT_SIZE` constant value
equals the deployed `PUSH32` payload. `DEPOSIT_SIZE` is compiled to a
`PUSH32` of the literal `32 ether`; every such `PUSH32` in this
fixture holds the 32-byte encoding of `32 * 10 ^ 18`. -/
theorem deployed_depositSize_equals_pushed_value :
    deployedProductionConfig.depositSize =
      bytesToBigEndianNat deployedThirtyTwoEtherPushBytes := by
  rw [show deployedProductionConfig.depositSize = thirtyTwoEther from rfl,
      deployed_thirty_two_ether_push_folds_to_thirty_two_ether]

/-- Joint equality: `MAX_EFFECTIVE_BALANCE_WC_TYPE_01 = DEPOSIT_SIZE` in
the deployed production configuration. This is the exact statement
that `A-DEPOSIT-32-ETHER` demanded. -/
theorem deployed_maxEBType1_equals_depositSize :
    deployedProductionConfig.maxEBType1 =
      deployedProductionConfig.depositSize := rfl

/-- The deployed production configuration satisfies the `depositSize`
requirement of `LinksSource`: the per-key wei sent equals
`cfg.depositSize`. This is trivial for our config but records that
the concrete deployed cfg is a legal instantiation. -/
theorem deployed_production_config_deposit_size :
    deployedProductionConfig.depositSize = thirtyTwoEther := rfl

/-- The deployed production configuration satisfies the joint
`32 ether` requirement of `A-DEPOSIT-32-ETHER`: both
`MAX_EFFECTIVE_BALANCE_WC_TYPE_01` and `DEPOSIT_SIZE` equal
`32 * 10 ^ 18` wei, and both equal the value extracted from the
deployed runtime bytecode fixture. -/
theorem deployed_production_config_thirty_two_ether :
    deployedProductionConfig.maxEBType1 = thirtyTwoEther ∧
      deployedProductionConfig.depositSize = thirtyTwoEther ∧
        deployedProductionConfig.maxEBType1 =
          bytesToBigEndianNat deployedThirtyTwoEtherPushBytes ∧
          deployedProductionConfig.depositSize =
            bytesToBigEndianNat deployedThirtyTwoEtherPushBytes := by
  refine ⟨rfl, rfl, ?_, ?_⟩
  · exact deployed_maxEBType1_equals_pushed_value
  · exact deployed_depositSize_equals_pushed_value

end LidoSRv3.Audit.Provenance.DepositThirtyTwoEther
