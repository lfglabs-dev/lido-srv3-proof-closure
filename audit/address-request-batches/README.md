# ADDRESS typed request batches with physical pause admission

Source base: `ae30a086154dc78196034657953b9a09cc75b48b` (merged #331).
Pinned core: `17005714f151e5502c559932319a3f2f74ac2436`.

This increment composes the actual stETH request and actual WSTETH
transferFrom→unwrap→request public effects across an ordered typed batch. It
executes the physical `_checkResumed` once, including for an empty batch, resolves
the owner at entry, then consumes each existing public runner on the previous
item's returned World. A later failure restores the complete batch-entry World,
including earlier successful items and callbacks; attempted-call journals remain.

**Scope is the physical pause admission plus typed-array iteration.** The model
uses `List Word` for decoded calldata and `List Nat` for typed request IDs. It does
not execute the compiled result-array allocation, calldata dispatcher, memory or
gas. It is not a full compiled implementation of requestWithdrawals or
requestWithdrawalsWstETH. The compiler allocation checks described below are not
silently assumed successful and are not supplied as public theorem hypotheses.
All previous one-item claims and their domains remain unchanged.

## Consumed public effects

`stETHStep` calls the accepted public stETH runner (amount guard before CALL).
`wrappedStep` calls #331's actual WSTETH transferFrom/unwrap runner (stETH amount
guard after unwrap). `stETH_batch_success` and `wrapped_batch_success` discharge
the generic loop implication with the **existing public theorems**, not supplied
successful stages. The new public theorems return entry `Resumed`, an inductive
`Transcript` and equal output/input lengths. Each transcript constructor binds
one original amount, result ID, complete old effect, actual pre/post World and
journal to the next constructor's entry World, preserving ordering. The wrapped
effect retains the **entire** previous JoinedEffect, including actual first
transferFrom, actual unwrap conversion/burn/transfer, same received Word, quote,
physical enqueue, events and attempts. No effect is replaced by an ID counter.

Both public rollback theorems apply to the entire batch runner. The underlying
item runners already roll back a failed item; the outer runner additionally
restores all earlier successful items. No initial allowance, balance/amount fit,
nonempty, nonalias, frame, successful-stage or per-item-success premise appears
in either public success theorem. The generic internal induction uses an item
implication that is discharged by old public proofs; it is not a residual public
assumption. IDs are returned in item order; no universal strict monotonicity is
claimed across arbitrary callback worlds that could change queue storage.

Owner selection occurs at batch entry. The old item helpers still contain their
pure owner resolver, whose idempotence is proved; passing the already-resolved
owner cannot change it. Context is fixed across the loop. Old item effects retain
their per-item entry timestamp. External World implementations may change even
model environment fields: no block.timestamp frame or full EVM environment
continuity has been added to make the theorem stronger than the underlying model.

## Physical and compiler correspondence

Read complete pinned WithdrawalQueue requestWithdrawals (129–140),
requestWithdrawalsWstETH (149–160), their internal requests and amount guards,
PausableUntil and UnstructuredStorage. The exact resume slot is
`keccak256("lido.PausableUntil.resumeSinceTimestamp")` =
`0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02`.
The model consumes that physical full-word slot via the accepted designated
queue storage lens. Pause means `blockTimestamp < storedResume`; equality resumes.
The fault retains the existing semantic custom-error category convention
`ResumedExpected`, not a new model raw-error-byte equivalence theorem.

The full **legacy** solc0.8.9 optimizer200 London assembly is archived. Both batch
bodies call `_checkResumed` before owner resolution and allocation; neither loop
rechecks pause. The isPaused body loads the exact data-pool slot, then compares
TIMESTAMP; `_checkResumed` emits the ResumedExpected selector. WSTETH batch body is
around assembly1379–1544; stETH around4086–4268; pause check5828ff; isPaused3353ff.
The stETH loop checks its amount before entering the internal request. Both load
typed uint256 items and store the returned ID in the corresponding result index.

The **omitted allocator boundary is concrete**: `new uint256[](length)` rejects
length >2^64−1 with Panic(0x41) (tag287); then uses free-memory pointer, writes the
length, advances by32+32*length and zero-fills with CALLDATACOPY. Both source loop
indices are uint256, initialized to0, compared to length, checked for input and
result bounds and incremented with overflow checking (tag300). For successful
compiled allocations their length bound makes counter overflow unreachable by
ordinary iteration. The Lean typed loop does not model these memory/ABI bounds,
allocation exhaustion, output encoding or gas. No inference from its arbitrary
finite List domain to compiled acceptance at impossible allocation sizes is made.

