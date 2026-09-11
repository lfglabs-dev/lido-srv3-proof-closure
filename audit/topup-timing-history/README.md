# TOPUP temporal admission and final physical history

Base: `367412569a2dd85972ab8bdab8304d261fa7b4ec`.
Core: `17005714f151e5502c559932319a3f2f74ac2436`.

`PTopupTimingHistory.actual_timing_credential_root_module_memory_history`
adds physical block-distance/root-age guards and the final gateway history
write to the executed physical credentials getter, actual root/witness loop,
module CALL, scalar return decoder and physical continuation. Its sole execution
premise is success of the new runner. `IntermediateEffects` contains the
**verbatim entire** 3674 public conjunction: the validation script compares
that text exactly. The public result identifies the intermediate World and all
three attempt journals with the old actual run, then relates the final World
and journals to the same executed stage. The old physical effects apply to
that intermediate World, before the new gateway history write.

The executable `execute` performs the real root loop once and passes its
retained `checked` result directly to `TopupBatchMemory.finish`, which runs
the actual module and continuation. `Stage.produced` retains that very output.
`execute_projection` proves equality to the old physical-getter runner for
all inputs, including errors. `execute_produced` derives an actual successful
loop output from whole-stage success. The final decision consumes its `total`;
it never reruns roots or reconstructs total from an allocation list. The zero
fallback for an absent retained output is unreachable under actual success,
as derived by `execute_produced`. There is no output/stage success premise.

`run` first checks the actual packed length/count configuration, then temporal
admission, then this stage. The repeated length check within `execute` is pure
on identical inputs and the initial World. Timing failures perform no lookup,
root or module attempts. Later failures retain the executed attempts and restore
the complete initial World. `actual_timing_credential_root_module_failure_restores`
is universal over all new error constructors, with no successful-prefix premise.

## Exact source and full compiler mapping

All references are to pinned `contracts/0.8.25/TopUpGateway.sol` and the complete
2519-line `audit/topup-credential-call/solidity/GatewayWitnessHarness.ir`.
The exact retained input/output, metadata and IR are reused without recompiling.
All 22 inputs (17 core, four OpenZeppelin 5.2, one unchanged inherited harness)
are checked against pinned Git or accepted vendored bytes, original fixture
SHA256 and compiler metadata Keccak. The retained profile is solc 0.8.25
`b61c2a91`, viaIR, optimizer 200, Cancun; this is not a production bytecode
identity assertion. The independent namespace hash is
`keccak256(abi.encode(uint256(keccak256("lido.TopUpGateway.storage"))-1)) & ~255`.

| Pinned source / complete IR | Executed model |
| --- | --- |
| Storage42–48; topUp163–175; IR372–438 | Nonempty/matching typed lengths and physical maxValidators first. Timestamp is uint32 at bit64, block uint32 at bit96, distance uint16 at bit128, age uint16 at bit144. |
| _isBlockDistancePassed323–326, _require328–332; IR2152–2170 and440–448 | Zero lastBlock short-circuits subtraction. Otherwise checked uint256 `number-lastBlock` precedes distance comparison and `MinBlockDistanceNotMet`. A zero stored distance is permitted. |
| _verifyRootAge380–388; IR450–479 | Child timestamp plus uint16 age is a **checked uint64 ADD**, before `RootIsTooOld`, then `child <= lastTimestamp` rejects. No future-timestamp restriction. |
| topUp189–228; IR512–995 | Existing canonical physical getter dispatcher, prefix02, same actual root replies/trees/limits; produced Output retained across module execution. Existing width/order/cursor conditions remain in full IntermediateEffects. |
| topUp233–235, _setLastTopUpData340–345; IR1113–1130 | Executed totalLimits nonzero selects a fresh SLOAD of the post-module gateway word. Optimizer coalesces the two uint32 assignments into one SSTORE, preserving bits0–63 and128–255. Semantic LastTopUpChanged carries full post-world TIMESTAMP. |

