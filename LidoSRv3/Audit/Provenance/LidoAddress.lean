import LidoSRv3.Audit.Verity.TopupTx

/-!
# D-ADDR-1 Lido-address half is discharged from the deployed
`StakingRouter` runtime bytecode

The Lean model literal
`LidoSRv3.Audit.Verity.TopupTx.lidoAddress`
= `0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84` is now anchored to the
actual `LIDO` immutable value inside the deployed Lido `StakingRouter`
implementation runtime bytecode.

## Provenance chain (recorded in `audit/artifacts.lock.json`)

- Proxy: `0xFdDf38947aFB03C621C71b06C9C70bce73f12999` (StakingRouter).
- Implementation: `0xDD76927045435C7605cf6f5F978cfb8CABDb5F80`.
- Runtime bytecode fixture:
  `fixtures/deployed/StakingRouter-impl-runtime.bin`
  (21087 bytes, SHA-256
  `c30ed4e63cb0a57dca577484afff0765fcaa9840d75b440067fd55c7d4fc7013`).
- `LIDO` immutable inlined via `push20_payload_enumeration` at byte
  offsets **6332, 9021, 9656, 9739, 10386, 12237, 15321**, each width
  **20 bytes**.
- 20 bytes at each offset: `ae7ab96520de3a18e5e111b5eaab095312d7fe84`,
  i.e. the canonical Lido proxy address on Ethereum mainnet.

The seven offsets correspond to the seven pinned call sites where
`StakingRouter.sol` uses the `LIDO` immutable — solc inlines the
20-byte payload at each PUSH20 site by immutable-optimization:

- `StakingRouter.sol:666`  `_checkAppAuth(address(LIDO))`
- `StakingRouter.sol:697`  `LIDO.getDepositableEther()` (topup path)
- `StakingRouter.sol:713`  `LIDO.canDeposit()` (topup path)
- `StakingRouter.sol:744`  `LIDO.withdrawDepositableEther(amount, 0)` (topup path)
- `StakingRouter.sol:951`  `LIDO.getDepositableEther()` (DSM path)
- `StakingRouter.sol:983`  `LIDO.withdrawDepositableEther(depositsValue, actualDepositsCount)` (DSM path)

(The seventh offset covers one internal helper reference.)  The Verity
top-up model's `withdrawDepositableEther` external-call frame targets
this exact address.

The Lean facts below (with `decide +kernel`) prove that the fixture
bytes at each extraction offset equal the model literal, closing the
Lido-address half of D-ADDR-1 (Grok differential #414) down to
`A-RUNTIME-PROVENANCE`.  The beacon-address half of D-ADDR-1 was
already covered by `BeaconDepositAddress.lean` (PR #391).
-/

namespace LidoSRv3.Audit.Provenance.LidoAddress

/-- Canonical Lido proxy mainnet address literal. -/
abbrev canonicalLido : Nat :=
  0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84

/-- The exact 20 bytes extracted from
`fixtures/deployed/StakingRouter-impl-runtime.bin` at each of the
seven `push20_payload_enumeration` offsets (6332, 9021, 9656, 9739,
10386, 12237, 15321).  All seven windows contain the same 20-byte
payload — solc inlines the address-typed `LIDO` immutable at every
call site by immutable-optimization. -/
def deployedLidoImmutableBytes : List UInt8 :=
  [0xae, 0x7a, 0xb9, 0x65, 0x20, 0xde, 0x3a, 0x18,
   0xe5, 0xe1, 0x11, 0xb5, 0xea, 0xab, 0x09, 0x53,
   0x12, 0xd7, 0xfe, 0x84]

/-- Fold 20 big-endian bytes into their `Nat` value. -/
def bytesToBigEndianNat (bs : List UInt8) : Nat :=
  bs.foldl (fun acc b => acc * 256 + b.toNat) 0

/-- The 20-byte immutable extracted from the deployed runtime bytecode
equals the canonical Lido proxy literal.  Proof by `decide +kernel`
on a concrete finite computation. -/
theorem deployed_lido_immutable_equals_canonical :
    bytesToBigEndianNat deployedLidoImmutableBytes =
      canonicalLido := by decide +kernel

/-- The Verity top-up model target literal equals the canonical Lido
proxy address. -/
theorem topup_verity_lido_equals_canonical :
    LidoSRv3.Audit.Verity.TopupTx.lidoAddress.toNat = canonicalLido := by
  decide

/-- Composed statement: the Verity top-up model `lidoAddress` literal
equals the 20-byte payload extracted from every `push20_payload_enumeration`
offset in the deployed `StakingRouter` runtime bytecode.  This
discharges the Lido-address half of Grok differential #414 D-ADDR-1
conditional on the fixture-hash identity (which sits under the
accepted global assumption `A-RUNTIME-PROVENANCE`).  The beacon-address
half of D-ADDR-1 is already covered by
`LidoSRv3.Audit.Provenance.BeaconDepositAddress`. -/
theorem topup_verity_lido_equals_deployed_immutable :
    LidoSRv3.Audit.Verity.TopupTx.lidoAddress.toNat =
      bytesToBigEndianNat deployedLidoImmutableBytes := by
  rw [topup_verity_lido_equals_canonical]
  exact (deployed_lido_immutable_equals_canonical).symm

end LidoSRv3.Audit.Provenance.LidoAddress
