# Independent review — TOPUP physical credentials getter

Candidate: `367412569a2dd85972ab8bdab8304d261fa7b4ec`  
Tree: `0d7c06dca0bf4ddb6a91d1399dcb2807f037a454`  
Parent: `f00863276fbe279c566328ed4ae90f5bf223a38e`

Verdict: **source/proof composition CLEAN within the stated typed scope; exact release gate pending one minor documentation correction**. No logical or source-correspondence defect found. README currently overstates the coverage of its concrete type-byte regressions; resolution requires only precise wording and the corresponding receipt hash, not recompilation.

## Independence and inherited proof provenance

I authored none of the three new 3674 Lean files. I previously authored the reused `DepositPhysicalAdmission` substrate. Consequently this is an independent review of the new dispatcher, getter connection and public composition; my present reinspection of the inherited helper bodies is **not** a new independent review of my own work.

The substrate's independent acceptance is recorded in the unchanged repository artifacts:

- `audit/deposit-physical-admission/integration/independent-source-review-39f4.md`, reviewing `39f48452bd5bdfff2478fffabe4b53efb20ad21e`, SHA256 `c37efb46ff225791363c6f3275591418d7937ee039a1b06555beb31b5f3099af`.
- `audit/deposit-physical-admission/integration/independent-integration-review-7305.md`, reviewing `73055005e3126742dfb949247ab76859e9dd50e6`, SHA256 `e40e6599c894916fa30cf6a43801eae2f28c42aa892ad07fa064b6f257530779`.

I independently compared complete `DepositPhysicalAdmission.lean` and `TopupRouterCredentials.lean` Git blobs at 39f4, 7305, f008 and 3674: identical. Both prior reviews remain byte-identical. Their physical operands were checked directly against the pinned Solidity and retained compiler IR for their actual use here. The deposit program's authorization, status and Active checks are not called by this new getter.

## Finding

**P3 — regression coverage wording, README.md:75–78.** The sentence attributes “all uint8 types” to the seventeen kernel regressions. `Tests/TopupPhysicalCredentialGetter.lean`'s `all_type_bytes_returned` is a concrete type-255 example, not 256 exhaustive instances. Other representative bytes are exercised separately. The general selection formula is indeed universally proved by `Source/TopupPhysicalCredentialGetter.lean:44–54`, using the inherited `selected_fields`; this establishes the algebraic result for every packed word, but does not turn the concrete tests into an exhaustive sweep. Replace the regression-list phrase with “representative type bytes including 255”, optionally describing the universal theorem separately. No Lean changes or new tests are necessary.

## Source-to-public-consumer assessment

The complete new source, public theorem and tests were read, together with the consumed f008 runner/public conjunction, physical storage helpers, relevant actual source bodies and complete retained IR functions. The core is pinned to `17005714f151e5502c559932319a3f2f74ac2436`.

| Obligation | Evidence and assessment |
|---|---|
| Actual module ID and target, not an unrelated successful getter | Source:32–38 decodes the incoming selected-selector request; `dispatch_request` at 58–72 proves that the actual canonical request traverses this decoder with the same module ID and target. `run` at 82–85 passes this dispatcher directly to f008. Public:47–50 consumes its actual response and decoder result. |
| Actual physical registration | StakingRouter:1099–1107 invokes SRUtils `_requireModuleIdExists`; SRStorage uses EnumerableSet.contains. The retained IR:4249–4260 and 5152–5160 reads the mapping at `keccak(encode32(id) ++ encode32(routerRoot + 2))`. The getter tests nonzero qualified storage, not lastModuleId, set length or array consistency. Missing membership returns selector `d41d6282` before selecting credentials. |
| Correct packed type and raw word | SRTypes places configuration at the module mapping base, type at bits 232–239, and router withdrawal credentials at root+4. StakingRouter:639–642/1046–1049 and IR:2814–2829/4537–4543 select this uint8 and replace the high byte, retaining low248. Public:17–22 derives membership, exact selected word, type2 and preserved low248 from whole-run success. |
| No invented status or type admission | This getter does not access the status enum or enforce Active, nor validate type1/type2. The source accepts every extracted byte; the inherited gateway prefix guard then requires type2. Concrete status255/type255 tests distinguish these operations. |
| Exact selected word is consumed downstream | Public:24–46 retains the same canonical response, decoded word, allocator result, `resolved e wc`, complete `TopupBatchRootCalls.Success`, `TopupRootCallEffects.Effects`, module call, result identity, journals and both module decoder/cursor conditions. Its proof passes through the previous full conjunction rather than replacing it with weaker helper facts. |
| Order and rollback | The f008 runner checks lengths before lookup, executes lookup before root/module calls, allocates return space before scalar decode, and checks the decoded high byte before the downstream batch. Public:60–66 restores the complete entry World on every modeled error. Tests include registration failure with an invalid cursor and late module allocation failure retaining attempts while restoring state. |

