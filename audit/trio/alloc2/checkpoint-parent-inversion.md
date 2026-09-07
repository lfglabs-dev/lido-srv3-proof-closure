# Parent outcome inversion

ParentInversion derives actual division and producer success from a successful
nonempty decoded parent execution. It proves that the producer transcript is
the final parent transcript and derives DecodedConsumerPremises from that
actual producer execution. The complete success split also covers the empty
count branch that bypasses division and returns empty arrays.

Failure classification has no producer-success, division-success or nonempty
premise. An actual decoded parent failure implies either division by zero
before producer execution, an identical producer failure and transcript, or
successful producer execution followed by conversion panic 0x11. The producer
failure propagation theorem preserves every Failure constructor, including raw
revert bytes and decoder/exceptional failures.

Composition receipt e4079b62-cb45-4f69-819c-739ca3496339 succeeded on ashur:
44 jobs and 43 exact source/config files. Runtime receipt
95af37dc-73bd-4a6e-8d1b-726301682ba3 succeeded on ashur: 47 jobs and the
47-file source/config closure. Neither successful log contains sorryAx.
The earlier old-agent inversion job 6ea792c7-3753-4ec1-9b33-7c68d720f696
was reconciled as queued and targets an earlier proof draft. It was not counted
as failed. The first ashur draft failed with proof-script errors and its receipt
is retained without claiming success.

The decoded executor still omits compiler memory/gas effects. Inspection of the
pinned optimized SRLib IR identifies the next allocation stage: after the two
arrays and count cache structs, finalize_allocation_31435 reserves 224 bytes for
the initial ModuleStateConfig (IR line 2073). Each storage-to-config load
reserves another 224 bytes (read_from_storage_reference_type_struct_ModuleStateConfig,
lines 2747 onward). These follow the segment modeled by MemoryPrefix; that
segment is not the entire schedule before module calls. The later allocations,
zeroing, stores, ABI/copy and full compiled-parent relation remain open.

The latest observed producer head 56787713037c736aea4593f36b5907aa1e81551a
changes admission/writer modules, but none of the seven consumed modules differs
from the validated 8691c78 pin. Interface acknowledgment and the additional
memory schedule finding were queued to ALLOC-1 as messages
8e0d2dc4-722e-49d1-b9b5-a883e86a5368 and
12582384-5332-43e6-81e7-067360a8544f. Final agreement and integration remain
open, alongside universal memory/frame proofs, real full make prove/test and
independent certification.

Further IR inspection: a successful summary call finalizes 96 bytes
(fun_getStakingModuleSummary, line 3341 onward); a successful type-2 stake call
finalizes 32 bytes (parent IR lines 2160 onward). The capacity array is allocated
after the first scan. Counting these observed stages suggests a producer-success
free-pointer increment of 576*n + 32*k + 320, where k is the number of type-2
stake calls. This is an inspection-derived candidate formula, not a proved
schedule theorem or a replacement for explicit failure ordering. It excludes
the parent's later external-library encoding/return and conversion allocations.

Validation refresh: byte differential 702ba347-1abe-4189-b44e-4f8bbfdbf2f7
exited 0 with 127 comparisons. Parent/frame/mutant job
eb23276a-4ff8-4089-99f7-386b9725bbae exited 0 with 24 passing cases and
six semantically rejected mutants. Metadata, UX2 artifacts, proof escapes and
source annotations passed in 46f40007-d9d8-4107-bb4f-1686f4959dea.
