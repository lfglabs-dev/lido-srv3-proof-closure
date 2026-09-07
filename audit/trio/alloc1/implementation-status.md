# ALLOC-1 implementation status

This is implementation evidence for independent review. The original full scope
remains open; the draft PR is not certification-ready.

The producer reads physical word slots and the complete stored enumeration. It
performs summary calls, active-count subtraction, optional WC2 stake calls, and
checked total accumulation in source order, followed by the capacity pass. No
count truncation or assumed callee success is introduced.

## Implemented and checked

- `Storage`, `Execution`, `Properties`, `CapacitySpec`: actual slot formulas and
  packed widths, ordered executor, identities/lengths, independent Nat capacities,
  and checked-total bound derived from producer success.
- `FirstPass`, `Relational`, `Determinism`: least-ceiling/active-count properties,
  independent two-pass relational specification, and two-way SOURCE-executor
  equivalence for all modeled results and call transcripts.
- `Bytes`, `Memory`: codec inverses, trailing-returndata decoding, constructive
  byte-backed disjoint array relation, and output length from physical count.
- `CallTree`, `VerityProducer`: complete response-dependent call program,
  interpreter equivalence, actual pinned Verity call-VM execution from physical
  world word slots, and universal static-call world preservation. This does not
  establish compiler memory, gas, or bytecode equivalence.
- `ShareWriter`: public role/membership/guard order, packed update, derived stored
  share bound, other-slot preservation, and rejection snapshot restoration.
- `WriterInvariant`: empty-state count/share/address invariant and preservation
  through the public share writer, with finite slot separation explicit.
- `AdmissionChecks`: physical role and ordered admission guards, address freshness
  derived from the complete duplicate scan, count below 32 on success, and checked
  uint24 last-ID increment. This is the prefix before admission writes.
- `EnumerationWriter`: actual existing-ID no-op and absent-ID insertion, physical
  count/old/new elements and positions, wrap-aware array-slot injectivity, and
  preservation of one-based position consistency under finite slot separation.
  Consistency derives uniqueness of enumerated IDs; it is not yet composed with
  all admission/configuration/migration writes.
- `AllocationMemory`: exact word rounding, oversized-array panic 0x41, allocation
  monotonicity/limit on success, and a bounded allocation lemma. Integration of
  these primitives into the entire compiler execution remains open.

Twenty Init-only modules are included in the fresh light validation driver.
The full production/test/audit-trust/legacy build passed 1,505 jobs at
`8269ac576cf119975a7e9954459cd4aa04d5cd82`, remote job
`3ca9d1e4-e496-43f7-87f2-a5925a9bd083` on nippur. This is **STALE_SUCCESS** for
newer heads, not their full validation. Exact output is in `full-build-8269.json`.

The physical-world Verity bridge and fixtures built 37 remote jobs and executed
at `03abaac4f0e27fd8456fad8cc84e6f1e73b27c18`. All 12 independently executed
Solidity/Verity results or raw errors and ordered top-level call lists agree
(`solidity-verity-comparison.json`). The earlier mismatching late-rejection fixture
is preserved in `verity-vectors-a35-mismatch.json`; it was corrected to configure
the same rejecting second target as Solidity. The separate history-sensitive
SOURCE regression remains intact.

Pinned solc 0.8.25 via-IR/optimizer-200 Shanghai execution also checked:

- Both internal arrays at actual root RETURN memory snapshots: allocation pointer
  256; capacity pointer `544 + 928*count + 160*wc2Count`; disjoint ranges and exact
  elements, including empty arrays (`solidity-memory.json`).
- Public share-writer packed-word preservation, event ABI, six exact error-order
  cases, unchanged storage and no events on rejection (`writer-*.json`).
- Public admission: fourteen exact rejections and one successful insertion
  (`admission.json`). Six late failures execute five distinct slot writes each;
  every attempted slot is compared before/after the reverted transaction and is
  restored, with no committed events. Includes uint24 last-ID overflow, fee-sum
  arithmetic panic, and duplicate/credential/count/name/role precedence.
- Nested read callback and rejected mutation CALL under static context: expected
  three call sites, unchanged module storage, no events (`callback.json`).
- Actual compiler storage layout and two executed parent-shaped mutants, plus
  formal witness theorems refuting the corresponding independent specification.

The test harness uses Shanghai because its Ganache engine lacks Cancun support;
these are pinned-source executions, not a production Cancun bytecode receipt.

## Interface and coordination

`Interface.lean` is byte-identical to accepted checkpoint
`2a4e9d2a91d257353470677c6101fd91293cf4e4`. Consumer written acceptance was
verified at ALLOC-2 commit `b279d572b694a9e106fdf61337323fbe5f6d3d33`; matching
producer confirmation is in `interface-agreement.md` and was sent through the
orchestrator. No incompatible change is proposed. ALLOC-2's isolated composition
pins producer8269ac and has its own receipts; it is not silently integrated here.

## Remaining original gates

| Requirement | Remaining work |
| --- | --- |
| Physical state reachability | All admission/update/migration writer transitions, count<=32 and unique-address derivations; explicit finite storage separation and deployment/hash relation. One share writer is not all-writer reachability. |
| Compiler memory and ABI | Universal allocation schedule and array-write refinement, allocation panic precedence, live producer byte extent and consumer ABI composition. Executed snapshots and constructive codec lemmas are not the whole proof. |
| Transaction composition | Parent checked wei conversions, sequential behavior, complete nested-call observation relation and rollback composition with ALLOC-2. |
| Integration and full validation | Current-head production/test/trust, make prove/test, canonical source inventory/metadata integration and independent certification. The shared UX2 gate is consumer-owned; no shared file is regenerated here. |
| Delivery | Draft PR245 is open. Final implementation and immutable-source validation are still required. No merge, deployment, public-site publication or Lido message. |

Migration-specific boundary: `SRLib._migrateStorage` copies legacy count and share
fields without rechecking the public admission limits. Its version check is not
a proof of legacy state reachability. The remaining migration theorem must connect
the legacy writers/deployment state to these bounds; it must not assume that a
successful migration alone implies count<=32, bounded shares, or unique addresses.

Infrastructure diagnostics and measured estimates are recorded in `reproduce.md`
and `receipts/remote-admission-sizing.json`. The full build uses 5 GiB; the measured
small Verity vector closure uses 2 GiB. The emergency disk floor is unchanged.

Latest owned closure: remote job a80e40c0-3f5d-40a4-9c02-1cccf8a8f635
passed 46 jobs at fcfa841970ef7dc690083f59c58b30a722185039, inspected eleven
critical theorems (only propext, Classical.choice, Quot.sound), and reran all twelve
Verity fixtures. The independently executed Solidity comparison passed again.
Receipts: verity-trust-fcfa841.json and solidity-verity-fcfa841.json. This closure
receipt does not replace current-head full-suite validation.
