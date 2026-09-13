import LidoSRv3.Audit.Verity.TopupTx

/-! # Kill-lines for `Verity.TopupTx.lidoAddress` and `beaconAddress`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the two pinned Verity-plane addresses used at
`Lido.sol:869-886` (Lido withdrawal call) and
`BeaconChainDepositor.sol:106` (deposit-contract call). -/

namespace LidoSRv3.Tests.VerityTopupTxAddressesKillLines

open LidoSRv3.Audit.Verity.TopupTx

/-- **Kill-line: `lidoAddress` = canonical mainnet Lido proxy.**

A mutant that changed one hex digit would refute the deployed-
immutable anchor. -/
theorem lidoAddress_pinned :
    lidoAddress.toNat = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84 := rfl

/-- **Kill-line: `beaconAddress` = canonical mainnet deposit contract.**

A mutant that changed one hex digit would refute the deployed-
immutable anchor. -/
theorem beaconAddress_pinned :
    beaconAddress.toNat = 0x00000000219ab540356cBB839Cbe05303d7705Fa := rfl

/-- **Kill-line: `lidoAddress ≠ beaconAddress`.**

A mutant that collapsed the two immutables to the same value would
refute the pinned two-target distinction. -/
theorem lidoAddress_ne_beaconAddress :
    lidoAddress.toNat ≠ beaconAddress.toNat := by decide

/-- **Kill-line: both addresses fit uint160 (address type).**

A mutant that expanded the address width would refute. -/
theorem lidoAddress_fits_uint160 :
    lidoAddress.toNat < 2 ^ 160 := by decide
theorem beaconAddress_fits_uint160 :
    beaconAddress.toNat < 2 ^ 160 := by decide

/-- **Kill-line: both addresses are non-zero.**

A mutant that zeroed either address would refute the ABI-anchored
identity. -/
theorem lidoAddress_nonzero :
    lidoAddress.toNat ≠ 0 := by decide
theorem beaconAddress_nonzero :
    beaconAddress.toNat ≠ 0 := by decide

#print axioms lidoAddress_pinned
#print axioms beaconAddress_pinned
#print axioms lidoAddress_ne_beaconAddress
#print axioms lidoAddress_fits_uint160
#print axioms lidoAddress_nonzero

end LidoSRv3.Tests.VerityTopupTxAddressesKillLines
