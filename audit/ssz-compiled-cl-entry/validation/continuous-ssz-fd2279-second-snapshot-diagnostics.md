# Bounded SSZ fd2279 second snapshot diagnostics

**Diagnostic outcome: Frame still fails; downstream chain is not validated. This is not SOURCE CLEAN, a release review, integration approval or merged proof credit.**

Read the complete previous diagnostic and `/tmp/lido-ssz-fd2279-extra-check.log` first. Retrieved only the six designated files through the existing native helper `/tmp/lido-native-offline-call.py`, using read-only `workspace_bash` against workspace `a582a491-be96-4ede-8d14-1fb7897f7622`, checkout `/workspaces/mission-fd22792c/temp/proof-main`. No remote build, source write, mission message, new queue or new resource was requested. Authentication used the existing Bitwarden helper without secret output.

Remote HEAD before and after snapshot acquisition was `1235a304e34ab8a04b28f0f8a04088fb73e6c58f`; its parent is `2c2c72a91cd68a43de0777912772d12cc48a285d`. A second read-only query independently confirmed that all six captured bytes equal those exact committed Git objects. The remote status at capture had only untracked `SszCompiledClEntrySlice.lean`; that file was not fetched, read, compiled or credited. No live uncommitted output is mistaken for this committed snapshot.

The isolated Mac mirror `/tmp/lido-ssz-fd2279-check` remains on its existing tracked base. Only the three authorized local snapshot files Frame/Reply/ClEntry were replaced with exact remote copies, and the new public snapshot was added. Fls/GIndex were verified unchanged and not rewritten. Old copies were retained outside the checkout under `/tmp/*-fd2279-first.lean`. No source fix was authored.

## Exact normal check and repeated blockers

Executed exactly one changed-module normal command:

`lake build LidoSRv3.Audit.Source.SszCompiledFrame`

It failed with exit 1 after 8.27 seconds; active Frame compilation took 6.9 seconds (target 1140/1140). Full stdout/stderr is `/tmp/lido-ssz-fd2279-second-check.log`. Reply was scheduled only after successful Frame compilation and therefore was not invoked. There was no retry of unchanged failing bytes and no rerun of the unchanged GIndex or Fls.

The changed Frame hash is d48c14ac, but its actual edits relative to c88ec9bd concern only explicit tactic arguments near lines 115/123. Neither earlier blocker was fixed:

1. **Frame 322:60, `pairStore_effects`, `wl251`.** `omega` sees `(load st leftAt).2.activeWords.toNat` bounded below 2^64 and `loadedLeft.activeWords.toNat` as a separate unbounded atom. The latter is only a local let alias. Normalize before arithmetic: for example `change (load st leftAt).2.activeWords.toNat < 2 ^ 251; omega`, or `dsimp [loadedLeft]; omega`. This is a definitional-normalization suggestion, not evidence that the statement needs another width assumption.
2. **Frame 384:72, `allocate_read_before`, final size argument of `store_read_after`.** `omega` treats `readState.memory.size` independently from `st.memory.size` even though `readState := (load st 64).2` and load preserves memory. Supply the already known size fact by conversion, e.g. replace that size proof with `by change offset + 32 ≤ st.memory.size; exact hsize`, or bind an explicitly typed `offset + 32 ≤ readState.memory.size` using hsize before the application.

Both suggestions remain unpatched and untested here. Error recovery prints sorryAx in downstream Frame closures; those lines are failed-elaboration output, not valid axiom receipts. Diagnostic **83c4dfca**, already queued for the prior c88 snapshot, remains applicable to these same two proof sites despite the changed file hash and +1 line shift. I sent no new remote mission hint or queue; root/Hermes coordinate it.

Unchanged Fls 73011ee4 retains its earlier PASS diagnosis only. Unchanged GIndex 4bb2cb74 retains the known failure at 177/178 (leading PUnit pure bind confused with checkedAdd) and 230 (word/2^256 normalization). It was expressly not recompiled. Frame must pass before discovering actual Reply errors, and both Frame/Reply plus GIndex must pass before meaningful ClEntry/public elaboration. No new downstream error locations are claimed observed.

## What the new ClEntry text actually connects

Read the complete latest ClEntry and both public declarations, and compared the changed Frame/Reply text. Unlike the prior d609 ClEntry, the new file contains a written `rootCall_success` proof without the old explicit sorry, a complete written `afterRoot_success` proof and a written `run_success` consumer. The public file now exposes `actual_compiled_cl_entry_branch` and `actual_compiled_cl_entry_tree`. Absence of textual admissions is not proof acceptance: none of those dependent files was elaborated in this diagnostic.

