# ADDRESS: one admitted stETH request and physical enqueue

Base proof tree: `eee5d6700e5d99cc35eab7bf3e1e2b51a2465857`.
Solidity pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
All prior proof files, claim/unwrap paths, registries and Lake configuration remain unchanged.

`PAddress1.actual_request_withdrawal_enqueue` consumes success of the new complete
one-item `runRequest`. It derives the two amount guards, owner fallback, a real
stETH `transferFrom` call (payload, canonical bool return, returned world, nested
attempts), the actual read-only shares quote on that returned world, truncating
uint128 conversion, checked cumulative additions and request ID, ordered physical
queue writes and owner-set insertion, then WithdrawalRequested and Transfer.
There are no supplied successful-stage, share-fit, quote, owner-set, frame or
non-alias premises. `actual_request_withdrawal_failure_restores` restores the whole
modeled entry world on failure, including successful transfer effects; attempts
remain a separate observation journal.

The request ID is one greater than the last ID **after transferFrom**, not the
transaction-entry ID. The getter has the accepted `StaticExternal` interface and
cannot return a changed world. The block timestamp is captured from entry and
transported independently of arbitrary returned metadata; only that immutable
value is captured, without erasing any other callee effect. Report timestamp is
read from real storage after the last-ID write. The constructor preserves the
unused high byte of its metadata word, clears claimed and writes owner and the
two uint40 timestamps. Cumulative amounts occupy the full other word.

## Fidelity differences that matter

The historical bridge is retained for compatibility and not promoted: it required
`transferFrom` to return true, used a mutable shares getter, captured report time
early and used a different owner insertion order. This new path is separately
implemented and consumed by the new public theorem.

The real pinned Solidity ignores the bool value but its legacy compiler decodes a
canonical 32-byte bool: false succeeds, 2 and a short reply revert. Shares use an
explicit truncating uint128 cast; a value of 2^128+7 contributes 7. The admitted
amount is separately proved below 2^128.

`insertOwnerChecked` checks the absent member/assert condition. The **legacy
solc 0.8.9 optimizer-200** code writes array length first (wrapping uint256), then
the array cell, re-reads length, and writes the member index. It has no length
panic at uint256 max. The fixture confirms that pathological maximum length
wraps to zero and the add succeeds. This is not a claim that this state is
reachable from normal deployed operation. The experimental IR probe emits a
2^64/Panic(0x41) guard and is therefore not substituted for the real legacy code.
`solidity/RequestHarness.asm` establishes the actual operation sequence.

The source relation records intermediate writes and the final checked insertion
transition, rather than asserting all final slot re-reads under arbitrary aliases.
It preserves the inherited physical-slot/Word abstraction and adds no keccak
injectivity assumption. Kernel dependency queries contain only propext,
Classical.choice and Quot.sound (subsets depending on the theorem).

## Validation and reproduction

- `lake build LidoSRv3.Audit.Source.AddressRequestCalls LidoSRv3.Audit.Guarantees.PAddress1RequestCalls LidoSRv3.Tests.AddressRequestCalls`:
  1262 jobs; new source/public were built in `source-build.log`, final tests built
  in `target-build.log`. Existing dependency warnings are retained; no warnings
  in the three new modules. The final test file contains 13 kernel examples and
  one concrete public rollback instance, plus seven active axiom queries.
- `python3 audit/address-request-call/validate.py`: reads the actual final test
  setup import closure, checks exact package pins and unchanged consumed local
  source bodies, and independently queries the compiled theorem environment.
- `python3 audit/address-request-call/run-diagnostics.py`: eight complete success
  diagnostics, including owner fallback, post-transfer ID, truncated shares,
  immutable entry timestamp and maximum owner-set length. These are **executable
  diagnostics, not kernel theorems**. The script builds the official evmyul FFI
  wrappers and recorded C implementations as a temporary dylib, then loads it for
  `#eval`; it introduces no Lean declarations or axioms. Native C objects use the platform C compiler; Lean wrappers are linked with leanc. Runtime C hashes and repository
  revisions are recorded separately from formal package pins.
- `forge test --root audit/address-request-call/solidity --fuzz-seed 0x20260911 -vv`:
  12 real Solidity tests, one fuzz test with 1024 runs. This compiles the complete,
  unchanged WithdrawalQueue and its 16 source dependencies. The subclass exposes
  one admitted request and setup access; the stETH/wstETH doubles are explicit.
  Pause, array allocation and the batch loop are intentionally outside the tested
  `one` boundary. No test overrides `_requestWithdrawal` or `_enqueue`.
- `forge inspect --root audit/address-request-call/solidity RequestHarness assembly`
  and `forge inspect --root audit/address-request-call/solidity CompilerProbe ir`
  reproduce the separate legacy and fragment compiler evidence.

The concrete success kernel-reduction attempt did not complete: reduction of
nested physical keccak slots hit maxRecDepth even at 1,000,000. The retained
`kernel-reduction-failure.log` is a diagnostic of the bounded probe, not validation
of the final file. No native_decide, claimed kernel success or non-alias hypothesis
was substituted. Initial interpreted execution also needed the native evmyul
wrappers; the explicit loader script resolves that runtime linkage requirement.

Full-harness `forge inspect RequestHarness ir` produced the solc 0.8.9 internal
error `IRVariable.cpp:52 Invalid stack item name: slot` for the unstructured
storage pointers. This observation is recorded here rather than invented as a raw
log. Legacy compilation and actual tests succeed. The restricted CompilerProbe
uses the same compiler/options and original OZ add to inspect fragments, not to
claim full IR/runtime equivalence.

## Remaining boundaries

This is a necessary-success source-shaped theorem using the accepted typed live
interpreter, not an EVM execution theorem. It excludes the full public pause/batch
prefix, raw ABI dispatcher and encoded errors/LOG topics, deployment/authenticity
of configured token addresses, actual Lido allowance/balance/share arithmetic,
CALL gas/reentrancy scheduling and full caller-renaming equivariance. The stETH
callee can return arbitrary modeled world effects; its net token transfer and
unrelated final state invariants are not asserted. Physical queue storage uses the
accepted unqualified contract view. The environment timestamp consumed by the
program is fixed, while other unrelated returned model fields are not normalized.
Source/state slot-address conventions are inherited; no new no-wrap/keccak
collision-resistance fact is borrowed. The old four-entry model and supplementary
request-ID/packed-owner helpers remain distinct. P-ADDRESS-1 stays open.

The two compiler text artifacts are retained byte-for-byte, including their final
blank line; these are the only `git diff --check` whitespace exceptions.
