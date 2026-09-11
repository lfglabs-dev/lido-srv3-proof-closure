# TOPUP actual module-return scalar memory guards

Base: `2c2c72a91cd68a43de0777912772d12cc48a285d` (integrated DEPOSIT321).
Core pin: `17005714f151e5502c559932319a3f2f74ac2436`.

## Useful public increment

`PTopupMemoryCalls.actual_root_module_memory_effects` consumes successful
`TopupBatchMemory.run returnBuffer ...`, which runs the actual root/witness
phase, then calls the same physical module with the same produced arrays,
executes the new scalar memory decoder on its actual returned bytes, and runs
the existing continuation on the module's actual returned World. This entry
executes each external phase once. Its proved equality with the retained batch
is a mathematical projection, not a second interpreter execution in the code.

The conclusion retains both existing TOPUP root/module cap and physical-effects
propositions on exactly this result (ordered witness/limit correspondence,
mathematical sum, zero branch or physical positive helpers/events/attempts).
It additionally exposes the actual raw reply and guarded decoded allocations,
post-return and post-array pointers, both allocator success equations, bounded
copied range, monotone cursor and uint64 ceilings. Failure restores the root
World, including effects of a previously successful module CALL, while keeping
both diagnostic attempt phases.

No existing source, executor, theorem or claim is changed. The new entry is an
additive scalar-memory refinement. Old memory-abstract success does not imply
new success, and the old unconditional canonical serialization lemma is not
misrepresented as proving cursor-dependent allocation success.

## Complete changed-source correspondence

- `contracts/0.8.25/sr/StakingRouter.sol:717–758`: same actual allocateDeposits
  arguments and returned allocations feed the amount loop and physical
  continuation. Preceding role/locator/config/paused checks remain outside the
  already declared covered suffix; this change does not assert they execute.
- Retained complete `audit/topup-module-nocode/router-ir.txt`, compiled from the
  pinned source in BatchRouter fixture, **solc0.8.25 optimizer200 viaIR Cancun**:
  lines1082–1086 copy successful actual returndatasize to the captured buffer,
  finalize raw allocation, and invoke uint256[] decoder. This is after the real
  zero-value CALL and its failure handling at1070–1078.
- IR3149–3159 finalize allocation: wrapped ADD(size,31), mask low five bits,
  wrapped pointer addition, reject pointer above 2^64-1 or below old pointer
  with Panic(0x41). The accepted DEPOSIT321 `round32/finalizeAllocation` bodies
  are imported unchanged rather than reimplemented.
- IR3348–3353: signed head SUB <32, head offset uint64 ceiling. The new decoder
  applies actual Word returndatasize and Word ADD/SUB, not an invented natural
  length bound. `end_sub_base` is reused; `raw_bounds` derives >=32, a small
  nonwrapping copied extent and pointer bound jointly from allocation and
  signed guard. No length/cursor admission premise is supplied.
- IR3323–3347: signed length-word address+31 bound, decoded count uint64 ceiling
  via IR3161–3170, then allocation of **32*count+32** at the **post-return**
  free pointer, then unsigned source-end bound and the array word-copy loop.
  `decode_success` derives safe nonwrapping pointer arithmetic from executed
  guards and identifies the identical retained `readWords` output. In particular
  the array allocation precedes extent rejection; the scalar error priority is
  preserved. No bytes-array allocation formula is substituted.
- `program/execute_success` consumes the actual raw result and projects the
  guarded continuation to the earlier same-call execution. `TopupBatchMemory`
  preserves the root input-length checks, same packed configuration, ordered
  root loop, immutable initial World for roots, and module/root trace split.
  Its universal rollback theorem handles both root failure and Live.run's
  restoration after module/memory/continuation failure.
- The public theorem obtains the original bounds and physical effects using
  this successful execution equality. No RootOracle, hdecode, stage-success,
  size, sum, alignment, canonical-offset or no-wrap premise is added.

## Exact degree and remaining boundary

This is a **typed covered-phase scalar-memory result**, not an unconditional
Solidity entrypoint or compiled memory simulation. `returnBuffer : Word` is the
explicit phase input; its origin and alignment are not derived. `raw` is the
immutable copied-return view; actual EVM memory-copy and overlapping writes/
reads (including potential aliasing with mstore(64) for arbitrary supplied
cursors), memory provenance and opcode gas are not established. The scalar
IR guards are faithfully checked on that view; the proof must not be cited as
establishing the omitted alias/copy relation. Host byte-list length is projected
to the EVM word; no artificial host-size rejection is introduced.

Existing ordinary-no-code/precompile, arbitrary external callee, typed root/
cryptographic reply, physical hash layout and declared Verity boundaries retain
their scope. Old accepted ALLOC/RESERVE claims are untouched. Successful old
canonical-return proofs remain historical memory-abstract evidence, not proof
of the new cursor origin. No full compiled CL linkage or gas theorem is claimed.

## Checks and reuse

`lake build LidoSRv3.Tests.TopupModuleMemoryRegression` checks all four new
modules plus their actual import closure. Regressions use ordinary kernel
proofs: canonical two-word return, raw allocation before empty-head rejection,
empty head, array allocation before payload extent, short payload, count
panic, unaligned unpadded empty tail, actual two-root batch success and exact
old-world/trace identity, whole-batch post-module memory failure/rollback,
public full consumer instantiation, positive physical execution identity and
its retained successful execution. The last transport reuses unchanged full
physical fixture proofs, avoiding opaque hash evaluation or invented helpers.

`validate.py` independently recomputes each selected theorem's axiom closure
from the environment and compares every imported local/package source to base
or pinned Git bodies. `source-ir-check.py` rechecks the retained IR/settings/
metadata/test receipt identities, all 28 actual compiler input bodies and
pinned core source bodies. There is **no new Solidity runtime test** in this
lot. The retained no-code call-site test is reused only for its original CALL
and rejection scope, not new allocation branches or exact revert bytes;
Foundry's intercepted diagnostics do not establish those bytes. New scalar
branches are checked by kernel regressions and complete source/IR comparison.
Independent review of the exact frozen candidate is pending; the author does
not self-approve source correspondence.
