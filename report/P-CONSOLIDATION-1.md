# P-CONSOLIDATION-1

The candidate registers `PConsolidation1.gateway_vault_live_success_and_revert` as its executable parent. It consumes `PhysicalEntrySettlement.execute` over an arbitrary credited entry world, context, grouped request bytes, transaction value, and shared external/static-call interpreters. Targeted validation passed at `d51c1865957c7655c47fa8a8c4e46f4d7af814b1` on registered `dgx-spark`, job `b7161153-afbd-4f57-88a9-268210490017` (1296 build jobs), including the actual ABI, settlement-request and physical-entry regressions.

The parent cases on that execution's actual outcome. Success derives `GatewayVaultEffects`; failure restores the original credited world. The successful certificate retains the complete existing physical-entry, quota, settlement and decoded-request conjunction:

- Role membership and resume time come from physical contract-indexed storage. The checked count comes from the supplied source-key groups. Quota arithmetic and packed writes produce the actual post-quota world.
- The gateway getter performs its nested inbox STATICCALL on that world. Successful exactly-32-byte return data determines the outer fee; checked multiplication determines the forwarded total and subtraction determines the refund.
- The grouped-byte producer constructs the gateway-to-vault ABI payload. The actual CALL debits the gateway and credits the vault; the vault decodes that payload and obtains its caller and value from the CALL request.
- The vault performs its own fee STATICCALL on the value-credited world. This read is not assumed equal to the earlier quote. The vault's checked exact-fee test and decoded arrays determine its per-request value-bearing inbox CALLs and source-ordered effects.
- Refund execution consumes the actual vault-loop result world. The certificate retains nested attempts, callback-returned worlds, the refund request, and the gateway's final balance assertion. Any later failure rolls back quota writes and earlier vault/callback effects to the original credited entry world.

All frame, fee and intermediate-world equalities are conclusions derived from root execution. There is no supplied desired boundary equality, fee-success boolean, or independent vault/refund success premise. One `External` handles inbox and refund calls, including aliases. A zero quoted fee is not excluded by an invented nonzero-fee premise.

The historical abstract `source_consolidation_preserves_eligibility_value_atomicity_from_gateway` remains a conditional source-plane theorem, with supplied boundary, positive-count and nonzero-fee premises. Its source if-tree characterization is retained, but those premises do not prove the new executable claim. The existing slot-free projection and its tests also remain; no equality between that projection and the complete live-world executor is asserted. Fabricated source/target storage slots were not reintroduced.

Source basis: `lido-core@17005714f151e5502c559932319a3f2f74ac2436`, especially `contracts/0.8.25/consolidation/ConsolidationGateway.sol:185-222`, its fee/refund helpers and modifiers, and the configured WithdrawalVault EIP-7685 fee/request implementation. The existing checked-multiply, exact-fee, then per-key validation order is preserved. The preserved patch based on `962a349bb0258ed7b05ce21aca2d12ca11cae54a` proposed registering the settlement suffix; its composition intent is reused with the stronger current physical-entry derivations.

The value-bearing inbox/refund CALL now excludes Cancun precompiles 1–10
from ordinary empty-code acceptance. The callee interpreter produces their
response; rejection rolls back the provisional credit and retains the failed
request and returndata. Regressions check all ten dispatch addresses, neighbouring
ordinary addresses, and the refund producer’s mapped error and rollback. These
are Lean execution regressions, not paired Solidity/precompile equivalence tests.

Remaining obligations:

- Shared STATICCALL now excludes Cancun precompiles from empty-code acceptance
  and retains the interpreter response, including rejection and static-state-change
  failure. The fee consumer and locator-origin certificates consume that execution.
  Cancun fork binding, actual precompile semantics and paired differential coverage
  remain required; dispatch lemmas do not discharge these obligations.

- The input world is already credited with the outer transaction value. Outer ABI decoding and payable-credit execution are not derived here.
- Gateway lines 201-207 perform the DSM/precondition check, locator lookup and target withdrawal-credential witness validation between counting and quota use. These operations are omitted. The theorem therefore establishes the declared physical-entry/quota/settlement model, not whole-function admission or beacon validator eligibility. The selected vault/inbox and request groups remain inputs at this boundary.
- The pure source-array producer and actual ABI decoder are connected, but source allocation extents and general lazy malformed-calldata ordering are not proved. Canonical source-produced payload execution must not be generalized to arbitrary malformed ABI equivalence.
- Predeploy implementation correctness, LOG ABI encoding, gas and complete deployed-bytecode/interpreter refinement remain outside the scoped executor. External callbacks are executable inputs, not proofs of a particular deployed implementation.
- Historical source-plane bridge and nonzero-fee premises remain limitations of their older abstract statements. They are not used to discharge the actual gateway-vault boundary.

The selected regressions cover actual ABI bytes, call values, two decoded requests and callback writes, distinct outer/inner fee observations, zero-refund skipping, refund rejection restoring earlier effects, and physical entry/quota guards. They complement the universal execution certificate; they are not full deployment closure.

```sh
lake build LidoSRv3.Audit.Guarantees.PConsolidation1ActualGatewayVault \
  LidoSRv3.Tests.ConsolidationTxMutants \
  LidoSRv3.Tests.ConsolidationGatewayCallRegression \
  LidoSRv3.Tests.ConsolidationSettlementRequestsRegression \
  LidoSRv3.Tests.TrioConsolidation.PhysicalEntrySettlement
```

Combined exact-SHA validation and fresh independent audit remain required. No merge or closure certification is requested.
