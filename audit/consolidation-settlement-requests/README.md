# Settlement consumes actual decoded consolidation requests

Base: `f8ea5f9d3cffc165f5d84dd96444836c806827eb`.
Pinned Lido core: `17005714f151e5502c559932319a3f2f74ac2436`.
Public consumer: `LidoSRv3.Audit.Guarantees.PConsolidationEth1.actual_settlement_requests`.

## Useful joint proposition

Success of the existing shared-callee `GatewaySettlement.execute` now implies both the full previous `GatewaySettlement.Success` and an actual decoded-request/refund composition. The theorem supplies no successful stage, fee equality, array round-trip, frame, count or arithmetic premise. No executor is introduced or changed.

The new `SettlementRequests.Effects` exposes:

- actual outer fee reply bytes and quote on the incoming world; the counted grouped sources are exactly the raw source-array count; the checked total and refund split retain their mathematical values;
- the exact produced raw byte arrays and their actual decoder result, a nonempty equal-length decoded source/target list, and authorization `ctx.self = gateway` derived from vault success;
- the separate inner fee reply bytes read on `transfer before gateway vault total`, their exact 32-byte length, and `decodedSources.length * innerFee = total`;
- success of the actual decoded inbox loop, 48-byte source/target widths, exact per-pair requests and fees, and its actual returned world and attempt list;
- the actual outer vault attempt with its concrete calldata, accepted empty return and nested inner-read/inbox attempts;
- the actual refund on that same loop-returned world, including request arguments and the zero-refund skip;
- the root final world, full quote/vault/refund attempt trace, and final gateway balance assertion.

The previous full settlement certificate remains part of the conclusion. This strengthens the retained fee/vault/refund result and the retained gateway-to-vault request result by composing their actual executions. It does not replace their claims or assert a new entry prefix.

## Source correspondence and proof route

At `contracts/0.8.25/consolidation/ConsolidationGateway.sol:189-199`, the pure group count checks empty groups and checked addition. Lines 209-222 quote the fee, check multiplication/value/refund, produce arrays, call the vault, then refund. Lines 285-307 implement the guarded refund arithmetic/call; lines 118-122 enforce the final balance assertion. The existing executor replays those pure checks around the covered suffix; it does not execute intervening omitted stateful admission.

At `contracts/0.8.9/WithdrawalVault.sol`, the wrapper authorizes the configured consolidation gateway and preserves the vault's ETH balance. `WithdrawalVaultEIP7685.sol:55-73,83-101,113-125` checks decoded lengths, rereads the fee, checks the exact fee, validates each source and target width, and sends `source ++ target` with that fee to the actual inbox before emitting its event.

The new proof extracts the vault success receipt from the same `GatewaySettlement.Success.effects`. `GatewayCall.execute_success` supplies its actual decoded arrays, authorization and executed vault-body world/trace. That body's `effects` supplies the inner read and actual richer-loop success. `loop_success_projection` transfers the *same* loop to `addConsolidationRequestsLoop`, including success, world and complete trace; `loop_success` supplies widths and the consumed request list. The derived world equality is then substituted into the already proved refund, final-world, final-trace and final-balance facts. The proof therefore does not attach an unrelated payload or auxiliary ledger to settlement.

## Important distinctions retained

Outer quote and inner fee reread are on different worlds. An arbitrary static interpreter can return different fees. The theorem does not assume their equality or replace either fee read. Likewise, it relates the produced raw source-array count to the outer total, and the actually decoded count to the inner total; it does not assert a universal raw-array/decoded-array identity or canonical round-trip for unbounded malformed inputs.

The starting world is already payable-credited. Role/pause/DSM/locator/witness/quota admission, complete source-array allocation provenance and the full entry are outside this covered suffix. Eager versus lazy malformed ABI behavior, LOG ABI, general compiler/Verity/gas/precompile/deployment/crypto/consensus boundaries keep their retained scope. Actual typed/model success is not unconditional Solidity behavior on every arbitrary byte array.

One shared `External` handles inbox and refund calls, including aliases and callback effects. The inbox interpreter's physical state transitions are exposed but not constrained to implement consensus or a recipient-credit invariant. No net inbox/refund-recipient credit is claimed, no callee frame or initialization law is supplied. Root rollback is the existing declared whole-world rule; retained diagnostic attempts are not on-chain emitted logs.

## Checks and reuse

`lake build LidoSRv3.Tests.ConsolidationSettlementRequestsRegression` passed 1266 jobs with existing caches. Seven named kernel regressions include two actual public theorem instantiations:

- the two-inbox-call success whose callback observes their storage/value effects before writing its own state;
- exact actual byte-array decoding;
- exact source/target payloads, fees, inbox slot300/777 increment to 2, inbox balance 4, then successful refund and callback slot400/888 = 42;
- zero refund still succeeds with a rejecting recipient;
- outer fee 2 on the incoming world versus inner fee 3 on the credited world;
- that changed inner fee rejects with the expected fee error and whole-world rollback;
- late refund rejection restores the prior inbox effects.

The positive regression transports no model-only staged receipt: it instantiates the new consumer directly from the retained full successful executor theorem. The concrete loop/refund regression evaluates the actual functions in the kernel. No native-decision or FFI axiom is added.

`validate.py` independently recomputes current import-closure source identities, all 11 package pins, and the new public/source/test kernel dependency closures. Every inherited local source matches the base Git body. `check_inherited.py` verifies 41 retained artifact/fixture hashes from the earlier settlement and corrected gateway-call packets, including compiler inputs/outputs and the unchanged full WithdrawalVaultEIP7685 source, plus all three pinned Solidity bodies. Their 9 + 5 Solidity tests are identity-reused historical checks, not a new run or full compiled composition proof. All existing executable definitions and compiler inputs are unchanged.

Reproduce:

```sh
lake build LidoSRv3.Tests.ConsolidationSettlementRequestsRegression
python3 audit/consolidation-settlement-requests/validate.py
python3 audit/consolidation-settlement-requests/check_inherited.py
```

Independent exact source/Solidity review and root All/Trust integration are pending. This dossier is a candidate record, not a delivery verdict.
