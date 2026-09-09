# Independent exact-commit review: TOPUP post-return timing

Verdict: CLEAN for the scoped increment at `b8e7d06658e24bfc19b1bd7c766be10e7a13313b`, relative to `26bbe6ea`. This does not close TOPUP-2, the aggregate per-block cap, or the full call-history obligation.

Reviewer: site_audit, independent of the author. Read-only inspection; only this requested review report was written. No build, commit, push, merge or deployment by the reviewer.

## Sources and correspondence

Read the complete TopupCallHistory.lean, TopupCallHistoryMutants.lean and all four audit/topup-call-history files. Previously independently reviewed the complete inherited TopupWeiBounds arithmetic dependency. Compared the actual pinned TopUpGateway Solidity setter, initialization call, guard, post-router update, timing fields and root-age code. Solidity pin is `17005714f151e5502c559932319a3f2f74ac2436`.

TimingState matches uint32 last block/timestamp and uint16 delay. setDistance reproduces the successful/error partition of the real nonzero/range checks. Configured derives positivity through successful setter transitions and timing updates; it does not assume positivity in a constructor as the desired result. Arbitrary valid later delay changes remain allowed. Configured is explicitly limited configuration reachability, not full protocol reachability.

finish correctly models the two truncating writes after the external router call returns and uses positive total LIMITS, not positive actual allocations. distancePassed correctly distinguishes the zero-sentinel short circuit, checked-subtraction panic and ordinary false distance result.

same_block_rejects_after_return and same_block_rejects_after_setter have the explicit, necessary domain `0 < blockNumber < 2^32`, positive limits and configured/valid-setter conditions. The later setter theorem derives positive delay and preservation of the last-block field rather than assuming configuration is frozen. No noReentry assumption is smuggled into either result.

zero_limits_zero_allocations uses gateway_wei_bounds and allocations_sum_le to derive a zero mathematical allocation sum from an observed zero unchecked sum of limits. Its cardinality, successful evaluation and per-key guard hypotheses are explicit, source-related premises. It does not assume the no-wrap conclusion. The mathematical result remains distinct from actual external effects or transferred value.

## Tests and limits

The decide witnesses exercise zero/out-of-range setters, old-state admission before finish, post-return rejection, uint32 block and timestamp truncation, the zero-block sentinel, positive limits with zero allocations, and checked subtraction. The repeated guard evaluation is explicitly only an arithmetic witness, not a demonstrated authorized reentrant execution. No test is presented as an EVM/Lean differential comparison.

The README preserves the material remaining obligations: pre-update external interval, authorized nested entries and role lifecycle, real callback effects and failure rollback, root admission, chain-context bounds and full protocol history. It explicitly refuses to treat a new noReentry premise as closure. The block horizon is an operational condition, not a proven chain-reachability fact. The cost estimate is labeled provisional and low-confidence; it is not proof evidence.

No blocking mathematical or source-transcription finding for this scoped increment. The results establish behavior of the modeled timing operations after a return; they do not prove that every real topUp call reaches finish with the modeled state or that every history respects the total per-block cap.

## Exact candidate and validation evidence

The six changed files are exactly:
- LidoSRv3/Audit/Source/TopupCallHistory.lean
- LidoSRv3/Tests/TopupCallHistoryMutants.lean
- audit/topup-call-history/README.md
- audit/topup-call-history/source-check.json
- audit/topup-call-history/validated-inputs.sha256
- audit/topup-call-history/validation.log

All six exact-commit blobs match the files examined in the source review. All six hashes in validated-inputs.sha256 match current files: timing source, tests, TopupWeiBounds dependency, manifest, toolchain and pinned gateway source. TopupWeiBounds, lakefile, manifest, toolchain and Solidity submodule pin have no difference from the candidate base.

The source-check receipt was independently checked: the gateway file equals its immutable pinned git object byte-for-byte. This confirms source identity; semantic correspondence comes from the scoped manual review above, not textual hashing alone.

The retained validation.log reports a successful targeted 496-job build and only propext/Quot.sound for configured_positive, same_block_rejects_after_setter and zero_limits_zero_allocations. The new source/test modules contain ordinary proved declarations and decide witnesses, with no native_decide, bv_decide or explicit proof escape. The reviewer inspected and reused this source-matched log; no additional build was needed for the unchanged reviewed sources/dependencies.

Source SHA256: `5e3ce8abcafb33e56e3ebb01fe71bd16a41d9c845d38968401ac64907b8b798d`.
Tests SHA256: `61d6330e768ceded97e714a7891d46da4fc737a837bf0e5f2704390ac1334a4b`.

CLEAN is limited to this post-return timing/arithmetic increment. It is not full-guarantee acceptance or permission to merge/deploy website PR #426.
