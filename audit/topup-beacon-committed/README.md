# Committed TOPUP beacon ledger and physical capacity

Core pin: `17005714f151e5502c559932319a3f2f74ac2436`.
P-TOPUP-1 and P-TOPUP-2 remain OPEN. This increment supplies necessary
properties of executions that actually commit; it is not full delivery.

## Actual consumer chain

`BeaconChainDepositor.sol:72–106` checks the key width before skipping zero,
then the minimum wei amount and maximum uint64 gwei value before a deposit
CALL. `TopupBeaconBatch.loop` runs those guards and the complete serialized
source payload through `TopupBeaconEffects.push` / `Live.CallData.invoke`.
The latter invokes the actual accepted source-shaped beacon dispatcher and
body at `deposit_contract.sol:101–159`, in the same `Live.World`.
`StakingRouter.sol:746–754` reaches the helper through the accepted router
continuation; the new `helper_success_*` theorems consume that helper itself.

The body checks its physical slot32 count before incrementing it and inserting
the branch. `deposit_success_count` derives the count guard and final slot
value from successful execution, including branch insertion's independently
proved exclusion of slot32. `push_success_count` transports that property
through the real provisional value transfer and callee dispatch.
`loop_success_count` composes every increment and derives the final capacity
bound when at least one deposit occurs. This is physical storage, not a
counter in a receipt or auxiliary state.

`guarded_amount_fits` derives uint256 wei fit from the executed uint64-gwei
upper guard. `loop_success_balances` consumes the callee-body balance theorem
at each actual successful CALL and composes an independent pointwise ledger
relation for the mathematical sum of all allocations. It accepts arbitrary
input lists and includes aliased sender/recipient addresses. No initial
funding, key-width, minimum, capacity, alignment or non-alias hypothesis is
supplied to this successful-execution theorem. For distinct sender/recipient,
`committed_funding` derives initial aggregate funding as a consequence.
`run_success_balances` consumes the actual root rollback wrapper.

The actual helper returns immediately for empty public keys. Accordingly,
`helper_success_balances` and `helper_success_count` account for zero in that
branch, even if an arbitrary caller supplies a nonempty allocation list.
No outer length validation is silently supplied. A successful loop with no
nonzero allocations does not establish a bound on an arbitrary initial slot;
its count equation still proves that the slot is unchanged.

## Verification performed

The targeted build checks nine source theorems, one substantive positive
execution theorem and seven kernel examples. Nine source axiom queries and
five queries in the test module report only `propext`, `Quot.sound` and, where
inherited through the helper's inputs, `Classical.choice`. No new axiom,
`sorry`, `admit`, `native_decide` or supplied acceptance oracle is used.

The positive test constructs the actual source callee success with the
accepted changed-withdrawal-credentials fixture, then discards its producer
balance/count facts and applies both new helper consumers to the same result.
It proves the ledger transfer and the physical count transition **3 → 4**.
The first test draft mistakenly expected initial count0; kernel evaluation
refuted that expectation. The accepted test uses the unchanged physical
fixture's actual initial count3. Other kernel examples check the upper amount
edge, empty-key/no-allocation-credit distinction, key check before zero skip,
length mismatch and an empty loop with an above-capacity initial slot.

`validation.log` is the final successful 1274-job target build. Dependencies
and the unchanged new source were replayed; only the corrected test module
was freshly built in that command. `source-build-with-failed-fixture.log`
retains the earlier successful source build and failed draft test, explicitly
not a passing whole-target result. Warnings and failed-fixture `sorryAx`
diagnostics there are not the accepted theorem axiom report. The final log
and input hashes identify the accepted files without rerunning unchanged
sources.

No new Solidity execution was run for these proofs. The unchanged accepted
solc0.6.11 beacon validation in `audit/topup-beacon-effects/` covers four tests,
one 1024-run fuzz test, all32 carry heights, final capacity, ordered rejects
and late rollback. Its source/test/log hashes are rechecked and linked as
inherited evidence, not a new integration test or a proof of this Lean-to-EVM
correspondence. The receipt also checks the actual import source closure,
package pins and selected Lean toolchain sources; it does not certify the
compiler binaries or the complete Lean kernel source.

## Necessary internal work still open

- Compose the gateway/module/withdrawal/history prefix through this actual
  helper and derive all initial state, length and registry invariants from
  initialization and the actual transitions. The current result does not
  establish the pre-module ledger or inter-call/nested funding cap.
- Derive the complete per-deposit event/branch chain and full pre-entry
  rollback/compiled-memory/gas/ABI correspondence for the promised domain.
  This increment adds ledger and physical count results; it reuses rather
  than strengthens existing forward event/branch and root rollback results.
- Actual compiled error data, LOG encoding, runtime dispatch and surrounding
  effects remain separate required links. The accepted source model's names
  and word-per-octet logs are not their EVM encodings.

## External boundaries

The opaque SHA implementation's correctness/cryptographic security and the
runtime identity/provenance of the deployed beacon/caller configuration are
not established here. Pin and finite source tests identify the source being
modeled, not the deployed instance or an authenticated consensus history.

Independent exact-commit review is required before integrating this increment.
