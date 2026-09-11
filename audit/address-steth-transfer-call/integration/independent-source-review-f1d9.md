# Independent exact ADDRESS physical stETH-transfer source review

Verdict: **CLEAN for `f1d91e3a8ad9829e92ab2e8ff443e391449a36bc` within the stated typed-call, physical-storage and outward-result scope.** No unresolved source, proof, composition, identity or evidence finding. This is not whole ADDRESS/EVM closure or approval of future integration/publication.

Reviewed clean frozen `/tmp/lido-address-steth-transfer`; sole parent `107e57e53ad4b1bd459a062d887bbcac85be6e41`; tree `ffbccb569db24f1535727b50da1c185e2b15425f`. Author stopped. Complete Git comparison confirms46 additions only: three Lean modules and this dossier. All existing objects, domains and configurations remain unchanged. All45 receipt hashes match exact Git blobs and current bytes. Parent-to-candidate diff-check passes, without excluding any new file. Old raw-assembly EOF exceptions remain inherited and unchanged.

## Independence and reading

I authored none of f1d9, its quote337 or conversion339 antecedents, or its new fixtures/dossier. I did author earlier ADDRESS wrapped-token1d07 and transferFrom a9c6 bodies. Their correctness provenance is the retained independent source reviews `audit/address-wrapped-token-call/integration/independent-source-review-1d07.md` and `audit/address-wrapped-transfer-call/integration/independent-source-review-a9c6.md`, which I read; my present inspection is not presented as independent authorship review of those bodies. Their actual source files still equal those exact accepted commits.

Read all228 lines of new source,52 public lines and114 test lines, including every proof and diagnostic body. Read the full README/receipt, both validators, native driver/program, fixtures and relevant logs/artifacts. Read the complete independent ee24 and107e source reviews from campaign local-goals, plus their actual source/public definitions. Directly followed the consumed old wrapped-token call/burn/decoder, QuoteFormula, Transcript, Live.run/storage/zero-value transfer and actual mapping backend. New quote/conversion inherited bodies are byte-identical to the source revisions independently reviewed. This is not a claim of manually reviewing every proof body among1,263 imports.

## Public consumer and exact World connection

The public runner executes the existing permit/batch/wrappedStep with only the former `tokenTransfer` interpreter specialized to the new `callee`. The first conjunct, PhysicalConversionPermitEffect, retains the entire107e conclusion: complete PhysicalQuotePermitEffect (old permit JoinedEffect plus physical-forward-quote transcript) and the reverse-conversion transcript, all on the same actual output World, IDs and attempts. The second transcript is derived by mapping precisely that existing transcript to stronger Items. No detached successful-stage assumption or parallel recomputed execution is substituted.

The proof chain is substantive:

- Source133 `canonical_call` rewrites the actual generated68-byte request: selector a9059cbb, recipient=the queue caller, amount=the captured received Word, value0, caller=WstETH and target=the dynamically selected stETH address. Typed canonical address/amount decoding is established, not supplied.
- `call_effect`168 uses that equality in the actual old CallEffect. `reply_success`146 derives the true32 bytes and physical ProgramEffect from the exact invoked callee on the zero-value-call World. The impossible successWithTrace branch is excluded because this concrete body makes no external calls.
- `token_effect`196 binds the same original wrapped amount, actual reverse-conversion result, BurnEffect, fresh postburn slot7 target, captured transfer amount, actual decoded return and returned World. It retains the whole old conversion TokenEffect as a conjunct.
- `item_effect`221 keeps the entire old Item and connects physical transferFrom, unwrap, this TokenEffect, the100..1000 ETH amount guards/derived uint128 fit, the queue's actual physical forward quote and same physical enqueue/attempt sequence.
- The public failure theorem applies to this same specialized runner and restores the whole pre-permit World, including permit writes/logs, earlier successful items, burns and transfers. Diagnostic attempts remain observations.

Reverse conversion reads WstETH's qualified slot7 before burn. The transfer separately rereads it from the actual burned World. No equal-target, same-rate, frame or nonalias premise identifies the two. The queue's immutable quote target is also distinct. The new transfer returns exactly encoded true; the existing WstETH0.6.12 decoder reads that word and then discards it. No new “must be true” acceptance guard is invented, and the older arbitrary mutable-transfer theorem still permits its previous decoded false/noncanonical outcomes.