The fixture extends the unchanged one-item harness only with an explicit physical
pause setter, used by a STETH callback. It executes the **inherited actual public
batch functions**, not a separately rewritten Solidity loop. It deploys exact
archived unmodified WstETH0.6.12 creation bytecode through its constructor. The
STETH double and storage seeding are explicit; no role or deployment-provenance
proof is claimed. STETH and token callbacks, queue's designated storage lens,
initial configured-address/layout/allowance provenance, permit entrypoints,
general compiler/EVM/LOG/cryptographic correspondence remain outside the proof.
No final token balance or conservation claim is added across callbacks.

## Validation and reproducibility

- Normal targeted Lean4.31.0 build passes1,272 jobs. Source/public were actively
  compiled in1.5s each; corrected kernel tests1.8s and final native-definition
  update1.6s. Warm unchanged dependencies are reused; no global All/Trust build.
  Seven source theorems, four public theorems,14 kernel examples and two public
  boundary instances (empty stETH success; paused wrapped rollback).
- Nine freshly evaluated ordinary axiom closures; public proofs use only
  propext, Classical.choice, Quot.sound. The generic loop/admission proofs need
  only propext.1,255 actual imported/new source identities,11 package pins,
  selected local olean identity and native runtime inputs are checked. Final
  source/artifact hashes are measured after successful checks, not backdated.
- Five native actual-batch diagnostic groups pass: stETH transcript, actual
  wrapped transcript, pause-callback worlds, late stETH rollback/journal and late
  wrapped rollback/journal. They use official existing Keccak FFI compiled to a
  temporary dylib. Positive physical executions are diagnostics, not kernel
  success instances or native_decide theorem claims. Generic-loop kernel examples
  are separately labelled and do not replace these actual consumer executions.
- Eleven fresh real Solidity tests pass, including one fuzz×1,024(seed0x20260911).
  They cover empty/paused/equality, owner/IDs/order, stETH guard-before-call, actual
  wrapped two-item execution, second-item allowance/amount failures and whole
  rollback, and callbacks pausing the queue after item1 for **both** batch paths.
- Correspondence checks35 reused inputs,27 Git/npm source bodies, compiler
  metadata11token/18queue/19test sources, exact token artifact, resume slot and
  selectors. Token0.6.12/200/Istanbul is reused; queue/tests0.8.9/200/London compile
  fresh. These fixture profiles are not deployed-bytecode identity.

```sh
lake build LidoSRv3.Tests.AddressRequestBatches
python3 audit/address-request-batches/validate.py
python3 audit/address-request-batches/run-diagnostics.py
python3 audit/address-request-batches/check-correspondence.py
(cd audit/address-request-batches/solidity && forge test --match-contract BatchTest --fuzz-seed 0x20260911)
forge inspect --root audit/address-request-batches/solidity BatchHarness assembly
```

Validators write manifests only in this new dossier; read before running in a
read-only review. Pinned source checks read the core checkout at
`/tmp/lido-ssz-proof-committed/lido-core`.

Development errors remain archived: Lean escaped error constructor, simplifier
normalization and pure owner idempotence; a test record newline syntax error;
Solidity fixture parameter named timestamp conflicting with Yul builtin; and a
correspondence check initially expecting a 0x prefix in raw assembly data. One
public/test build was launched before noticing the still-failing source owner
proof and repeated that failure; it is retained explicitly and not credited as
new evidence. Corrected final source/tests pass. Public/source active compile
success within a later failing test build is distinguished from final test success.

The optional experimental IR inspection **failed** with compiler ICE
`Invalid stack item name: slot`; stderr and empty stdout are retained. It is not
the chosen legacy profile, no IR evidence is credited, and no source/profile was
changed to hide the failure. The complete successful legacy assembly is used.
Raw BatchHarness.asm ends with the compiler's blank EOF, deliberately preserved;
that exact raw-output exception is not an unconditional diff-check PASS. Earlier
inherited raw token assembly remains unchanged as well.

No global wiring, roadmap, site update, merge, publication or deployment is part
of this candidate. Author freezes and stops for a different independent reviewer.
