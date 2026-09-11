# ADDRESS permit transport composed with complete typed batch effects

Source base: `274d8cc9aa543aa4aafda84937689676e0839cfe`, independently reviewed batch
source. Core pin: `17005714f151e5502c559932319a3f2f74ac2436`.
Only three new Lean files and this dossier are added; old sources, public domains,
package pins, wiring and site remain unchanged.

The new runner executes the actual permit CALL **before** the accepted batch's
physical pause check. Its returned World becomes the batch's entry World. The
public successful result preserves the **entire** previous batch conclusion:
Resumed at that returned world, the ordered per-item Transcript of complete old
effects, final World/journal and result/input length equality. Wrapped items still
execute actual #331 transferFrom and unwrap, with all their physical effects.
The outer failure theorem restores the entry World from before permit, including
permit writes/events and any earlier successful batch items.

## Actual request and proof consumption

`PermitInput` contains Word value/deadline/r/s and UInt8 v. The generated payload
is selector `0xd505accf` followed by exactly seven 32-byte ABI words:
`ctx.sender`, `ctx.self`, value, deadline, v.toNat, r, s. `calldata_length` proves
228 bytes; kernel examples check every field's actual position. Owner is the
requesting sender, not the optional withdrawal recipient. UInt8 provides the
canonical v domain without a fit hypothesis; r/s are full-width words.

`permitCall` directly passes these bytes to `callWithCalldata`, with caller queue
self, target STETH or WSTETH selected by the public wrapper, and zero value. The
real transport checks target code, invokes the explicit external implementation,
bubbles rejected bytes/nested trace and retains its success World. The program
ignores all successful returndata, including empty/short/noncanonical bytes.
No bool or minimum-length decoder is inserted for a void call.

`PermitEffect` identifies that exact request and actual external reply on the
value-transferred World, its full returned World and its actual journal. The
joined proof derives this relation from execution and obtains the complete batch
effect on the very same returned World. The two public success proofs explicitly
apply the two accepted batch public theorems. The generic internal batch-success
implication is discharged there; no permit-success, batch-success-stage, allowance,
fit, nonalias, frame or signature premise remains in the public statements. This
is not an unused payload adapter or an isolated permit fact.

The two public failure theorems run rollback around both permit and batch. Batch
rollback alone would restore only the post-permit World; this new outer boundary
restores before permit. Attempts remain diagnostic observations rather than
committed logs. No final token conservation through arbitrary callbacks is added.
The permit external may even change pause storage: the downstream check reads its
actual returned World. Kernel cases cover a permit resuming a paused input and a
permit pausing a resumed input. No pre-permit Resumed hypothesis is supplied.

## Pinned source/compiler evidence

Read complete pinned WithdrawalQueue permit wrappers (lines170–176 and186–194),
PermitInput, both public batch bodies and the consumed IERC20Permit interface.
STETH.permit and WSTETH.permit are void external methods called before the
corresponding batch function. Configuration/deployment of these token addresses
remains an explicit context boundary, as in the preceding sources.

The complete legacy0.8.9 optimizer200 London assembly is archived and inspected.
WSTETH wrapper body is around2185–2315; STETH around3234–3351. Both build the same
seven fields, use zero value, EXTCODESIZE before CALL, and bubble returndata on
failure. Success pops the call result and enters the batch; there is no success
returndata copy or decoder. Recording success bytes in the model journal is an
observational interface, not a claim that Solidity copied them into memory.
The v decoder (tag372) requires a full calldata word equal to its low8 bits;
encoder tag374 uses seven words, address cleanup and v mask, ending at224 bytes
after the selector. Outer malformed ABI/struct/calldata decoding is not modeled.

The fresh BatchHarness creation/runtime bytecode **objects**, compiler metadata
and full assembly match the previous batch artifact. Whole artifact bytes do not:
the old JSON also contains the optional assembly field and sourceMap differs in
the fresh fixture build. The checker explicitly compares the actual objects and
metadata and records each artifact's own hash; no guessed whole-artifact identity
is claimed. The full assembly is byte-identical to the previous reviewed assembly.
No optional experimental IR run is performed or credited in this increment.

The existing typed batch boundary is retained: actual result-array allocation,
length/memory checks, array ABI/output encoding and gas are not executed by the
List-based model. The source/compiler allocator limits remain those documented
in274d, not hidden successful-allocation assumptions. The queue keeps its existing
designated storage lens and each old item its entry-world timestamp; no new EVM
environment frame or deployment/storage provenance theorem is added.

## Permit body and fixture distinctions

**The formal permit body, EIP2612 signature validity, domain separation, nonce
updates and authentication remain explicit external behavior.** No theorem here
proves those implementations. The proof is additive transport/call composition.