All public execution hypotheses remain whole-run outcomes. Funding, successful primitive stages, strict widths, nonzero divisors and guard admissions are derived from execution. Old arbitrary mutable-callee statements and domains are untouched. The specialization does not authenticate deployed code at an arbitrary selected address.

## Actual physical transfer and pinned correspondence

Read the complete relevant pinned StETH.transfer/_transfer/_transferShares/event functions, Lido rate overrides via the accepted full quote implementation, Pausable, Aragon raw storage and SafeMath, WstETH.unwrap and queue wrapped request. Core is `17005714f151e5502c559932319a3f2f74ac2436`. Full-Lido assembly identity also matches the exact complete artifact independently inspected in the preceding ACCOUNT pause review. New pertinent transfer/return/event paths were inspected directly, not inferred from standalone StETH storage layout.

`program`88 first executes the accepted physical getSharesByPooledEth body on the selected contract and actual pre-move World. It retains strict amount<2^128−1, full-Lido packed I/S reads, raw wrapped multiplication/subtraction and outward empty divisor failure. Thus conversion failure precedes every sender/recipient/pause/funding guard. It uses the captured result for all movement/events; no postwrite recomputation is introduced. Zero internal shares with positive ether can produce a zero-share transfer of a nonzero token amount, exactly as the source allows.

`move`31 follows sender!=0, recipient!=0, recipient!=self, entire physical pause word!=0, sender shares read and funding guard, debit SSTORE, fresh recipient SLOAD, checked addition and recipient SSTORE. `MoveEffect`44 records those actual sequential states and exact resulting World. SafeMath.sub's repeated bound is already established by the executed funding guard. For two uint256 words, the source wrapped-sum>=first guard is equivalent to the model's unbounded-sum<2^256 test; no added fit premise is required. Recipient overflow can leave a dirty intermediate Exec state, but `reply`108 invokes Live.run and exports no rejected post-World. Root rollback remains complete.

Full Lido's actual mapping base is0. Assembly tags1093/1095/1096 clean the address to160 bits, MSTORE owner and zero base, Keccak64, then SLOAD/SSTORE; sender SSTORE precedes the fresh recipient hash/read. `balanceSlot_keccak`19 proves exactly the corresponding two32-byte big-endian words and Keccak output. The backend range lemma removes the offset0 modulo; the separately declared mapping-injectivity axiom is not used by any checked theorem closure. Qualified read/write semantics were inspected. Same-address/mapping aliases are represented by the sequential keys; hypothetical mapping-to-fixed-slot collisions are not erased by a frame claim. Consequently the theorem does not promise unaffected pause/rate/total words under such a collision.

The active literal is exactly `0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece`, independently recomputed as keccak256("lido.Pausable.activeFlag"). Full assembly tag397→430→917 uses raw SLOAD and ISZERO/ISZERO, with no low-byte mask or canonical1 check. Any nonzero Word is admitted, including2,256 and2^255.

Complete transfer entry paths agree: tag307 calls494, which calls forward quote137, movement603, then events605; shared continuation422 supplies true. Source events use original token amount and derived shares. Both actual LOG3 topics and order were independently recomputed/checked: Transfer, then TransferShares. Semantic logs remain the inherited formal abstraction; finite raw-log tests are not promoted to a universal LOG ABI theorem.

## Independent checks, artifacts and evidence reuse

Both validators were read before execution. They normally write deterministic dossier outputs. I ran them with Python bytecode disabled and Path.write_text/write_bytes intercepted under the candidate root: every proposed output had to match existing bytes; none was written. Six outputs compared successfully. Only the existing external temporary Lean.collectAxioms probe was used; no source/kernel build, compiler, Forge or native diagnostic replay was performed.

Fresh independent comparison/query results:

