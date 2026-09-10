# Independent exact-head TOPUP memory review — CLEAN

Reviewed candidate: `2063fb762cda58e6824f64cb8a395ebace58f24c` in `/tmp/lido-topup-memory-call`.
Base: `2c2c72a91cd68a43de0777912772d12cc48a285d`.
Pinned Solidity core: `17005714f151e5502c559932319a3f2f74ac2436`.
Reviewer: `/root/topup_memory_exact_review`, independently assigned after the author stopped. I authored none of the candidate. Candidate repository remained read-only and clean throughout. This report is the only durable file written by this review.

**Verdict: CLEAN for the declared additive covered-phase scalar-memory theorem. No blocking correctness, composition, source-correspondence or evidence-integrity finding.** This verdict applies to the exact frozen head, not future integration/wiring or a stronger compiled-memory/whole-Ethereum claim.

## Complete changed-source review and composition

Read all four new Lean files completely: `TopupModuleMemory.lean` (176 lines), `TopupBatchMemory.lean` (83), `PTopupMemoryCalls.lean` (53), and `TopupModuleMemoryRegression.lean` (82), together with the complete new dossier and validator bodies before choosing read-only checks. The diff contains only four new Lean files and twelve new dossier files; all sixteen entries are additions. No inherited executor, theorem, global wiring or old ALLOC/RESERVE domain was changed.

`TopupBatchMemory.run` executes inherited input-length checks using the actual packed gateway configuration, then the same ordered root/witness loop. The loop consumes each row/proof and produces the pubkeys and wei limits supplied to `TopupBatchConsumer.moduleInput`. I expanded `TopupGatewayRootCalls.Authenticated`, the loop, `moduleInput`, packed `blockCap`, and target computation. Root calls use the gateway caller and initial immutable World; their verified static semantics preserve that World. Target is the inherited capped/rounded computation on the initial router storage, with the earlier allocation still arbitrary.

`finish` invokes `TopupModuleMemory.execute` once. Its program invokes `TopupModuleCall.call` once with the actual physical module address, serialized payload, router context and zero value. The returned bytes enter the new decoder. `Live.bindExec` passes the successful CALL's returned World into the existing continuation and appends the actual attempts. The allocations selected by this decoder are the allocations in `continuationInput`; neither a supplied success oracle nor a reported-but-unused payload substitutes for execution. The scalar final cursor is exposed for the scalar conclusion; subsequent memory allocation simulation is not claimed.

`program_success` derives old-decoder success for these identical bytes and values, then proves equality of the full execution results. `execute_success` transports through rollback; `TopupBatchMemory.run_success` lifts the equality to the complete root/module result. These equalities are proof-level projections, not second external calls inside the executable definition. The public theorem derives both inherited `Success` and `Effects` on this exact result, together with actual reply, both allocator success equations, copied-range bound and cursor conclusions. Its only execution premise is success of the new whole covered phase. There is no extra hstage, hdecode, size, no-wrap, alignment, sum or canonical-ABI premise.

## Expanded public meaning

I expanded `TopupBatchRootCalls.Success`, `TopupRootCallEffects.Effects`, `TopupRouterCommitted.PositiveEffects`, module-call origin/continuation, and `Live.run`/`bindExec` rather than relying on theorem names. The retained conclusion relates the same ordered authenticated rows to produced limits, derives exact mathematical sums below 2^256 and the storage-derived uint64-gwei block cap, and preserves actual root/module attempts and final World.

The zero-total branch retains the module's returned World and appends the router event without withdrawal/helper calls. The positive branch exposes the actual withdrawal World followed by the actual helper World, physical beacon slot32 count increment and capacity, helper balance relation, final balance assertion, logs and concatenated traces. These are relative to the post-module/post-withdrawal Worlds specified by the inherited theorem, not an invented pre-module conservation/frame property for an arbitrary callee. Determinism of the same calls/decoders makes the existential witnesses in the conjuncts coherent.

The new universal failure theorem restores `e.before` on input/root, module, memory-decoder or continuation failure. Diagnostic attempts remain observable, including a successful module CALL whose World changes are subsequently rolled back. No reverse implication from old memory-abstract success to new success is asserted.

## Pinned Solidity and complete pertinent IR functions

Read pinned `StakingRouter.sol` around the complete allocateDeposits/amount/continuation suffix and the retained optimized IR call site, argument construction, failure branch, decoder call, amount loop and positive suffix. Checked the complete pertinent `finalize_allocation`, `array_allocation_size_array_uint256_dyn`, `abi_decode_array_uint256_dyn_memory_ptr_fromMemory`, and `abi_decode_array_uint256_dyn_fromMemory` bodies, not only fragment matches. Retained settings/metadata establish solc `0.8.25+commit.b61c2a91`, optimizer 200, viaIR, Cancun in the BatchRouter fixture.

