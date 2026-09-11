# Independent ACCOUNT physical-pause source review

Verdict: **CLEAN for exact `62669fad69b4bae620458eff7130b2d5e0017720`**, with the two explicitly preserved raw-assembly EOF whitespace exceptions below. No unresolved correctness, composition or source-correspondence finding. This is source-candidate acceptance, not aggregate integration or whole ACCOUNT closure.

Checkout: `/tmp/lido-account-physical-pause`; parent `295e6c676b61de1815b7027a49ed8bc5fe5b8b3f`; tree `ccc14ab5451258ea128a2fe0b7a55aef94f3de03`. The writer was stopped. HEAD and clean status were checked before and after review. The complete delta consists of40 added paths: three Lean modules and the audit dossier. Every old object and configuration remains unchanged; there is no lakefile, AllGuarantees, Trust or site edit.

## Independence and actual composition

I authored none of these ACCOUNT source bodies or the candidate. I read all three new Lean modules completely (198-line flat source,23-line public module,92-line tests), the complete new fixtures, README, receipts and validator/build code. I followed the consumed ReportFeeTreasuryCall/TreasuryCall, ReportFeeMint, StETHMintShares, FeeDistribution and ReportFeeDistribution definitions and relevant proofs. Retained independent324 reviews `audit/account-treasury-call/integration/independent-source-review-a7ea.md` and `independent-integration-review-c309.md`, and322 reviews under `audit/account-fee-distribution/integration/`, provide prior full-source validation. I checked the directly reused324 and322 consumer bodies remain byte-identical to their accepted source commits a7ea and6c1f. Earlier review work on these modules does not amount to authorship of them.

The new `execute` at source103 actually runs the entire324 executor on `project before`. Projection at11 replaces only legacy `steth.activeFlag` with the full physical word's nonzero interpretation. Its equality with that read is established by construction on the executed input, not supplied by the public caller. `projection` preserves router, physical StETH storage, abstract share map and the existing identity/authentication context.

`OldEffect` at109 is the entire324 public success conclusion with its entry explicitly changed to `project before`: actual report/getter/checked fee/mint, ReportFeeDistribution.Success, pointwise Ledger and the actual treasury-call ReadEffects/events/payment/attempt branch. It is not a weaker replacement certificate. The new public theorem retains it in conjunction with PhysicalEffect; its sole execution premise is success of the whole new runner.

| Obligation | Consumed derivation and conclusion |
| --- | --- |
| Physical pause at mint | `mint_frame`35 inverts the actual successful mint, derives the executed active guard and proves pause-word preservation across the actual total-share-word write. |
| No supplied separation | `total_slot_distinct`33 proves inequality of the two actual literal slots by kernel computation. No nonalias or frame hypothesis reaches the public theorem. |
| Every actual payment | `chain_physical`86 inducts over the executed PaymentChain. Each enhanced Payments constructor keeps the actual transfer equality/effect and its real intermediate state, derives physical active=true and carries the entry pause word. |
| Actual module/read World | `module_world_invariant`128 derives the invariant for every actual successful module result. OldEffect.ReadEffects supplies the corresponding executed module equality, so this applies to that exact middle state observed by TreasuryCall, rather than an unrelated proposed World. |
| Final and intermediate state | `old_success_physical`156 retains actual minted execution, its invariant, module invariant, full ordered payment chain and final preserved pause word. Positive mint derives physical admission; zero mint is explicitly allowed. |
| Root failure | `failure_restores`191 restores the entire original incoming World, including its untrusted legacy flag metadata, while retaining the old diagnostic payment/attempt lists. |

The readonly treasury interpreter has type Request→the actual ACCOUNT World→Reply, with no mutable post-World channel. It observes the projected, actually executed post-module World. There is no hidden frame assumption about a mutable callback. Internal `Frame` is proved from mint/transfer execution; intermediate consistency assumptions in helper lemmas are discharged by projection and induction. No new fit, active-word, fee-positive, successful-stage, funding or external-read-success premise appears in the public statement.

Zero fee skips mint/distribution/treasury. It can still normalize the nonphysical flag metadata. README and public documentation explicitly deny equality of the successful metadata-bearing World with the old unprojected World. Likewise this pure state interpretation is not claimed as an extra early EVM SLOAD instruction trace. These distinctions are necessary and correctly retained.

## Pinned source, complete compiler inputs and relevant assembly

Core pin is `17005714f151e5502c559932319a3f2f74ac2436`. I checked the complete relevant Pausable, unstructured getter, mint, transfer, authentication, accounting lookup and distribution functions, and their complete relevant retained legacy assembly paths. All37 full-Lido compiler input bodies are identity-checked against the accepted exact provider and actual metadata Keccaks; no substituted mini-bool harness is used for Lido execution.

Pausable's literal and the compiled data segment agree exactly with Lean:
`0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece` = keccak256("lido.Pausable.activeFlag"). The Aragon getter returns `sload(position)` directly. Lido.asm tag397→tag430→tag917 uses SLOAD followed by ISZERO/ISZERO for admission. The compiler shares the unmasked storage getter implementation; it does not mask a byte or require canonical1. Thus raw2 and high-bit-only words are active, raw0 is stopped. Nat regression construction explicitly reduces modulo2^256; that is not a claim about non-word EVM inputs.

Actual Lido.sol894–900 and assembly tag193 preserve `_auth(_accounting())` before pause, then `_mintShares`, then event conversion. Existing locatorAccounting is still supplied auth context in Lean; the new result does not claim to execute or prove that deployed locator getter. StETH365–369/494–507 and assembly tag603 preserve sender/recipient/self guards before pause, then funding, sequential debit and fresh recipient addition, conversion and paired events. No recipient callback is invented.