The executable sequence is substantive. `beforeRoot` runs the prologue/dispatcher, reads the proof tail, slot/proposer and validator index from the same calldata, executes the slot pair SHA and checked sibling comparison, then validates the timestamp word. `rootCall` loads the actual machine free pointer, stores timestamp and length, checks allocation, stores the new free pointer and loads length again. Its STATICCALL payload is a `readWithPadding` of that resulting memory, not a separately invented timestamp payload. The accepted typed low-level STATICCALL operates on the same supplied Live.World. Its actual bytes and success flag are installed in the machine's returnData and carried to afterRoot. Its own attempts are used by run.

`rootCall_success` is written to derive the timestamp-payload identification from these concrete stored cells and memory reads. It also derives free pointer192, zero slot96, active-word bound, unchanged execution environment, and conditional actual call success/returnData identity. These are internal frame hypotheses at this phase: Stored free128, memory size96, activeWords3 and timestamp width. The written `run_success` obtains all of them from `beforeRoot_success`, rather than exposing them as public hypotheses.

`afterRoot` first copies the actual returndata to a caller allocation, then decodes a root word through actual memory loads and failure/length guards. It reads slot again and executes `SszCompiledGIndex.wrapper (cfgWords cfg)` with the same validator index, allocates the leaf, decodes the key slice, executes pubkeyRun, stores the actual key digest and decoded fields, executes merkle, obtains the proof tail again, and calls verify with the same decoded root, actual packed rawIndex, computed leaf and calldata cursor/length. There is no visible unused root/GI adapter replacing those consumed operands.

The written afterRoot proof consumes `reply_success` to connect the loaded root to the first actual returndata word and to establish the dynamic free-pointer/memory bounds. It consumes wrapper_success to connect the raw packed GI to `sourceWrapper`; it then feeds the actual allocation/stores through fields_effects and merkle_effects, and connects the final leaf to the independent typed validator tree using pubkey digest, decoded fields and credentials at calldata word164. The verified branch statement names the proofWords consumed by the loop, explicitly not the complete ABI-declared list.

The written whole-run proof inverts actual beforeRoot/rootCall/afterRoot results; derives success and length from the reply phase; identifies root request, code check, external success and the one attempt from the actual call; identifies the second slot/proof-tail reads with the originals using execution-environment preservation; and supplies that data to the public branch conclusion. The second public theorem transports the branch into the typed digest/tree vocabulary rather than running a different verifier.

The public assumptions are whole-entry success **and inherited `SszProofCommitted.ShaWidth`**. This is not an assumption-free theorem: ShaWidth universally states a 32-byte opaque SHA output for every pair input. It is explicitly inherited and disclosed, rather than derived from this entry. There is no additional public stage-success, root/index equality, initial memory layout or reply-size premise in the new text. Configuration remains typed constructor pack words; external remains the accepted typed interpreter. Gas, compiled-bytecode correspondence, deployment/configuration authenticity and EIP-4788 history-ring authenticity remain outside. The current whole-entry failure result carries an error and attempts, not a newly proved full machine/world rollback theorem. None of these source readings upgrades the unelaborated proof text to a proved composition.

## Exact snapshot identities and retained outputs

- SszSoladyFls: `73011ee40979829b244cd2346e23f9a24b88b7006f22938a5694bcd079a46647`, 7033 bytes.
- SszCompiledGIndex: `4bb2cb740fc1e36028583621d85e1f6c5eb72fc987c7a66a858536845af3a118`, 11008 bytes.
- SszCompiledFrame: `d48c14ace98fcbd57a20df6b51488362a04e92911a020636bc7a75fb89825baa`, 49536 bytes.
- SszCompiledReply: `842a09b260fca1f34875c45bd98d35537576da6680ef3c43a11d0a007949fcea`, 24142 bytes.
- SszCompiledClEntry: `64cab54b3f70a0c7f4e0daedc12b6b644c4fbc30b854daac0b70075d593f523c`, 39575 bytes.
- PSsz1CompiledClEntry: `678dcbb1033904f47bab8b115b958300b003a1d2df89f713838ec9e86b4cce1b`, 7763 bytes.

Transport result: `/tmp/lido-ssz-fd2279-second-remote.json`. Compact snapshot manifest: `/tmp/lido-ssz-fd2279-second-identities.json`. Exact committed-object comparison: `/tmp/lido-ssz-fd2279-second-commit.json`. Normal compiler output: `/tmp/lido-ssz-fd2279-second-check.log`.

Final copied hashes were rechecked against the captured manifest. Tracked mirror diff remains empty; the six SSZ files are isolated snapshot additions. No Fls/GIndex rebuild, Reply compile, ClEntry/public compile, full build, Solidity/FFI validation, axiom-clean claim or release verdict was performed. No further local process remains active. **Bounded diagnostic complete; reviewer STOP.**
