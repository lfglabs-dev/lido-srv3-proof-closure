# P-DEREF-1 bounded receipt

Writer: `LidoSRv3/Audit/Guarantees/PDeref1.lean`.

Pinned source: `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

This is supplemental evidence, not a twelfth minimal-11 guarantee. The checked
model derives a registered address's nonzero and 160-bit bounds from reachable
`initialize`, valid one-time `_migrateStorage`, and `_addModule` states. It
then proves that a concrete executable Verity mapping transaction guarded by a
module-position mapping returns that source-model address and writes the same
address to its observation map.

The writer inventory includes the migration address copy in
`SRLib._migrateStorage` (51-155), `_addModule` (183-232), and the normal
post-migration status/accounting/parameter/share writers, which do not modify
`config.moduleAddress`. Guard-removal and address-replacement mutants remain
concrete regressions in `LidoSRv3/Tests/DereferenceMutants.lean`.

OPEN: the old-layout migration contents are an explicit input boundary; no
claim is made about `ROUTER_STORAGE_POSITION`'s computed hash, Solidity's
keccak mapping location, struct packing, compiler-generated Yul, emitted
`SLOAD` execution, proxy/runtime bytecode, or deployed provenance. The Yul
file is deliberately syntax-only and contains no exact-location theorem.
