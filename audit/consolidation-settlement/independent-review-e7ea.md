# Consolidation settlement independent exact-head review

**CLEAN for the declared same-world settlement suffix at `e7ea041c216365acab8114aaac8d6eca109aae84`. No blocking source, proof, or evidence defect found.**

Checkout `/tmp/lido-consol-root` was frozen and clean. Base is `b45cf453834a628439c9899feba760a77d3b984d`; Solidity pin is `17005714f151e5502c559932319a3f2f74ac2436`. This verdict concerns the source increment, not yet root integration or publication. No repository was edited, tests reflexively rerun, or push/merge performed.

## Exact evidence

Reviewed all 23 added files: the 406-line executor, public facade, all 11 kernel regressions, complete scoped Solidity harness/test sources, fee-callsite source/input/output/IR, and the full JSON/log/checker evidence. All 23 working files match git HEAD. No pre-existing file changes are present.

`check.py` passes: all **1249 source identities**, **11 package pins**, retained successful statuses, and all receipt artifact hashes match. Independently compared every source manifest entry to its actual git body (candidate HEAD for local files, recorded package pin for dependencies): no mismatch. The three full pinned Solidity source hashes match the source checkout and pin git bodies. The copied WithdrawalVaultEIP7685.sol is byte-identical to the pin.

Retained evidence records **1263-job targeted Lean build**, **11 kernel regressions**, and **9 successful Solidity fragment tests**. Existing dependency caches were reused, as declared. Public success has `propext, Quot.sound`; public failure has `propext`; the new kernel regressions have `propext`. New proofs introduce no axiom, native decision exception, proof escape, or successful-stage assumption.

Also inspected retained Forge metadata for SettlementHarness, SettlementVaultHarness and SettlementTest. All five compiled source occurrences match their compiler keccak hashes. Compiler settings match the dossier: gateway/test solc0.8.25, optimizer200/Cancun; vault solc0.8.9, optimizer200/London. The retained fee-callsite IR matches compiler JSON output and its input source, and exposes selector `1e515533`, STATICCALL, call-failure bubbling and short-return ABI rejection without an extcodesize precheck. Recomputed selectors for EmptyGroup, FeeReadFailed, FeeInvalidData, InsufficientFee and ZeroArgument; all literals agree.

## Source comparison and execution

Compared the complete new executor with the pinned gateway count, fee getter, checked multiplication, `_checkFee`, pair producer, vault call, refund helper and final modifier. Read the relevant transitive executable bodies: GatewayCall's ABI-framed invoke/dispatcher/vault body/loop, the producer and ABI framing/decoding, LowLevel CALL/STATICCALL, physical Live transfer, refund execution and its request/zero/failure rules. The richer inherited proof projections were also checked where consumed or used to interpret the public certificate.

The modeled entry is an already payable-credited world. Its balance subtraction, nonzero msg.value, nonempty groups, empty-group error, and checked uint256 request accumulation match the scoped source operations. The count is computed from these actual source-key lists. The producer flattens those same lists and repeats each group's target. This does not replace the existing ABI/array-extent boundary with a new admission premise.

The quote executes the configured read-only vault getter on the same world. Its outer request has zero value and the exact getter selector; its inner request is a zero-value empty-payload STATICCALL from the vault to inbox. A code-less vault produces a successful empty outer call followed by caller uint256 decode failure, matching the retained IR and Solidity test. For a code-bearing vault the actual inner reply is checked for call success and exactly 32 bytes; its word is decoded and ABI-encoded for the outer reply. Inner rejection/invalid size becomes the proper bubbled getter error. No writable-world response is discarded.

Checked multiplication derives `requestCount * fee < 2^256` before fee comparison and Word construction. `_checkFee` derives the refund from msg.value; successful execution proves exact natural-number equality `total.val + refund.val = msgValue.val`, so no modular loss is hidden.

The actual GatewayCall executes with that total and those produced raw groups on the same incoming world. Its recipient transfer occurs before the vault body. The vault repeats its fee STATICCALL on the credited world; the first quote is not silently substituted for the second read. Vault authorization, array/count/width checks, exact fee, per-pair source-then-target payload, callback worlds, semantic request logs and final vault balance assertion remain those of the inherited consumer.

Refund executes only after successful vault execution and takes **that vault-returned world**. Zero refund skips the call. Zero recipient resolves to ctx.sender. Nonzero refund uses the low-level empty-payload CALL with the actual amount, retaining accepted/rejected and nested observations. The final gateway balance assertion runs after the refund callback, including arbitrary successful callback effects. Any final error, including that assertion or refund failure after successful vault effects, causes execute to restore the entire input suffix world while retaining attempt observations.

The combined trace is quote outer/static descendants, then vault outer/call descendants, then refund outer/call descendants. Depth increments and static flags agree with the call frames. The kernel regression explicitly witnesses the two fee reads and two inbox calls before the refund.

## Exact public promise

`actual_settlement_success` has a single success hypothesis on `GatewaySettlement.execute callee callee staticExternal ...`. It uses one shared **External for inbox and refund execution**, including those addresses aliasing; repeated fee reads use the one read-only StaticCall.External. The configured outer vault functions are source interpreters, rather than arbitrary external success booleans. No separate quote, vault or refund success, funding, BalanceFrame, LogFrame or Untraced premise is supplied.

The returned `Success` certificate exposes actual counted/quote/check/call equations, exact fee split, refund request shape and zero-refund behavior, same-world continuation, final returned world, concatenated traces and the gateway balance postcondition. Successful component equations are derived by inversion of the actual composed execution. `actual_settlement_failure_restores` restores the input world under the declared root model rollback rule.

This is a useful composition of previously separate results. It does **not** establish aggregate recipient net credit under arbitrary callbacks; its exact split concerns call amounts. It also does not establish a universal deployed address-to-code dispatcher or reconcile arbitrary supplied external interpretations with actual deployed contracts; those remain the accepted source/deployment boundary.

## Publication boundary to retain

- Role/pause/DSM/locator/witness/quota prefix admission and updates are omitted. Pure count is replayed; this is not proof that the full gateway entry reaches the chosen world.
- The balance snapshot is the already-credited suffix entry. Failure restores that snapshot, not an independently modeled pre-payable transaction world or caller debit. Solidity fragment transactions roll back their earlier payable transfer too; that additional effect is not attributed to this Lean theorem.
- Unbounded-array ABI round trip, physical allocation extents, lazy malformed-element error/trace order, arbitrary precompile dispatch, gas, deployment and consensus/EIP7251 processing remain outside this increment.
- Refund faults and inherited request logs retain their declared semantic representations; exact error/LOG ABI is not claimed beyond the modeled source fragments.
- The Solidity harnesses are honestly scoped fragments: the EIP7685 base is exact, but full witness layout and gateway prefix are absent. Their nine tests corroborate the same-world settlement and error behavior without claiming full-gateway/proxy execution.

Existing public claims are untouched. Root may proceed to additive AllGuarantees/Trust/registry integration and request final exact integration-diff confirmation; this review does not pre-approve an unseen integration diff.
