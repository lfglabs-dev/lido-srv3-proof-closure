# SSZ-1: selected compiled execution of the complete CL entry

This increment adds a compiled (`EvmYul EVM.State`) execution of the complete
unmodified pinned `CLValidatorVerifier._verifyValidator` (core
`17005714f151e5502c559932319a3f2f74ac2436`, lines 44-57) as reached through
`SszRootCallHarness.verify(BeaconRootData,ValidatorWitness,uint256,bytes32)`
(selector `0x2e77b4ba`, `audit/ssz-root-call-composition/solidity/SszRootCall.t.sol`),
and a public consumer whose proof-loop root and index are *produced* by that
execution rather than taken from calldata words 68/100. The public theorems are
`PSsz1.actual_compiled_cl_entry_branch` and `PSsz1.actual_compiled_cl_entry_tree`
(`LidoSRv3/Audit/Guarantees/PSsz1CompiledClEntry.lean`). Registry, AllGuarantees,
Trust and site integration belong to the root agent; no existing file is edited.

This is the representation repair named by the 83da6dbe STOP note (section 4,
R1-R3): the join between the typed root-call entry and the compiled harness is
not asserted between two executions; one execution supplies both operands.

## Artifact (R1)

`solidity/inspected-cl-entry-ir.yul` is the `irOptimized` output of the official
solc `0.8.25+commit.b61c2a91` Linux binary (sha256
`c42aada7a52057ddbed93ec011235e256c564c440b68dbaac5ae482babbb3d6d`, from
binaries.soliditylang.org) on `solidity/standard-json-input.json` (viaIR,
optimizer 200, Cancun, `bytecodeHash: ipfs`, remapping
`contracts/=lido-core/contracts/`), with one trailing newline appended exactly as
the retained `audit/ssz-witness-abi/solidity/inspected-harness-ir.yul`. The same
procedure over the seven inputs recorded for the existing BlsCompositionHarness
reproduces that retained file byte for byte (sha256 `1d2924b9…`), which is the
check that this procedure is the one used before. Source identities are in
`solidity/compiler-input-identities.json`; all six core inputs and the harness
match the pinned bodies listed by `audit/ssz-root-call-composition`. The IR is
not edited or invented. Artifact sha256:
`aba7b84e915d3279916e7d18150f047e553c8f712b1e30ea96235e11998679e3`.

## Execution (R2)

`LidoSRv3/Audit/Source/SszCompiledClEntry.lean`, `run fuel cfg external world context`,
in the IR's order:

| IR lines | Source | Executed model |
| --- | --- | --- |
| 36-55 | dispatcher, ABI head | `prologue` (fresh frame, free pointer 128), `header`: value, selector `0x2e77b4ba`, `slt(size-4,192)`, `slt(size-4,96)`, witness offset at word 100 with uint64 guard and eight-word extent |
| 56-97 | `_verifySlot` (89-94) | validator index word 132; proof tail through the existing `SszWitnessAbi.tail`; slot (36) and proposer (68) through `read64`; one existing `pairRun` on `chunk slot`, `chunk proposer`; `slotSibling`: checked `length-2` (panic 0x11), bounds (0x32), `calldataload(offset + 32*(length-2))`, `InvalidSlot` |
| 98-114 | `_getParentBlockRoot` (103-104) | timestamp word 4 through `read64`; `rootCall`: `abi.encode` at the free pointer (value at ptr+32, length 32 at ptr, `finalize_allocation`), `mload(ptr)`, the 32 input bytes read from machine memory, the STATICCALL as the existing low-level primitive on the typed world, reply bytes as the machine's returndata |
| 116-166 | `_getParentBlockRoot` (105-106) | `SszCompiledReply.copyReply`: `returndatasize` switch (zero slot 96), uint64 guard, `bytes memory` allocation through the free pointer, `returndatacopy`; `decodeRoot`: `!success || length == 0` → RootNotFound, `slt(len,32)` → decoder revert, `mload(data+32)` |
| 168-233 | `_getValidatorGI`, `concat` (54, 97-100, GIndex.sol 22-107) | second slot read; `SszCompiledGIndex.wrapper` on the constructor words: fork select, `shr`/`pow`/width, checked adds, range guard, `pack`, both literal Solady `fls` (`SszSoladyFls`), depth guard, final `pack` |
| 234-361 | `_validatorHashTreeRoot` (60-85) | existing `allocate` (256 bytes at the current free pointer), `tail` pubkey slice, existing `pubkeyRun`, key store, `SszCompiledFrame.storeFields` (credentials from word 164, six guarded field stores), existing `SszCompiledConsumer.merkle` |
| 362-417 | `SSZ.verifyProof` (179-248) | proof tail again, existing `SszProofCalldataLoop.verify` with the packed index word and the decoded root word as stack operands |

Everything the earlier increments executed is reused unchanged; the new
executable pieces are the entry-specific ABI head, the slot sibling compare, the
root call and reply handling, and the pure index prefix.

## Frame lemmas with a parameterized pointer

`SszCompiledFrame` restates the allocator/store/load/pair lemmas of
`SszCompiledMemory`/`SszCompiledMerkle` for any cell below the allocator's own
uint64 guard (the leaf array follows the variable-length reply), carrying the
active-word extent below 2^64 instead of 20 words. The fixed-frame lemmas and
`PSsz1.actual_memory_validator_branch` are untouched. A later refactor may
re-derive the fixed-frame lemmas from these (proposal in the delivery note); it
was not performed here.

## What the public theorem derives (R3)

