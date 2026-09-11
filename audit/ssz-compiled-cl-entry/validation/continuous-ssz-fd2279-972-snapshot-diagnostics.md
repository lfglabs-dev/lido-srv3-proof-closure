# Bounded SSZ fd2279 972 snapshot diagnostics

**Outcome: changed GIndex and Frame now compile normally; Reply fails with newly observed errors. ClEntry/public remain dependency-blocked. No SOURCE CLEAN, whole-Solidity review, release or integration verdict is given.**

## Writer freeze and exact acquisition

Independently read actual mission digest fd22792c-4a75-4239-bd6b-b6eda143ad71: status awaiting_user, awaiting_kind ack; generation4 execution terminal, healthy, reason TurnComplete, ended/heartbeat 2026-09-11T00:56:51.849398270Z. Root's durable stop instruction remains controlling; no resume, acknowledgement, mission hint or writer restart was sent by this reviewer.

Using the existing native helper with read-only workspace_bash, fetched six authorized SSZ files from `/workspaces/mission-fd22792c/temp/proof-main` in workspace a582a491-be96-4ede-8d14-1fb7897f7622. HEAD before and after acquisition was `9723377c3a936c522ec10e88dadcab7e1a7b25b0`, parent `2c2c72a91cd68a43de0777912772d12cc48a285d`. Every captured byte was compared on the remote with its exact committed Git object. This commit's delta is twelve additions only, comprising seven Lean files and five audit/compiler files; no existing tracked source is changed. The remote checkout is not entirely clean: `SszCompiledClEntrySlice.lean` remains untracked. It is not imported by the six designated modules and is not committed, so it was excluded from copying and proof credit. The committed regression/audit files were identified in the delta but not copied or tested by this bounded six-file diagnostic.

The local mirror `/tmp/lido-ssz-fd2279-check` retained its existing tracked baseline. Before copying, I checked that each destination was an untracked snapshot path. Only changed GIndex/Frame snapshot bytes were replaced; Fls/Reply/ClEntry/public already matched and were left untouched. No shared package or tracked baseline source was replaced. Previous GIndex/Frame copies remain under `/tmp/*-fd2279-second.lean`. All final snapshot hashes match the acquisition manifest.

## Exact sequential normal commands

1. `lake build LidoSRv3.Audit.Source.SszCompiledGIndex`: **PASS**, 788 jobs, active compile1.2s, elapsed2.04s. This changed 9b58af30 source fixes the previous leading pure-bind and word-normalization errors. The fallback `(unfold word; rfl)` is reported unused/unreachable because the preceding `rfl` succeeds; these are linter warnings, not proof failures. Printed wrapper_success uses foundations only, pinned_words propext.
2. `lake build LidoSRv3.Audit.Source.SszCompiledFrame`: **PASS**, 1,140 jobs, active compile4.6s, elapsed5.48s. Changed 0984e6f0 actually normalizes the loadedLeft hypothesis/goal and supplies the converted hsize at store_read_after. Both previous blockers are resolved. Its five printed closures use only propext/Classical.choice/Quot.sound, with no error-recovery sorryAx.
3. `lake build LidoSRv3.Audit.Source.SszCompiledReply`: **FAIL**, 1,141 target jobs, active compile2.3s, elapsed3.51s, exit1. The unchanged 842a09b2 source could now be attempted for the first time because Frame passed. Full normal output is retained, and no retry was made.

These were three sequential normal Lake commands on warm dependencies. Fls was replayed unchanged, not recompiled. ClEntry/public were not attempted because Reply has no successful current elaboration. No full build, remote Lake, speculative source edit, native run or Solidity run occurred. Both passing modules have ordinary empty setup options/plugins, nonsynthetic traces and no skipKernelTC setting. Current passing artifacts are separately hashed; no successful artifact claim is made for Reply.

## Reply failures: primary issues and cascades

All locations refer to exact Reply842a09b2.