The Solidity fixture executes actual inherited public WithPermit wrappers and
batch methods. Direct STETH tests use a clearly named PermitSt double: it verifies
caller/spender/calldata size, records all seven arguments, may reject chosen bytes
and returns arbitrary bytes from a void function. It does not authenticate a
signature. Its returned state/logs are checked through success or rollback.

Three wrapped Solidity tests additionally execute the **actual unmodified**
WstETH0.6.12 permit implementation, using a reproducible fixture-only private key1
and Foundry signing. They use the actual token DOMAIN_SEPARATOR/current nonce,
then verify allowance is consumed by actual transferFrom/unwrap for two items,
or that nonce/allowance/balances revert on a later failure or paused empty batch.
This is finite real-signature execution evidence, not a formal authentication
claim or proof that the mocked direct STETH permit implements EIP2612. Token
balances are explicitly seeded and STETH conversion/transfer remain doubles.

Native model diagnostics start with zero qualified WSTETH allowance. An external
permit implementation accepts only the exact generated request and writes15 to
the actual owner1/spender99 nested allowance slot. Without it, transferFrom fails.
With it, both7/8 wrapped items execute and consume the allowance to0; later item
failure restores pre-permit allowance0, supply/balances and logs. Thus permit's
returned storage is consumed by the actual wrapped implementation, not merely
included in a result record. The four native groups are executable diagnostics,
not positive kernel theorem instances.

## Validation

- Normal Lean4.31.0 targeted build:1,274 jobs PASS; source1.5s/public1.4s actively
  compile in the build that later exposes a test syntax error; corrected tests
  pass1.7s, and the final two pause-world kernel examples pass1.8s. Warm unchanged
  dependencies reused. Four source theorems, four public theorems,19 kernel
  examples and two public boundary instances. No global All/Trust build.
- Nine fresh ordinary scoped axiom queries. Source transport/compose/length
  scopes use propext; public closures use only propext/Classical.choice/Quot.sound.
  1,257 imported/new source identities and11 package pins checked, with selected
  imported olean byte identity and exact old local sources. Runtime/FFI inputs
  recorded separately from kernel proof evidence. Final source/object hashes are
  captured from the successful final environment, never assigned retrospectively
  to failed attempts.
- Four native actual-permit/batch diagnostic groups PASS. After adding two
  kernel-only pause-world examples, final native execution is repeated to bind
  the diagnostic receipt to the final compiled test source; the earlier log is
  retained separately. No historical source hashes were guessed.
- Nine fresh Solidity tests PASS; one fuzz test×1,024 varies value/deadline/v/r/s
  and ignored void return lengths0–64 while checking the actual caller/spender.
  Other tests cover no-code/rejection before pause, paused empty and late-item
  rollback of permit writes, actual stETH batch success and the three real-token
  signed permit cases above. Only PermitTest is selected; copied BatchTest tests
  are compiled as dependencies, not counted as newly executed.
- Correspondence:39 reused inputs,27 exact pinned Git/npm source bodies,
  metadata11token/18queue/20test inputs, exact old token artifact and full assembly,
  selectors and actual compiler-object identities. Token0.6.12/200/Istanbul is
  reused; queue/tests0.8.9/200/London compile fresh. Not deployed-bytecode identity.

```sh
lake build LidoSRv3.Tests.AddressPermitRequestCalls
python3 audit/address-permit-request-calls/validate.py
python3 audit/address-permit-request-calls/run-diagnostics.py
python3 audit/address-permit-request-calls/check-correspondence.py
(cd audit/address-permit-request-calls/solidity && forge test --match-contract PermitTest --fuzz-seed 0x20260911)
forge inspect --root audit/address-permit-request-calls/solidity BatchHarness assembly
```

Validators write this dossier's manifests; read before using in a read-only
review. Core checks use `/tmp/lido-ssz-proof-committed/lido-core`.

Retained development failures are the missing fully-qualified ABI lemma, an
unresolved existential attempt witness, and a test record-layout newline. One
public/test build started before the failed source result was noticed and repeated
that source error; the repeated failure remains explicit and is not credited as
new evidence. An initial fixture-command tool invocation also failed because its
working directory had not yet been created; no shell command ran in that attempt.
An artifact comparison initially assumed all JSON keys shared the optional
assembly field; corrected inspection established the precise object/metadata
identity and sourceMap difference described above. No fixture/compiler semantics
were changed to hide a failed assertion.

Raw BatchHarness.asm's terminal blank line is preserved as the sole new
whitespace exception. Filtered source diff-check excludes exactly that compiler
output; it is not an unconditional whole-history PASS. Previous raw-output
exceptions and experimental IR failure evidence remain in the unchanged base.
No old source, wiring, roadmap, site, merge, publication or deployment belongs to
this candidate. Author freezes and stops for a different independent reviewer.