From whole-entry success and the inherited SHA output-width condition only:
the executed guards and slot check (proof word `length-2` equals the pair SHA of
the little-endian slot/proposer chunks); the successful STATICCALL with its
exact request (caller = the machine's code owner, target BEACON_ROOTS, payload =
the zero-extended timestamp word), a code-bearing target, at least 32 reply
bytes, the retained single attempt; the typed `sourceWrapper` result of the
executed slot and validator-index words; the decoded key/field/credential leaf;
a nonempty independent `SszProofFold.Branch` over the consumed proof words from
that leaf to `firstWord (fromBytes data)` of the same reply, at that index. The
tree form restates it in the typed digest vocabulary of the root-call theorems.

## Explicit boundaries

* BEACON_ROOTS callee: the accepted typed `StaticCall.External` on `Live.World`
  (same object as the typed entry). EIP-4788 history-ring authenticity, deployed
  code identity and root freshness are not represented.
* Immutables: the typed `Configuration`'s `pack` words (constructor boundary).
* SHA: the opaque engine FFI, with the inherited `ShaWidth` condition.
* Not identified with the whole ABI-declared proof list; outer opcode gas and
  compiled-bytecode correspondence remain outside; `fuel` is the interpreter
  parameter.

## Validated native successor of the initial candidate

The original imported commit `9723377c3a936c522ec10e88dadcab7e1a7b25b0`
was **not compilable**: GIndex and Frame passed after the remote fixes, but
Reply still had parser/type/normalization failures and ClEntry/public had not
been validated. The two retained independent snapshot diagnostic reports and
`validation/development/` preserve that history and the unsuccessful native
repair attempts. Their error-recovery `sorryAx` output is not proof evidence.

After the remote writer stopped and ownership transferred, the native repair
corrected Reply's record syntax, imported the actual RootCall definition,
normalized byte-array sizes/word casts and qualified overlapping lemmas. ClEntry
now imports the intended Stored predicate explicitly, disables autoImplicit,
and proves its concrete frame/environment transports with unambiguous terms.
No public theorem statement or executable guard/operand was weakened. No
initial memory, successful stage, root equality or index equality premise was
added. The nested-state proofs use maxRecDepth4096 with normal kernel checking;
no maxHeartbeats increase or skipKernelTC is retained.

The initial regression predicting Panic11 for a maximal offset under the
aligned pinned base was false: zero remainder plus that offset reaches the
range guard without overflow. The repaired regression checks IndexOutOfRange
there and separately checks Panic11 with a nonaligned base. Both are kernel
checks of the unchanged index executor.

Final normal validation:

```sh
lake build LidoSRv3.Audit.Source.SszSoladyFls LidoSRv3.Audit.Source.SszCompiledGIndex LidoSRv3.Audit.Source.SszCompiledFrame LidoSRv3.Audit.Source.SszCompiledReply LidoSRv3.Audit.Source.SszCompiledClEntry LidoSRv3.Audit.Guarantees.PSsz1CompiledClEntry LidoSRv3.Tests.SszCompiledClEntryRegression
python3 audit/ssz-compiled-cl-entry/validation/validate.py
python3 audit/ssz-compiled-cl-entry/validation/make-vector.py
python3 audit/ssz-compiled-cl-entry/validation/run-diagnostics.py
```

All seven normal modules pass, with the final targeted warm-cache build reporting
1,232 jobs. The current actual regression import closure checks 1,215 sources,
eleven exact package pins and seven normal artifacts. Thirty-one fresh named
ordinary axiom sets use only propext/Classical.choice/Quot.sound. These scoped
results are not a claim that the future combined global Trust environment is
foundations-only. Fourteen named kernel regressions cover fls, configured GI,
range/overflow order and decoder arithmetic/selector. No whole successful
execution is described as a kernel-evaluated instance.

Four **whole-entry FFI diagnostics** pass. `make-vector.py` independently builds
ABI calldata (2,180 bytes), a validator leaf and 50 sibling words with Python
hashlib SHA256, including the actual slot/proposer sibling. The ordinary entry
executes the actual memory-backed timestamp root request and consumes the
returned root to accept that proof. Corrupting the root or one proof byte fails
at proof verification; changing the timestamp causes the finite external
interpreter, which checks the exact request, to reject. Initial machine memory
is deliberately nonempty before the entry prologue. The diagnostics invoke the
existing EvmYul FFI via a fresh temporary native library; runtime inputs are
hashed separately and these IO checks add no theorem axioms.

All seven retained compiler input bodies are checked against the exact pinned
Git objects and recorded Keccak/SHA256 values. Root independently replayed the
materialized input with its existing **Mac** solc0.8.25 binary and reproduced the
complete retained IR byte-for-byte, including the single appended newline.
`continuous-ssz972-root-compiler-identities.json` identifies that replay; the
original recorded Linux binary was not executed again. The materialized input
and actual replay output are retained for comparison. I read the full relevant
entry/decoder/allocator/GI/fls/SHA/proof-loop IR paths and pinned CL/GIndex source;
independent exact full source/IR review remains the next gate.

No Forge run was performed in this repair. The unchanged seven-input harness
and historical nine-test `audit/ssz-root-call-composition/receipt.json` are reused
as inherited fixture evidence only; they are not a new Solidity execution or a
proof of bytecode equivalence. Full custom-error/revert byte strings and the
success consumer's failure-world rollback are not newly proved. Root owns
AllGuarantees/Trust integration, global checks, independent review and release.

`validation/validate.py --write` regenerates identity JSON after a normal build;
its default invocation compares without replacing the archived JSON. The raw
compiler IR's existing blank EOF is preserved. Historical raw compiler/build
logs remain verbatim. In addition to the IR EOF, only development logs
`lido-ssz-repair-cl-1.log`, `lido-ssz-repair-cl-2.log` and
`lido-ssz-repair-reply-1.log` retain trailing whitespace from Lean error output.
The unrestricted diff check reports those four raw-output files; source and
nonraw files pass. The receipt records this exception explicitly.