- 1,263 imported/new source identities,11 Git package pins and all selected local source/olean providers pass; every consumed old local source equals107e.
- 13 current transitive axiom sets match the dossier, containing only propext, Classical.choice and Quot.sound. No sorryAx, new native theorem axiom or mapping-injectivity assumption appears.
- All18 normal source/olean/ilean/trace/setup/config records match. Three new setups have empty options/plugins; traces are nonsynthetic and contain no kernel-skip option.
- All45 new receipt hashes match. Parent91 and quote111 receipt hashes also match exact inherited Git bodies.
- All37 original full-Lido compiler input bodies and metadata Keccaks match, including exact pinned core bodies and unchanged vendor provenance. Lido/WstETH deployment artifacts and three full legacy assemblies are identical to their accepted providers.
- All18 queue inputs, executable objects and metadata remain unchanged. The two new artifact snapshots match actual retained compiler outputs; the new test metadata binds19 source inputs. Active-slot preimage, selector, both event topics and four64-byte mapping preimages/hashes were independently recomputed by the evidence checker.

The identity-verified author logs accurately show source/public actively built in the1,279-job public run, followed by tests actively built in the1,280-job run. Prior dependency warnings are replayed; no warning-free or completely fresh dependency-build claim is made. The three normal artifacts just checked bind those exact sources. This source candidate has no new global All/Trust result.

Fourteen finite kernel regressions cover generated payloads, conversion-before-guard priority, sender/recipient/self/pause errors, dispatcher rejection and full-word active admission observed through later funding errors. The two public kernel instances are **empty success and paused rollback**. Nonempty success is intentionally separate executable evidence, not a kernel-evaluated positive batch instance.

Read the complete native runner/program and its PASS log. Four cast-derived mapping vectors are cross-checked by actual Lean FFI; six execution groups cover a nonempty two-item permit batch7/8→700/800 with physical balances and ordered events, late transfer rollback, self-transfer fresh read, recipient overflow, qualified target and selected no-code target. Their freshly built diagnostic C/dylib inputs are separately recorded and match current source/repository identities. They add no theorem axiom and were not rerun by this reviewer.

Read all11 real Solidity tests and the successful1024-run fuzz evidence. Direct tests deploy the complete unmodified Lido artifact and check exact true32, physical shares, raw event topics/order/data, conversion/guard error bytes, any-nonzero pause, insufficient shares, overflow rollback, aliases, zero amount and zero derived shares. The fuzz property uses bounded uint64 inputs and self/distinct recipients; it is not an exhaustive256-bit arithmetic proof.

The composed fixture uses real WstETH and signed permits, two unchanged full-Lido instances with distinct queue targetQ and slot7-selected targetA, and actual stETH.transfer. Its setup seeds storage explicitly. Both successful items check actual amounts/IDs/cumulative shares, A's physical balances, unchanged Q shares and nonce/allowance/supply. Later failure restores permit and earlier burn/transfer/request effects; pause/no-code failures are also exercised. These are substantive finite correspondence checks, not universal signature or deployed-code-authentication proofs. No ConversionHarness/controller or mutable-transfer override is used in this new fixture.

Compiler profiles are retained precisely: full Lido0.4.24+e67f0147 optimizer200 Byzantium, unchanged WstETH0.6.12 artifact, queue/new tests0.8.9+e5eed63a optimizer200 London, fixture code-size limit100000. Only the new19-input test compilation is fresh in author evidence; old Lido/WstETH compilers were not rerun. No production-profile equivalence is inferred. Large exceptional-path gas measurements do not establish gas behavior.

## Remaining scope and disposition

The accepted improvement is a concrete physical stETH.transfer implementation connected to the existing actual selected CALL, preserving the complete permit/burn/conversion/quote/enqueue result. Initial storage/deployment/immutable provenance, runtime code identity, arbitrary malformed dispatcher equivalence, full memory/allocator/gas/EVM trace and general event/error ABI refinement remain outside. The inherited address0 storage convention is explicit. Permit and unmatched-call interpreters retain their accepted boundaries; signature diagnostics do not remove them. Old general mutable-transfer claims remain available unchanged.

No source/cache/dossier/Git mutation, rebuild, compiler/Forge/native rerun, site update, merge or publication was performed. Only this external report was written. Exactf1d9 remains clean. **CLEAN for source review; reviewer STOP.** Root owns the separate integration and publication gates.