The source addition width is not inferred from the uint256 timestamp comparison:
IR explicitly masks the child to64, age to16 and panics if their sum exceeds
`0xffffffffffffffff`. The compiler's history mask clears exactly bits64–127.
`packed_fields` proves both uint32 truncations and preservation without a
storage fit premise, using only the inherent Word width. `HistoryEffects`
includes the full resulting World equation, log append, and physical fields.
The event signature Keccak and inherited gateway root are checked independently.

Both TIMESTAMP and NUMBER for final history come from the **actual returned
intermediate World**, as does the preserved part of the packed slot. Arbitrary
module/callback Worlds remain allowed. No invariant ties their timestamp,
block number or gateway storage to the admission World. A concrete regression
changes all these values, includes high bit255 and preserves changed low/high
fields. Event timestamp remains full width while physical fields truncate.

## Boundaries

- This remains a typed covered phase. Role/pause, LOCATOR.stakingRouter,
  initial deployment/setters, outer ABI admission and actual gateway-to-router
  topUp CALL/caller composition retain their existing scope. Supplied gateway
  and router roles are not justified by a new equality premise.
- The omitted outer router CALL at IR1002–1100 and its returned-buffer allocator
  IR1102–1110 are not executed by this model. History is joined after the actual
  already-covered module/physical continuation. No allocator success or bound
  is invented for the omitted entry phase.
- History's event uses the existing semantic Log representation. Its compiled
  memory load/store, allocation/aliasing, LOG bytes and gas are not newly
  modeled. Existing separate scalar getter/module cursor results remain fully
  preserved, without claiming complete memory provenance.
- Existing selected getter dispatch/storage/hash, actual roots/typed proof,
  cryptographic SHA, module callbacks, withdrawal and beacon boundaries remain.
  There is no new SHA-totality, membership/type, frame, future-time,
  monotonicity, byte-width, fit, funding, alignment or stage-success premise.
  pendingBalanceGwei remains the legitimate paired source argument.
- Timing errors retain semantic classes (including arithmetic panic), not a
  new byte-for-byte complete revert ABI theorem. Canonical getter return/error
  bytes retain the earlier consumer's exact scope.

## Validation

Normal `lake build LidoSRv3.Tests.TopupTimingHistory` passes 1369 jobs, with
three new modules. Sixteen kernel regressions cover temporal width/priority,
zero-block short-circuit, exact distance and age boundaries, prior timestamp,
future child acceptance, length/config priority, no early attempts, whole
success, positive limits with all-zero allocations, nonempty zero limits,
and late failure rollback. The complete public theorem has a concrete success
instance, and its universal rollback theorem has a concrete late-failure
instance. Structural constant-SHA kernel fixtures are not cryptographic tests.

Seven fresh native FFI IO diagnostics consume the unchanged independent
three-row SHA tree/proofs from f008: positive physical [1 ETH,0,2 ETH] plus
history; all-zero allocations with real positive witness limits plus history;
altered stored credentials; altered actual root reply; temporal failure before
missing registry entry; aggregate-cap failure and rollback; uint64 age overflow.
Native C/library commands, six runtime source identities and subrepository
pins are recorded. These are executable diagnostics, not kernel proof credit
or new native axioms. Development diagnostics first hit an earlier per-row
allocation guard; the final aggregate-cap case uses [2 ETH,2 ETH,0], each within
its produced 2 ETH limit. Earlier parser/instance/proof development failures
provide no proof credit; retained final logs contain successful checks.

The actual normal registered regression closure has 1352 source identities and
11 package pins. All 28 fresh ordinary scoped axiom sets contain only
`propext`, `Classical.choice`, `Quot.sound`; three normal artifacts/options are
recorded. `validation/validate.py --write` records outputs; default mode compares
without changing them. Complete combined All/Trust and independent exact review
belong to root integration, and are not claimed by these scoped results.

No solc or Forge execution was repeated. The old gateway fixture's seven tests
(including three 1024-run fuzz properties) are reused only for their original
scope and exact input identities; they do not constitute new runtime timing
or history test executions. Complete compiler artifacts and original receipt
remain at their inherited immutable paths. No raw IR copy is added, so this
candidate introduces no new raw whitespace exception. Only three new Lean
files and this dossier are added; older sources, wiring, dependencies and site
are unchanged.
