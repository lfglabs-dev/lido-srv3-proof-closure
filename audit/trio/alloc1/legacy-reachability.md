# Legacy reachability source investigation

This is a source investigation, not a migration theorem or deployment attestation.
The local pinned core checkout includes history. Tag v2.2.0 resolves to immutable
commit `4bf7742aed332c363f3e74ffc8199d197e468ea4`.
Its `contracts/0.8.9/StakingRouter.sol` is a concrete version-3 predecessor candidate:

- `initialize` sets contract version 3. `finalizeUpgrade_v3` checks version 2 and
  changes only version metadata. Neither establishes bounds for arbitrary storage.
- `addStakingModule` checks count below 32, then scans every old module address
  for duplication. It assigns a checked uint24 next ID, writes the indexed record,
  position mapping, last ID and count, then invokes `_updateStakingModule`.
- `_updateStakingModule` checks share and threshold at most 10000 and their order
  before packed writes. A later failure reverts the earlier admission writes.
  Both fee-sum bounds are `> 10000`, but the current helper additionally scans
  other modules for fee consistency; legacy max-deposits validation permits zero.
  Reusing the current writer verbatim
  would therefore change successful legacy executions.
- The legacy layout is an index-keyed module mapping and a separate one-based ID
  index mapping. Current storage uses an ID-keyed module mapping and EnumerableSet.
  Physical correspondence must map these layouts rather than equate their slots.

Current `contracts/0.8.25/sr/SRLib.sol::_migrateStorage` accepts expected version 3,
copies legacy count by enumerating indexed records, inserts each old ID, and copies
share/address fields without the admission guards. It also copies names, casts
status, safely casts deposit/accounting fields, invokes summary calls, accumulates
balances and clears old storage. Success alone cannot supply legacy reachability.

Outstanding: identify the authorized implementation/upgrade history, model its
physical writes and base initialization, prove writer preservation across that
history, and compose the resulting predicate with the actual ordered migration.
The tag above supplies source evidence only; it is not assumed to be the deployed
predecessor merely because its stored version is compatible.