The scalar execution order corresponds:

1. Actual successful CALL return size is projected to a uint256 word. Raw-return allocation occurs before any head rejection. Imported unchanged DEPOSIT321 `round32` performs wrapped ADD(size,31) then the low-five-bit mask; `finalizeAllocation` performs wrapped cursor ADD and rejects next >= 2^64 or next < cursor with semantic Panic(0x41).
2. Wrapped end-minus-base is tested by signed comparison against 32; offset >= 2^64 rejects empty. The absolute location+31 signed bound precedes loading the count.
3. Count >= 2^64 produces Panic(0x41). The uint256[] allocation is exactly 32*count+32, at the **post-raw** free pointer; it precedes the unsigned source-end bound. Failure of that extent produces the empty fault. There is no substituted bytes-array size formula.
4. Successful guards derive bounded nonwrapping copied pointers and complete word extents. The readWords result is the identical retained byte decoder result. Unaligned offsets and unpadded admitted tails remain allowed.
5. The retained amount loop checks gwei alignment before limits indexing (Panic(0x32) for an overlong access), then per-limit admission, wrapped unchecked accumulation, target bound, zero/positive branch and final balance assertion. The composition does not reorder these guards.

The raw allocator alone is insufficient to rule out near-2^256 rounded-size wrap. `raw_bounds` correctly uses the signed head guard jointly with allocator success to derive the nonwrapping range; the public theorem does not hide this obligation in an input premise. Host list lengths are projected, not rejected by a new artificial host-size admission rule.

## Independent checks and evidence identity

All checks below passed locally, without paid resources, other model services, network compiler runs or candidate mutations:

- Recomputed all **15 receipt artifact hashes** from disk.
- Reconstructed the actual four-target `.setup.json` import closure and matched all **1,340 source identities** to those resolved source paths. Inherited local source bodies matched base Git; package source bodies matched pinned Git. All **11 package HEADs** matched the manifest/receipt pins. Actual paths include the shared existing Mac package cache; cache location was not treated as identity evidence by itself.
- Rechecked all **17 inherited artifact hashes and base Git bodies**, all **28 compiler input bodies**, pinned core Git bodies and the complete retained IR hash. This independently reproduces the meaningful read-only identity checks without executing the dossier writers.
- Recomputed all **21 declared axiom closures** from the actually imported built environment using the independently elaborated `Lean.collectAxioms` probe in the existing trust checker. Exact agreement with `axioms.json`; union is only `propext`, `Classical.choice`, `Quot.sound`. No native-decision or new admitted axiom dependency appears in these scopes.
- Freshly elaborated each of the **four exact source files** with local Lean 4.31.0 using `lake env lean <source> --setup <actual setup>`, without `-o`, `-i` or `-c` output options. All four returned exit 0. This rechecks the new proofs and regressions against the verified cached dependency closure without modifying olean/log/receipt files.
- The identity-verified original build log records **1,357 successful jobs**. I reused that full-closure receipt rather than claiming a fresh full build. The fresh focused elaborations cover **12 normal-kernel/identity-transport regressions plus one full public instance**, including canonical decoding, raw-allocation-first, empty head, array-allocation-before-extent, short payload, count panic, unaligned empty tail, real two-root batch success, old-result identity, post-module memory rollback and positive physical execution transport.
- Final HEAD remained exactly `2063fb762cda58e6824f64cb8a395ebace58f24c`; final `git status --porcelain` was empty.

## Limits retained in the CLEAN verdict

This is a typed covered-phase **scalar** allocator/decoder refinement. `returnBuffer : Word` is an explicit phase input. Its provenance/alignment, the preceding allocation and memory phase, actual returndata-copy relation, mutable-memory aliasing (including free-pointer/spill-slot overlap for arbitrary cursors), and whole bytecode/ABI memory execution remain outside. The immutable copied-return view is expressly disclosed, consistently with the accepted DEPOSIT321 scalar boundary. Arbitrary supplied cursors are therefore not a claim that actual EVM writes preserve that view. No full memory simulation follows merely from matching scalar guards.

Earlier authorization/pause/locator/configuration provenance and final gateway history work retain their inherited scope. Cryptography, root semantics, consensus/CL linkage, ordinary-no-code versus precompile dispatch, declared Verity/compiler boundaries and opcode gas remain the accepted boundaries. Semantic Fault labels are not a new theorem of complete revert-byte ABI. There were **zero fresh Solidity runtime tests**: retained Foundry evidence is reused only for its historical CALL/rejection scope, not for new memory branches or exact revert bytes. New branches have focused kernel evidence and source/IR review.

No requirement to narrow old claims, alter old domains or add stronger unproved premises was found. Integration with the later ACCOUNT322 main head and global wiring is the root agent's subsequent work and is not certified by this frozen-candidate report.

Review complete; reviewer stopped without changing the candidate or publishing externally.