The router namespace root was independently recalculated by the reviewed validator from the exact ERC7201 preimage, and both selectors were checked. The four relevant retained IR functions expose the root arithmetic, qualified mapping preimages, nonpayability/signed decoder guard, packed read and canonical return. Their complete source input identities match the pinned core and accepted OZ vendoring under the retained solc 0.8.25, viaIR, optimizer 200, Cancun fixture profile. This is not a new compiler execution or production bytecode identity claim.

## Validation and identity

The checkout was clean at the exact candidate throughout. The parent-to-candidate diff contains only seventeen additions: three Lean files and fourteen audit artifacts. `git diff --check` passes. All sixteen receipt hashes were independently checked against both exact candidate Git objects and filesystem bytes.

After reading its implementation, I ran `python3 audit/topup-physical-credential-getter/validation/validate.py` in its default comparison-only mode. It exited 0 and reproduced the archived records: **1,349 actual source identities, 11 package pins, 24 ordinary foundational axiom scopes, 28 retained compiler inputs, three normal module artifacts**. The fresh scoped inspection admits only `propext`, `Classical.choice`, and `Quot.sound`; new declarations introduce no axiom, native theorem shortcut or skipped kernel checking. Sources, selected imports, setup, trace and olean identities matched.

The archived named build reports success at **1,366 jobs**. Precisely, its final command **replays the new source and public modules** and **actively builds the new tests in 5.6 seconds**. I reused those exact normal artifacts and the log by identity; I did not report three fresh builds from that final log, and did not repeat a build. There are seventeen named kernel regression theorems plus a concrete full public success instance. Their structural positive fixture uses the acknowledged partial constant SHA interpretation.

Separately, the archived runtime log records four successful fresh author FFI diagnostics using byte-identical f008 independent Python SHA vectors: physical credentials plus three actual root calls and `[1 ETH, 0, 2 ETH]` physical continuation; missing membership; changed physical low bits causing invalidProof; type1 rejected before roots. The diagnostics and loader were read, their runtime/vector identities checked. They use actual SHA FFI with an explicit test mapping-hash interpretation, and are executable diagnostics rather than kernel proofs or deployed EVM executions. I did not rerun native code, Forge or the compiler. No global All/Trust build is claimed for this source-only candidate; integration remains separate.

External machine-readable evidence: `/tmp/lido-topup-physical-3674-independent-evidence.json`. Independent comparison output: `/tmp/lido-topup-physical-3674-readonly-validation.log`.

## Boundaries preserved

This proves the selected typed getter and its connection to the existing public batch consumer. The physical getter observes the initial World used by its actual STATICCALL. It does not equate that credential with a later physical reread after arbitrary module or callback effects, and adds no frame, injectivity, range, membership or successful-stage assumption.

Mapping Keccak interpretation, actual deployed code/layout provenance, callee memory allocation/copy and gas, and the existing typed SHA/root-response trust boundaries remain explicit. Nonzero membership is the source's contains predicate, not a proof of registry reachability or array consistency. Other selectors are outside this selected dispatch slice. Outer gateway authorization, pause/timing/locator/root-age/ABI admission, gateway-to-router entry CALL/role binding, final gateway history write and caller cursor/copy provenance remain inherited open obligations; this increment does not claim to discharge them. No whole-guarantee or deployment certification follows from this bounded acceptance.