The actual total-share position is `0x6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6`. Complete `_mintShares` and tag368 update its low128 half before the recipient share-map write; the high half is retained. This literal differs from the pause slot, as the new kernel theorem establishes. The proof models the inherited account shares as an abstract mapping, so it does not incorrectly extend literal-slot distinctness to a universal Keccak mapping/noncollision theorem.

The actual Accounting `_distributeFee` body in the new DistributionHarness is byte-identical to pinned Accounting. Its only wrapper/interface change from the accepted treasury fixture is replacing fixture `mintSetup` with actual `Lido.mintShares`. The fixture deploys the complete unmodified Lido artifact; no pause, bool, transfer, mint or rate override is present. The mock locator authenticates actual caller/selector/length, checks already executed module balances and actual Lido pause interpretation, then returns the consumed treasury address. Storage setup and deployment/context remain fixture assumptions, not formal provenance results.

## Independent validation and exact reuse

The validators normally write dossier outputs. I read their complete code first, then executed them with Path.write_text/write_bytes intercepted under the candidate root to assert byte equality instead of writing. Eight intended outputs compared successfully. Python bytecode writes were disabled. The scoped axiom query uses the existing isolated temporary Lean.collectAxioms probe; no source compilation or cached olean output was requested. No build/compiler/Forge/native diagnostic was repeated.

Independent checks passed:

- All39 receipt hashes match exact6266 Git blobs and current files; all40 added paths and preservation of every old object were checked.
- All40 actual imported/new source identities,11 package HEAD/manifest pins and six complete pinned core Solidity bodies match. The two actual prerequisite setup closures select matching current local sources and oleans, including cross-worktree cached providers.
- All three new source/olean/ilean records match current artifacts. The flat source is manually compiled before its public consumer and tests; the unchanged prerequisite build/provider supplies its imports.
- All nine freshly queried actual-environment axiom sets exactly match the dossier and contain only propext, Classical.choice and Quot.sound. Public success and rollback transitively include the new invariant proofs; no sorryAx, native-decision axiom or extra premise is present in their current closures.
- All111 retained exact quote-provider hashes match `ee24f9dc158ed25cec118a8ab8cd3a4fc59942f1`; all37 full-Lido metadata source Keccaks, deployment artifact and complete retained assembly match. The pause Keccak and exact distribution body were independently checked. Fresh caller/test/locator artifact metadata and full new caller assembly match their retained snapshots and source bytes.

The normal passing log is precise: a39-job registered prerequisite build, largely replayed cached modules, followed by three sequential ordinary `lake env lean -o ... -i ...` compilations. It is not a registered full-root build. The build script checks subprocess exits and emits its final PASS only after all three return successfully. Existing prerequisite warnings and the new test's unused pattern-binding warnings are retained; no warning-free claim is made.

Formal regression credit is fifteen kernel computations in tests plus the literal-slot inequality in source, totaling16. There are two public kernel instances: one nonempty successful report→mint→module→treasury execution and one late-failure whole-entry rollback. They are not two successful executions. The successful case deliberately supplies contradictory original flag metadata, requires the treasury interpreter to observe the normalized physical state, and checks real payments/events. Tests also cover raw0/2/highbit/modulo-word construction, auth-before-pause, recipient-before-pause, zero-fee normalization and forbidden readonly state change.

The hash-verified author-run Solidity log passes13 cases, including1024 arbitrary-word fuzz runs. I inspected every test. The cases use real full-Lido isStopped/mint/transfer, paired phase execution, preserved high pause word, exact competing revert reasons, late treasury-zero rollback, forbidden SSTORE under STATICCALL and zero-mint skip. They exercise actual source execution in the fixture, not the full deployed Accounting oracle-report entry. The large forbidden-static gas number establishes no gas property. No independent fresh Forge run is claimed here.

Compiler profiles remain explicit: reused Lido solc0.4.24+e67f0147 and fresh fixture solc0.8.9+e5eed63a, optimizer200, Byzantium. This does not assert production-profile bytecode equivalence. The prior unrelated compiler warning remains evidence history, not a signature claim.

Failed development logs are correctly retained as failures. Source simplification and early test parsing/reduction attempts include errors and temporary sorryAx output. They are excluded from passing proof credit. The final successful build and current independent nine-scope query establish the corrected exact candidate, without borrowing axioms or success from failed runs.

## Limits and final gate

This removes the independent activeFlag input for the new executed interpretation. It does not physicalize the abstract share map, derive deployed contract separation, execute the earlier accounting locator authorization call, close report prefix/reward/rebase suffixes, or establish unified EVM instruction, full ABI/memory/gas/compiler refinement. Those are retained inherited boundaries, not newly added public premises. All older arbitrary-flag public versions and domains are untouched.

Unqualified parent-to-candidate diff-check exits2 solely for preserved raw compiler EOF blank lines: `DistributionHarness.asm:1609` and `Lido.asm:16951`. The complete snapshots match their compiler/provider artifacts; excluding exactly those two raw outputs yields PASS for every source and other artifact. The dossier discloses this exception rather than reporting blanket whitespace success.

The source is CLEAN within this scope. Root still must register ReportFeePhysicalPause in the existing AccountAddressChecks provider and validate canonical aggregate/Trust imports in the integration candidate; this source verdict is not a claim that those steps already occurred. No project/cache/Git mutation was made. Only this external report was written. Exact6266 remains clean; reviewer STOP.
