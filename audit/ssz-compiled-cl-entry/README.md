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

## Validation

Focused Lean check (Lean 4.31, existing dependency cache):

```sh
lake build LidoSRv3.Audit.Guarantees.PSsz1CompiledClEntry LidoSRv3.Tests.SszCompiledClEntryRegression
```

Kernel regressions (`decide +kernel`): literal `fls` on the header, pinned and
boundary values; compiled index of the pinned configuration equals the packed
typed value `1430·2^40 + offset`, power 40; range/wrap rejections; decoder word
arithmetic. The machine-level phases run the opaque SHA FFI and are not
kernel-evaluated, as for the existing compiled increments. No forge run was
executed in this lot; the existing 9-test `SszRootCall.t.sol` receipt exercises
the same harness.
