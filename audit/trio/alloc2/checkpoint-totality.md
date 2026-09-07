# Totality, exact decoded errors, and candidate composition — full scope remains open

The previous turn was progress (selection correspondence, Solidity execution,
and scoped draft PR). The public draft is #246 on the owned proportional branch.
Checkpoint 77deca452be85fe22ab180de2efeb7b833eec45a remains recoverable; the
pre-current-main branch is preserved as checkpoint/alloc2-before-current-main.

New checked arithmetic/totality results:

- `ceilDiv_success` derives all intermediate operations and the exact unbounded
  `(a+b-1)/b` result for b != 0. `ceilDiv_zero_denominator` preserves zero-numerator
  guard precedence; no arithmetic success is a premise.
- `initialScan_success`, `secondScan_success`, and `initialScan_selected_row`
  derive successful scans and actual paired reads. No fixed module cap is assumed.
- `step_success` proves all candidate-step operations succeed from sufficient
  capacity length and bucket length <2^256, allowing zero/saturated/overfull rows.
- `allocateLoop_success` and `allocate_success` prove whole decoded-loop success;
  the accumulator is bounded by the remaining demand at every actual step.
- Short capacities with positive demand produce arrayBounds. `allocate_success_iff`
  states the exact decoded success condition: zero demand or sufficient capacities,
  for a representable bucket length. Byte decoding and panic bytes remain separate.

Final owned-slice receipt: 0af9fe87-bfdf-4fbc-ad93-7d5bf2dae555 on ashur,
exit 0, 21 jobs. Intermediate failure receipts record proof-script fixes. No
project axioms or escapes were introduced. Exact source identities are in
`differential-source-identity.json`. Solidity differential execution was rerun
against this receipt; see `solidity-execution.json` for the 105 comparisons.

Actual-producer composition is now proved against producer candidate
5f1683eaf753ff73aec6f1e787cb7f68bedcf056 in the separate owned composition
validation target. The accepted v0 interface is byte-unchanged. Both named bridge
and producer-then-consumer result derive from actual produce success, including
storage-count-derived length bounds; they assume neither a compatible-memory
predicate nor successful intermediate arithmetic. See composition/README.md for
precise decoded scope, 21-job receipt and remaining integration obligations.
Explicit producer agreement remains pending; no producer files were changed.

UX2 regression suite passed at immutable PR head
53ff80f86b344e7c481b1feb79a9ba8f5a237457, with real pinned Lean syntax execution.
`ux2-head-receipt.json` records the exact command and output. New source files
require the usual regeneration and current-head regression rerun; no check was
weakened or removed.

Full production/test/trust remote job 4090a961-f137-4909-bc68-c19a42879623
on old-agent completed successfully, exit 0, 1512 jobs. It covers the earlier
current-main + c275911 source overlay, not the subsequent PR heads. Its exact
terminal receipt is retained. The latest candidate still requires full targets,
make prove (which builds production AND legacy), make test and trust validation.

Original remaining scope: complete Spec.choose/step/Distributes correspondence,
row-wise bounds, actual memory/ABI, parent checked conversion and observations,
Verity execution differentials, parent-shaped mutants, arbitrary rejection and
late rollback, full current-head prove/test/trust receipts, producer integration,
and independent certification readiness. The checked decoded composition is not
a claim that these outstanding source/parent boundaries are closed. No merge,
site deployment, Lido message, or unrelated PR mutation occurred.
