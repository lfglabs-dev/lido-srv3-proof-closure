# Main source-model guarantees

`main-guarantees.json` registers the three main website claims against existing
composed theorems. `generate_ux2.py` resolves every declaration, including its
statement and source span, into `main_result`. The older two-plane registrations
in `audit/guarantees.yaml` remain available for existing report consumers. They
are not the evidence for these new main claims. No existing declaration or proof
status is removed or promoted to a deployment guarantee.

The source-model registration is intentional: ALLOC-1 and ALLOC-2 include named
Verity external-call interpretation results, whereas RESERVE-1 uses a custom
transaction interpreter over Verity physical contract storage. A full Verity EVM
execution theorem for that reserve path is not claimed.

ALLOC-1's successful producer relates live-derived rows to the independent
capacity specification and its actual stored arrays. Success is explicit;
adversarial calls and checked arithmetic can fail. The lifecycle count theorem
is additional evidence for covered histories, not a bound on arbitrary storage.

ALLOC-2's public outcome relation composes the producer, memory/ABI transport,
proportional library model and checked wei conversion. The VM correspondence
projects return/error and module observations. Its library event does not execute
the deployed linked code. The separate +1 algorithm remains outside this result.

RESERVE-1 uses the physical pipeline preservation theorem, the independent
withdrawal correspondence and the specification's rollback theorem. The pipeline
has configuration, queue, arithmetic, funding and recipient premises. Rollback
restores the physical world while preserving attempted-call observations.
Arbitrary successful callbacks are not promised reserve protection.

## Boundary migration

The former per-card omissions remain attached to the historical parents. For the
new main claims: live queue reads, source-ordered module calls and stored array
transport are now covered by the named results. Compiler memory interpretation,
omitted-write frame conditions, configured code identities and primitive bindings
remain conditions. The live queue result does not prove every queue writer or
integrate all report paths. The deployment and gas exclusions remain unchanged.

The main descriptions and conditions share one checkout with the assumption
catalog corrections. Validation must identify this combined commit; historical
receipts cannot be relabeled as a full run on it.
