# Actual root calls consumed by P-TOPUP-2

Candidate is additive over `ea5774a82facf0d474e68058c4645ebf4380d403`.
Source pin: Lido core `17005714f151e5502c559932319a3f2f74ac2436`.

`PTopup2.actual_root_module_batch_bound` derives one joint `TopupBatchRootCalls.Success` relation from success of the new covered-phase executor. The relation includes:

- Ordered `List.Forall₂ Authenticated rows ns`, binding each witness's actual evaluated fields to its `ns` element, timestamp STATICCALL bytes and independent validator container tree under actual interpreted SHA outputs.
- Exact output pubkeys, wei limits and nonwrapping limit sum; those same arrays feed `TopupBatchConsumer.moduleInput` and the unchanged `TopupModuleCall.execute` on the initial World.
- Actual raw module CALL reply and decoded allocations bounded by the uint64 packed router cap converted to wei.
- Root attempts in row order, followed by the unchanged module executor's attempts, and its actual committed World. The two existing attempt types remain separate phase fields rather than being coerced into one trace format.

There is no arbitrary RootOracle in this execution. It executes `SszRootCall.run` for every admitted row; its actual returned root is consumed by the existing slot/index/leaf/proof sequence. No total SHA success, independent leaf, verifier-success, checked-limit, target-bound, module frame or root-storage assumption is a theorem premise. Actual root-call world preservation comes from the existing static semantics. Gateway config is reread from `e.gateway`/`e.before`; the loop-only `Environment.cfg` field is replaced by this read at the batch entry.

## Source mapping

| Pinned Solidity | New composition / reused source |
| --- | --- |
| `TopUpGateway.sol:163–175` length admission | unchanged `TopupGatewayWitnessBatch.checkLengths` using actual rows/keyIndices/operatorIds lengths and `TopupGatewayConfigWords.readConfig` |
| `TopUpGateway.sol:204–220` pubkey, strictly increasing index, activation | new `TopupGatewayRootCalls.rowLimit`, unchanged `ordered` and `activated` checks |
| `TopUpGateway.sol:221`, inherited `CLValidatorVerifier.sol:44–56` | new `verify` executes unchanged `SszRootCall.run` with gateway caller; slot check precedes STATICCALL, then wrapper, validator leaf, fold |
| `CLValidatorVerifier.sol:59–85` | unchanged `SszActualLeafTree.leaf_success_tree` binds actual checked replies to independent validatorTree |
| `CLValidatorVerifier.sol:102–106` timestamp root query | unchanged physical-world `SszRootCall.call`, `decode`, `afterRoot` |
| `TopUpGateway.sol:223–228` copy pubkey, checked headroom, unchecked wei/sum | new loop retains exact copied keys and limits using unchanged `evaluate`, `fields`, `gwei`, word modulus and accumulator definitions |
| `TopUpGateway.sol:232`, `StakingRouter.sol:717–758` covered value continuation | unchanged packed target calculation, actual `TopupModuleCall.execute`, raw return decode, withdrawal and beacon continuation |

The internal inheritance call retains the gateway address as STATICCALL caller; it does not send the query as an independent verifier address. Every row uses the same timestamp and initial World; static execution preserves that World. Failure before root verification has no root attempt. Root/leaf/proof/headroom failure retains the attempts already executed; subsequent rows and module are skipped. Module failure uses the existing rollback wrapper and retains both diagnostic phases. `failure_restores` proves restoration of the complete initial World.

## Scope retained

This is a typed aligned-row, covered batch value path. It does not join the declared Witness ABI/proof-list decoder or compiled SSZ calldata/memory harness. It does not cover the intervening role/pause/timing/locator/credential view calls, the preceding module allocation calculation, final gateway history writes, cryptographic SHA correctness, EIP-4788 storage authenticity, gas or full compiler refinement. Withdrawal credentials remain the same typed argument, not independently authenticated storage. Arbitrary external module/withdrawal effects retain the existing external-interpreter boundary. Earlier public executions and theorems are unchanged.

## Validation

Build: `lake build LidoSRv3.Audit.Guarantees.PTopup2RootCalls LidoSRv3.Tests.TopupBatchRootCallsRegression`.
Identity/trust: `python3 audit/topup-root-call-batch/validate.py` reads actual Lake setup import closures, checks inherited local source bodies against the base, package source bodies against exact manifest revisions and recomputes scoped kernel axiom sets. Only `propext`, `Classical.choice`, and `Quot.sound` are permitted. Eleven kernel regressions execute the new composition, including a partial SHA interpreter, two distinct ordered validators producing exact 32/31 Gwei limits, a module that accepts only the expected produced calldata, gateway-caller rejection, rollback above the cap, duplicate-index prefix attempts, early slot/activation failure, rejected/forbidden roots and pending overflow after verification. A twelfth theorem instantiates the public joint guarantee on the successful full batch.

Existing Solidity fixtures/receipts are reused only for unchanged inputs, with fresh identity checks recorded in `inherited-validation.json`. No new Solidity execution or compiled composition theorem is claimed. Independent full-source and pinned Solidity review remains root-owned; no integration, push or PR is performed by this writer.

Recheck inherited identities with `python3 audit/topup-root-call-batch/check_inherited.py` (`LIDO_CORE_SOURCE` may select the pinned checkout). After successful build/identity/axiom checks, `write_receipt.py` seals their exact hashes. The four new Lean files and this audit directory are the writer’s entire scope; aggregate imports, Trust inventory and release integration are root-owned.