- **33:40, 229:38, 274:38, 313:38, 335:40: unexpected `(`, expected `}`.** The nested record field `toMachineState :=` has a multiline method application parsed incorrectly under this layout. Parenthesize the complete `st.toMachineState.returndatacopy ... ... ...` RHS and keep its continuation inside those parentheses. The same expression pattern also occurs in proof-local memory equalities at235 and281; they were inside declarations already rejected earlier and deserve the same consistent syntax repair. This diagnosis targets syntax/layout, not a memory semantic change.
- **98:2: No goals to be solved.** The preceding rewrite at97 already closes word_of_bytes by definitional equality. The trailing `apply ByteArray.ext`/`exact Array.toArray_toList` at98–99 are redundant; remove them rather than add a premise.
- **110:29: unknown Array.toList_toArray**, with the accompanying goal at108. The actual pinned Lean core declaration is **List.toList_toArray**, `as.toArray.toList = as`, in Init/Data/Array/Basic.lean133. The same incorrect qualifier occurs at150. The opposite direction Array.toArray_toList exists but is a different theorem.
- **148:4/149:9: unknown SszRootCall.fromBytes.** Reply imports only Frame; this dependency chain does not load SszRootCall. A direct import of `LidoSRv3.Audit.Source.SszRootCall` would make the used definition available; the inspected RootCall imports VerifierEntry and LowLevel, not Reply, so this does not visibly create a cycle. Merely importing RootCall later in ClEntry cannot make it available while compiling Reply itself.
- **205:4: omega failure in hpre.** The counterexample splits `dest.size` from `dest.data.size`. Normalize with the existing `ByteArray.size_data` when simplifying the array extraction/replicate lengths, or explicitly change both occurrences to the same size expression before arithmetic. The identity min(d,size)+(d-size)=d needs no new bound assumption.
- **215:7: invalid field notation on `(_ ++ _).extract`.** The underscore operands do not give the elaborator a ByteArray type. Use the explicit ByteArray concatenation already named in hshape/hpre, or annotate the full left term as ByteArray before `.extract`; alternatively remove that redundant show if the preceding rewrite already has the required form. This is type elaboration, not a demonstrated false read/write lemma.
- **411:8: subst failed on metavariable equality.** The printed context explicitly contains `hc : sorry = Except.ok (data, st1)` because copyReply's record syntax failed. This is presently a recovery cascade. Fix primary syntax/type issues, then reassess whether prod_ok/subst needs any independent change. Do not treat the current metavariable equality as a semantic counterexample.

These are bounded repair suggestions only: none was applied or tested by this reviewer. The failed Reply log prints sorryAx in reply_success and root_word_typed; those outputs are not accepted proof/axiom evidence. Exact first failure and hashes were sent immediately to root; no mission queue or sourcewriter was started. Further Reply errors may appear after the primary repairs; none beyond the retained output are claimed observed.

## Public composition and unchanged boundaries

ClEntry64cab54b and public678dcbb1 are byte-identical to the complete sources read in the second-snapshot diagnostic. That source reading remains applicable: beforeRoot derives the actual initial frame and checked slot/timestamp/index inputs; rootCall stores ABI length/timestamp into actual machine memory, reads the STATICCALL payload back from it, consumes the accepted typed external call on the supplied Live.World, and installs actual returndata; afterRoot copies and decodes those bytes, computes the GI from cfg/slot/index, allocates/stores the leaf, executes the pubkey/field/merkle pipeline and consumes the same root/GI/leaf/proof cursor in verify.

The written run_success supplies rootCall_success's internal Stored/free128/size96/extent3/timestamp-width hypotheses from beforeRoot_success, and supplies afterRoot_success's free192/zero96/width frame from rootCall_success. Public branch/tree declarations assume whole-entry success and the explicitly inherited ShaWidth condition; they add no public root/index equality, initial-memory frame, reply-size or supplied-stage-success premise. ShaWidth is a genuine universal opaque-SHA output-width condition, not proved by this entry. The typed external interpreter/configuration, EIP-4788 authenticity, complete ABI-list equality, outer gas and compiler/runtime equivalence boundaries remain as documented. No new full rollback theorem is inferred from this success consumer.

This source connection is not a substitute for compilation. Reply failure prevents any normal validation of ClEntry/public here; completing those elaborations may reveal additional errors. The full pinned Solidity/IR correspondence, regression candidate and global trust environment are outside this bounded diagnostic. No whole-candidate proof credit follows merely from GIndex/Frame now passing.

## Exact identities and outputs

- SszSoladyFls: `73011ee40979829b244cd2346e23f9a24b88b7006f22938a5694bcd079a46647` (7033 bytes). Unchanged.
- SszCompiledGIndex: `9b58af30b481d66f11a5879429d317a161226a4a77d6d99b33b7238d97bc5347` (11121 bytes). Changed.
- SszCompiledFrame: `0984e6f07a71d9441fb994cde86ef33c4f5d8bd8a4ac848c78569f70c0be9311` (49771 bytes). Changed.
- SszCompiledReply: `842a09b260fca1f34875c45bd98d35537576da6680ef3c43a11d0a007949fcea` (24142 bytes). Unchanged.
- SszCompiledClEntry: `64cab54b3f70a0c7f4e0daedc12b6b644c4fbc30b854daac0b70075d593f523c` (39575 bytes). Unchanged.
- PSsz1CompiledClEntry: `678dcbb1033904f47bab8b115b958300b003a1d2df89f713838ec9e86b4cce1b` (7763 bytes). Unchanged.

Passing normal oleans:

- GIndex: `6c3383f54cb6ee62a3178f0310208300084f54bd0e0b3f0f141582b6d5c02fa0`.
- Frame: `3fa478662835ada074d506e8a10b8e36b6eddf0e157fd55e898502de72670474`.

Retained local evidence: `/tmp/lido-ssz-fd2279-972-state.json`, `-972-remote.json`, `-972-identities.json`, `-972-passing-artifacts.json`, and separate `-972-SszCompiledGIndex.log`, `-972-SszCompiledFrame.log`, `-972-SszCompiledReply.log` (all with prefix `/tmp/lido-ssz-fd2279`). Tracked mirror diff remains empty; only authorized SSZ snapshots and normal isolated build outputs were affected. No compiler process remains active. **Bounded diagnostic complete; STOP.**
