# DEPOSIT actual module CALL through the actual beacon suffix

Source pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Integration base: `f8ea5f9d3cffc165f5d84dd96444836c806827eb`.

The new public consumer is `PDeposit1.actual_module_call_metadata_suffix`.
`ModulePhysicalMetadata.execute` issues the actual zero-value
`obtainDepositData(uint256,bytes)` CALL, decodes its raw two-byte-array result,
checks alignment/count/value, updates the physical packed module word and
router event on the module-returned world, and runs the existing
`LiveBeacon.suffix` on that updated world. Root failure restores the whole entry
world while retaining module, nested and suffix attempts.

The selected allocation and immutable maximum effective balance are typed
inputs. The module address is the low 160 bits of the physical config slot;
the cap is the third uint64 in physical deposits slot +1. Both are read before
the module CALL. The target is `min(cap, selected/maxEB)` with division-by-zero
and zero-target guards. The target and cached address are never reread after
module execution. Returned public keys may be shorter than the request or
empty; signatures are checked by the existing positive suffix after withdrawal,
not by an invented early guard. Empty keys still commit module effects and the
physical metadata/event, and make no withdrawal or beacon call.

`Commitment` contains equations for the actual CALL, exact raw decode,
preparation, actual suffix and chronological journal, all derived from one
successful executor result. The public theorem additionally derives the
arbitrary coded callee's raw reply/returned world, count and checked value,
physical packed fields, and either the zero-key commit or the existing real
`LiveBeaconCommitted.SuffixCommitment`. No supplied successful stage, frame,
module count bound or synthetic module result is an executor input.

## Byte and memory projection

The exact selector is `0xbee41b58`. Payload encoding has a two-word head,
bytes offset 64, a length word and zero padding. The fresh pinned-solc fixture
compares 64 actual Lean byte vectors with compiler encoding and decoding, in
addition to 256 fuzz cases. Hand-built noncanonical return bytes independently
exercise shared offsets/head aliases, reversed and unaligned tails, omitted
final padding, and trailing bytes.

The retained solc 0.8.25 IR performs a zero-value CALL without an EXTCODESIZE
precheck, copies its returndata into the CALL buffer, finalizes that allocation,
then decodes the first bytes completely before checking the second offset.
`Input.returnBuffer` is an explicit uint256 free-memory pointer at that phase;
its origin in the earlier allocation/preamble is outside this added suffix. It
is not fixed to 0x80 or constrained by a caller-supplied bound.

The model executes all three scalar allocator checks. `round32` performs
uint256 ADD wrapping before the low-bit mask; `finalizeAllocation` checks the
uint64 ceiling and wrap below the previous pointer. The return-size/head
subtraction and absolute bounds use EVM word arithmetic and signed comparison
where the IR uses SLT. In particular a near-2^256 size can pass a wrapped
allocation and is still rejected by the signed head guard. The host byte-list
length is projected to the EVM uint256 RETURNDATASIZE, without assuming a new
host length bound. The first/second byte length words have the uint64 guard;
allocation precedes each unsigned payload extent check.

The small copied range is derived from allocator plus signed head guards.
There is no claim that Lean list copying is a verified execution of EVM memory
copy opcodes, that the earlier source prefix produced the supplied cursor, or
that gas/memory expansion always succeeds. The accepted LiveBeacon suffix
retains its existing memory abstraction after the newly executed decoder.
The scalar guard tests are explicitly IR arithmetic projections; they do not
pretend to allocate enormous concrete EVM buffers.

## Source coverage and remaining boundaries

- StakingRouter.sol:950–976: cached address, selected allocation boundary,
  physical cap, target/zero guards, actual module call, decoded count/guards,
  checked product and pre-suffix physical metadata/event.
- StakingRouter.sol:978–996: existing consumed LiveBeacon suffix, including
  zero-key early return, actual RESERVE withdrawal, actual beacon dispatcher,
  and final live router-balance assertion.
- SRTypes.sol ModuleStateConfig/ModuleStateDeposits, SRStorage.sol mapping root
  and getter, SRLib.sol:896–900: physical field positions and metadata update.
- BeaconChainDepositor.sol:43–63 and accepted LiveBeacon/TopupBeaconBatch source
  semantics remain the positive continuation. No ALLOC-1/2 or RESERVE-1 proof is
  changed or newly claimed by this addition.

Earlier Lido.getDepositableEther, ALLOC execution/admission, registration and
credentials/config provenance, memory-cursor origin, immutable/deployment
identity, and full compiler/deployed-bytecode correspondence remain outside
this additional consumer. Context credentials are captured before the module
CALL. The external module may change any modeled world component; there is no
new frame assumption or conservation claim across its arbitrary behavior.

The CALL rule inherits the existing ordinary-no-code acceptance arm (empty
return, rejected by the decoder); precompile dispatch is outside that arm's
scope. Faults and logs retain the accepted semantic representation, not a new
complete revert/event ABI proof. Root rollback is the existing Live.run rule,
not a new proof of the EVM transaction journal.

## Validation

`validate.py` reruns the focused normal-kernel Lean checks, the actual positive
and late-beacon runtime checks, the byte-vector export and pinned Forge suite,
then records source hashes and tool identities. `check_receipt.py` checks the
retained manifest without rerunning tools. Every new production theorem and
the positive nonvacuity fixture is checked by the ordinary Lean kernel; no
native_decide, axiom, sorry or reduction escape is introduced. Imported caches
are reused and identified; this is not a clean rebuild of all dependencies.

Independent source/IR review of the final frozen commit is required before
integration. Existing guarantees and their claims remain unchanged.
