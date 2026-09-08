# Integrated follow-up review

## Inputs and disposition

- PR252, `64ae83be`: reviewed and compiled AllocationTx and its live regression
  module before merging on GitHub as `cd1a16d5`. The added injected rollback
  result belongs to the older AllocationTx wrapper, not the composed main
  source-memory executor. No main claim is strengthened by that result alone.
- PR250, `d3c4fb5b`: the metadata correction was already cherry-picked. Review
  identified contradictory vault-premise descriptions in the canonical registry
  and theorem docstring. Those now consistently require positive value received
  by the vault; positive outer payment is insufficient. The registry review
  basis is advanced to the exact editorial correction commit `db7d515b` and the
  generated report explicitly disclaims new independent certification. Original
  registrations, theorem statements, statuses and trust allowances are retained.
- `p-account-1-address-1` at `e04136dd` and its bounded successor at `39991771`:
  integrated the original slice plus bounded-owner corrections. Replaced new
  native-decision test proofs with kernel-checked `decide`, added a root Lake
  target to the test gate, and documented supplied inputs, unsupported batch
  shapes, grouped errors and missing full-call correspondence. These isolated
  slices do not close the registered accounting or address claims.
- PR252 moves existing native-decision lines in its test file. The tactic
  inventory was refreshed only after comparing parsed old/new sites and
  confirming identical paths and tactic text. No new use was allowed.

## Small proof improvement

`TrioComposition.CacheStores` models the five cache field writes and their
second-pass reads from SRLib.sol:513-552, with offsets also inspected in the
recorded SRLib compiler artifact. It proves field readback, derives each row's
address bounds from the existing allocation geometry, proves the writes preserve
both output arrays, and proves the resulting memory-based capacity calculation
has exactly the existing row calculation's outcome (including errors).

This is a constituent proof, not main-parent composition. Omitted configuration,
hash and return-buffer writes, pointer-table readback, placement of cache writes
around external calls and compiler byte-memory interpretation remain open.
Wrong field offsets, missing writes, wrong capacity reads and overlapping cache
addresses are compiled as mutations; the respective proof obligations must fail.

## Remaining trio boundaries and supporting evidence

| Boundary | What actually limits the risk | Remaining work |
|---|---|---|
| ALLOC1/2 omitted writes | CacheStores proves the five fields' reads, their use in capacity calculation and derived-address array preservation. Existing word-copy and array-geometry proofs cover their stated operations. | Compose these stores at their original positions in the parent and cover other omitted buffers; retain compiler interpretation. |
| ALLOC1 other histories | LifecycleHistory proves invariants from the modeled proxy initialization through ACL, share, parameter, admission and status updates, including rejection. | Migration and missing writer paths are not in that induction; this is larger than another bound lemma. |
| ALLOC2 actual library | The source library/ABI model has allocation and transport correspondence; the Verity parent executes module static calls. | The parent records rather than executes deployed DELEGATECALL; integrating that execution is a separate interpreter task. |
| ALLOC2 nested calls | VerityParent covers the stated module responses/errors and source call observations. | Full recursive callback observations and deployed callee correspondence remain outside the interpreter. |
| RESERVE callbacks | Pipeline has concrete success, rejection and shortage results for its specified recipient; separate callback rules check named vault admission/update paths. | Those callback components are not a theorem that arbitrary successful recipient callbacks preserve the reserve. |
| RESERVE EVM execution | WithdrawalSpec and the concrete pipeline prove outcome/rollback and physical storage properties within the explicit transaction interpreter. | A refinement to full Verity EVM semantics is substantial infrastructure work, not implied by shared storage types. |
| RESERVE other updates | PhysicalSequence relates modeled spends, target updates and rebalances; it proves other-account/queue preservation under its premises. | Full queue writers, report admission, migrations and arbitrary update sequences are not composed. |

No unresolved row is removed from the website solely because a supporting leaf
exists. Deployment, compiler, hash and consensus assumptions remain explicit.
Gas verification and arbitrary future upgrades remain outside this program.
