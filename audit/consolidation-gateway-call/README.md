# Actual gateway-to-vault CALL consumer

Public consumer: `PConsolidation1.actual_gateway_vault_requests` supports the request-integrity promise by connecting the actual high-level CALL to the vault body that consumes its ABI calldata and transferred value. `actual_gateway_vault_failure_restores` proves rollback of that CALL frame. P-CONSOLIDATION-1 and P-CONSOLIDATION-ETH-1 remain OPEN.

## Source correspondence

At core17005714, ConsolidationGateway.sol220 calls the void vault interface. The solc0.8.25 call-site harness confirms selector a75ac640, the code check before CALL, bytes[] offset tables and padded elements, value argument and bubbling of failure returndata. This is a scoped compiler check, not verification of solc.

The byte producer is the existing `preparePairBytes` on grouped raw byte arrays. `GatewayCall.execute` uses those bytes through corrected295 `gatewayVaultArgs`, `invoke` and `vaultExternal`; no independent Nat pubkey identity or supplied successful vault run appears. The vault body derives self and sender from the request and compares sender to a separately configured gateway. This repairs the tautological caller-as-authorized-gateway check in the abandoned f32 candidate.

WithdrawalVault.sol81–85/199–208 and WithdrawalVaultEIP7685.sol58–72/83–101/113–126 determine the body order: checked pre-credit balance subtraction, configured caller, nonempty/aligned arrays, real fee STATICCALL, returndata length, checked multiplication, exact fee, each source then target width check, value CALL, request event and final balance assertion. The model preserves static flags and nested depths; it encodes custom-error arguments and panic bytes. `loop_success_projection` reuses the old successful-loop request and world proofs while the new runtime retains error data and actual static observations. `execute_success_requests` composes that result into the real outer CALL, including its returned world and nested trace.

The failure theorem restores every component of the caller world before transfer, including provisional vault/callee effects. This follows the existing declared live-world CALL rollback rule; it is not a proof of all EVM rollback.

## Verification scope

Four new kernel-checked regressions cover the accepted two-pair ledger, static/CALL ordering, independently configured gateway rejection and exact fee error. Five Forge tests execute the unmodified pinned EIP7685 base with the exact vault modifier/entry copied into a minimal constructor harness: actual two-pair calldata and ETH, authorization, fee error, failed second call rolling back the first, and no-code high-level rejection. The caller uses solc0.8.25 and vault source solc0.8.9. This does not execute the full gateway prefix or the deployed proxy.

The public AllGuarantees/Trust build passes1613 jobs. The full axiom checker recomputes dependencies and re-evaluates native claims: unchanged29 exact axioms. Both new public consumers and their source composition use ordinary Lean axioms; the four new regressions use propext only. Corrected295 changes the native-backed test inventory by120 added or moved records and35 removed or moved records (net85); `native-inventory.json` records the exact delta. These are inherited finite regression checks, not production proof axioms or kernel-proof credit. The inventory update requires review along with the candidate.

## Required composition still open

- Full gateway role/pause/preconditions, locator/credentials, witnesses, quota, checked request count/fee lookup, actual array allocation and refund remain to be joined to this CALL consumer. The byte-array producer itself is consumed; its initialization and memory extents still need the source connection. The public result identifies the arrays actually decoded, without claiming unconditional round-trip equality for arbitrary unbounded arrays.
- Gateway/inbox immutables still need deployment binding. Malformed elements are decoded eagerly rather than Solidity’s lazy accesses; their failure order and traces remain open. The live event representation preserves semantic fields, not deployed LOG topics/data. The inherited low-level code-less branch still omits precompile dispatch. No simplified EIP7251 predeploy or arbitrary-callee frame is promoted to deployed correspondence.

These are internal/source-specific gaps, not new accepted external assumptions. The accepted compiler, declared Verity semantics, crypto, general gas and consensus boundaries remain unchanged. Historical positive-fee assumptions are not premises of the new public consumer. ALLOC-1/2 and RESERVE-1 are unchanged and outside the improvement queue. Final exact-source independent review is required before integration.
