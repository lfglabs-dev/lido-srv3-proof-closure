# Scan correspondence and differential execution — still incomplete

The previous turn made progress by committing five scan bounds at c275911.
This continuation adds `ScanCorrespondence.lean` and `Selection.lean`:

- Actual successful first-scan allocation equals the fold minimum of independently
  filtered open Nat row levels.
- Its exact count equals the number of rows at that final level (with a precise
  incoming-candidate contribution for the general scan).
- Its index is the first open row at the final minimum; incoming candidates win
  ties when their minimum survives.
- Actual second-scan result equals the fold minimum over strictly higher open rows.
- Word-open levels are strictly below the sentinel. The initial scan's optional
  minimum agrees with Spec.minimum; count zero iff no rows are open.

These are checked scan/specification projections. They do not yet prove the whole
Spec.choose/step/Distributes correspondence or any byte-memory/ABI representation.

Remote final slice: 60f2c38c-dce8-4ee6-8344-f300fec330b9 on ashur, exit 0,
17 jobs. Individual receipts record intermediate errors and their corrections.
`differential-source-identity.json` binds all 16 source/config files to the final
verified overlay. Axiom inspections use only standard Lean propext, Quot.sound,
and (for secondScan_higher_minimum) Classical.choice; no project axioms added.

The final slice actually emits 32 execution vectors. A local in-process EVM
compiled and executed the exact pinned Solidity source with solc 0.8.9, optimizer
200, Istanbul (one configuration in the pinned core repository). The runner
compares 105 raw return/revert results, including direct and delegated library
calls, internal step, caller-array copying, ceilDiv boundaries, and malformed ABI
with zero demand. See solidity/trio-alloc2/README.md for exact commands and limits.
The runner rejects stale source manifests and missing vectors. Its first attempt
rejected 31 vectors because Lean prefixed the first output with a source-location
message; parsing was corrected to recognize that exact format, retaining the
required 32-vector check. Optional µWS native module is absent for Node 18.19.1;
Ganache used its JS fallback. No existing credentials were inspected.

UX2 regression result: exit 0 on local integration commit
4e29275916c8ddb357b5f55ed88ebe57747e1ea7, based on current main
bcfbb5f027a5c370594891c1a455fde137709941 and the earlier c275911 sources.
Exact command: ELAN_HOME=/tmp/pr241-elan
PATH=/tmp/pr241-elan/toolchains/leanprover--lean4---v4.31.0/bin:$PATH
python3 scripts/test_ux2.py. Private dependency checkouts match all 11 manifest
pins. Earlier failures were untracked-source rejection and then a Lake shim
missing the installed binary. Neither guard was weakened. This is an earlier
candidate receipt; latest source changes require regeneration and rerun.

Full remote build job 4090a961-f137-4909-bc68-c19a42879623 on old-agent
remains running at last authoritative observation (past 780 dependency modules).
It tests the earlier main-plus-c275911 overlay. Reconcile that exact handle before
another full submission; even success will not certify subsequent source changes.

ALLOC-1 remains running; no revised producer interface or success theorem has
been adopted. The full original objective remains open, including entire
selection/loop source correspondence, arithmetic success, memory/ABI, actual
producer composition, Verity differential execution, parent effects/rollback and
mutants, current-candidate full prove/test/trust gates, and independent review.
+1 remains separate and unmodified. A scoped draft PR is being prepared; no
completion or independent certification is claimed.
