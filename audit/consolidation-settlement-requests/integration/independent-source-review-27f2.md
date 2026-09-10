# Independent CONSOL settlement requests review

Verdict: **CLEAN for the bounded source increment** at `27f2394bd9afb416ffc6ed753d57f04d0f082228`, based on `f8ea5f9d3cffc165f5d84dd96444836c806827eb`. No correctness or scope finding identified. This is not acceptance of the whole delivery guarantee or of a later facade/Trust integration.

Reviewer independence: I authored neither these three Lean files nor the consumed proof substrates. I made no project, Git, site, or proof changes during this review. The final checkout remained clean at the reviewed SHA.

## Scope and useful result

I read the complete three new Lean files and their dossier, the consumed definitions and proofs in GatewaySettlement, GatewayCall, Composition, LiveCall and the live call/world substrate, the relevant raw-byte producer, the existing settlement regression fixtures, and the pinned Solidity gateway/vault/request bodies. Core identity is `17005714f151e5502c559932319a3f2f74ac2436`. I also read the retained settlement/source and integration reviews and the earlier PR295 rejection and subsequent accepted actual GatewayCall review; the older missing outer-call finding is addressed by that accepted substrate, not silently assumed away here.

The public theorem in `LidoSRv3/Audit/Guarantees/PConsolidationEth1Requests.lean:13` has the complete existing settlement execution's successful outcome as its only proposition premise. Its conclusion retains the full previous `GatewaySettlement.Success` and conjoins the new effects. It does not replace that certificate with a weaker independent helper result.

`audit/trio/consolidation/SettlementRequests.lean:13` ties the actual gateway payload's decoded arrays to width-valid inbox pairs, the precise per-pair requests, the returned vault/loop world and the subsequent refund on that very world. The proof at lines 59–85 extracts the successful actual GatewayCall, derives its inner loop's correspondence to the consumed loop, and substitutes the resulting world equality into the refund, final world, trace and balance facts. Thus the result supplies useful same-execution composition rather than separate successful executions or an assumed stage equality.

The outer quote is read before vault value credit (lines 18–24); the inner fee is read after that credit (lines 34–35). Their values remain distinct. The theorem derives the necessary inner product equality without assuming fee equality, ABI round-trip correctness, callee frame preservation, or extra stage success. Decoded pairs remain explicit: the statement does not claim they are unconditionally identical to the original raw input arrays. The shared callee and static-call external functions are actual parameters throughout.

## Independent validation

- Compared complete Git trees: all base entries, modes and blobs are unchanged; exactly 14 additions comprise the three Lean files and eleven dossier files. No executor, existing theorem, registry, AllGuarantees/Trust, Lake configuration or dependency pin changed. `git diff --check` passes.
- Recomputed all 13 receipt SHA-256 entries against candidate Git blobs and working bytes: all match.
- Replayed the source/axiom and inherited-evidence validators with project writes intercepted and checked against existing deterministic JSON. All 1,249 source identities and 11 package pins pass; the three generated JSON contents reproduce exactly. This did not rewrite project files.
- Independently recomputed nine scoped axiom sets through the normal Lean environment. The new public/source theorem and their two public regression instances use only `propext`, `Classical.choice`, `Quot.sound`; the other five regression theorems use `propext`. No custom or native axiom was found in these sets. This is a scoped check, not a claim about every theorem in the repository.
- Ran normal `lake env lean` independently on each of the three exact new files: all exit 0 (2.14 s, 2.07 s and 2.86 s). Commands and results are retained in `/tmp/lido-consol-27f2-independent-normal-checks.json`, with individual logs `/tmp/lido-consol-27f2-independent-0.log` through `-2.log`. No heavy build or new compiled artifact was requested.
- The retained targeted Lake log reports 1,266 jobs and success. It replays the source/public modules and builds the regression module (2.3 s); it is not a fresh rebuild of every dependency. The independent normal checks above directly check the exact new source bodies again.
- The seven named kernel regressions include, rather than supplement, the two public-consumer instances. They cover the concrete two-request decoded payload, same-world request/refund effects, zero refund, differing quote/read worlds, changed inner fee rejection and restoration, and rejected refund restoration. The distinct-fee example prevents interpreting the composition as an implicit quote-equality assumption.
- All 41 retained artifact/fixture hashes and the three complete pinned Solidity bodies match. The 9 and 5 Solidity tests are historical identity-based reuse. No fresh Solidity run or new compiled composition refinement is attested by this increment.

## Remaining boundaries

The entry world is already credited with the gateway's payable value. The model omits the stateful gateway prefix, including its full authorization/pause, locator, witness, quota and allocation provenance obligations. Pure checks modeled in the suffix do not establish the omitted prefix or its complete error ordering.

The byte producer and actual decoder are explicit typed models. The new proof assumes no round-trip equality, but does not itself establish full raw ABI/runtime equivalence, all malformed-input error priorities or actual allocation provenance. Event/request traces are semantic model values, not a complete LOG ABI or deployed EVM refinement.

External calls can return arbitrary modeled worlds. The proof establishes the executed loop world, refund input, exact attempt structure and final gateway balance assertion; it does not derive general callee frame preservation, net recipient/inbox balance conservation under arbitrary callbacks, cryptographic authenticity, gas behavior or deployed runtime correctness.

The public source increment is ready for the parent's separate integration review. Any later facade/Trust wiring, merged tree, site claim or deployment requires its own exact acceptance; none is certified by this report.
