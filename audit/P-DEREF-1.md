# P-DEREF-1 bounded receipt

Supplemental child evidence. Not a twelfth public guarantee.

Writer: `LidoSRv3/Audit/Guarantees/PDeref1.lean`.
Pin: `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

The model proves a registered module address is nonzero and 160-bit after
reachable `initialize`, one valid `_migrateStorage`, and `_addModule`. A
guarded Verity mapping transaction then returns that address and writes it to
the observation map.

Writers: `SRLib._migrateStorage` 51–155, `_addModule` 183–232, and later
status/accounting/parameter/share writers that do not change
`config.moduleAddress`. Mutants: `LidoSRv3/Tests/DereferenceMutants.lean`.

OPEN: old-layout migration bytes are an input. No claim on
`ROUTER_STORAGE_POSITION` hash, Solidity keccak map slots, packing, Yul,
`SLOAD`, proxy bytecode, or deployment. The Yul file is syntax only.
