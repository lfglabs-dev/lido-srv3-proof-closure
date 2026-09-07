# Required shared integration patch (not applied)

Pinned core: `17005714f151e5502c559932319a3f2f74ac2436`. Keep existing
declarations and guarantee statuses until the integrator validates replacements.
This note specifies inventory additions; it does not authorize or claim canonical
integration or independent certification.

## Source graph and producer cut

Add `SRLib._getModulesAllocationAndCapacity` (SRLib.sol:493–559) as the producer
cut inside `_getDepositAllocations` (391–431), before external MinFirst execution.
The parent's zero-count return and wei/validator conversions remain outside this cut.

Record these edges and corresponding owned modules:

| Source operation | Model |
| --- | --- |
| SRStorage.getModulesCount/getModuleIdAt/getModuleState, SRTypes packed config/accounting | Storage, Execution.firstRow/firstLoop |
| SRStorage.getIStakingModule, SRLib._getStakingModuleSummary, IStakingModule.getStakingModuleSummary | Execution.staticCall/decodeSummary |
| WithdrawalCredentials.isType2, SRStorage.getIStakingModuleV2, IStakingModuleV2.getTotalModuleStake | Execution.firstRow/decodeStake |
| Math.max, checked subtraction/addition, Math.ceilDiv | Execution checked operations; FirstPass |
| Second loop active/top-up branches, multiplication/division/min | Execution.rowCapacity/secondLoop; CapacitySpec |
| Complete two-pass execution and failures | Relational, Determinism, CallTree, VerityProducer |
| Array representation and actual bytes | Interface, Bytes, Memory; AllocationMemory primitives |

Inventory physical router slots: root mapping, root+1 enumeration length,
root+2 position mapping, root+3 accounting, root+4 credentials, root+5 packed
last-ID/top-up limit. Enumerated elements start at keccak(root+1). Module records
start at keccak(id,root): config at +0, deposits +1, accounting +2, name +3.
Record field widths from `interface-proposal.md` and the compiler layout receipt.

## Writers and initialization obligations

Add public updateModuleShares -> SRLib._updateModuleShares (ShareWriter),
updateStakingModule -> _updateModuleParams/_requireConsistentFeeSum
(ParameterWriter), and addStakingModule -> _addModule -> EnumerableSet.add,
name storage, _updateModuleParams, last-ID, _updateModuleLastDepositState
(AdmissionChecks, EnumerationWriter, StringStorage, AdmissionWriter).
Their role/membership guards read physical storage. WriterInvariant covers the
share and parameter updates. AdmissionFacts covers public admission invariant
preservation under finite layout and the FreshRecords storage predicate; the
RecordInvariant now establishes both predicates for histories of admission, share
and parameter writers from zero storage. Full lifecycle induction, including
initialization and migration, remains pending.

Migration `_migrateStorage`, all-fee updates, status/credential updates, and writes
to adjacent packed/accounting/deposit fields still need their frame/reachability
obligations discharged. Migration copies legacy shares/count without admission
revalidation. Do not turn a version check into a legacy-reachability premise.

## Deviations and gate wiring

Ghost module identities and transcripts are instrumentation. SOURCE state uses
word-addressed storage; keccak/root and finite separation remain explicit deployment
relations. Verity uses the pinned call-VM world adapter, not deployed bytecode.
Compiler memory schedule/ABI composition, transaction gas and full consensus truth
are not established by the call-VM theorem. Array-allocation primitives and executed
memory snapshots do not alone close the universal producer/consumer memory bridge.
Typed public writer inputs do not prove malformed top-level calldata rejection.
Writer outcomes record committed events/state; attempted storage writes are observed
by separate Solidity traces. The capacity cut makes zero-value static calls only.

Wire all owned source/test imports into production/test/audit roots only during
coordinated integration; add the selected axiom checks from InspectAxioms.lean and
actual Verity execution driver. Update canonical source-map/guarantee metadata and
regenerate inventory/UX2 artifacts together. Run make prove/test and metadata,
annotation, inventory, provenance and trust gates on that immutable integrated head.
ALLOC-2 owns consumer composition and its shared UX2 integration. No website or
guarantee-status update should present these partial gates as completed correspondence.

StatusWriter extends the physical configuration writer coverage and history
induction to public status changes. Remaining ordinary storage writers include
the fee batch (SRLib 315-337), exited-validator/accounting reports (748-891),
last-deposit updates (894-901), router top-up cap (StakingRouter 1023-1028),
withdrawal credentials plus notification callbacks (1036-1043; SRLib 903-920),
and inherited ACL/initialization writes. Each requires actual packed-field or
other-slot preservation, including callback and rejection composition where
present. A text assignment inventory is not a source-correspondence theorem.
