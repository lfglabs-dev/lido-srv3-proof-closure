# Independent CONSOL settlement requests integration review

**CLEAN** for exact integration `d7347925237b9e843997f244d032bcc7c442fd40` in `/tmp/lido-consol-requests-integrated`. No integration finding identified. This accepts the bounded joint settlement/request consumer and its public/Trust wiring, not the complete delivery guarantee.

I authored neither the new proofs, their consumed substrates nor this integration. Review was read-only; HEAD was exact and the checkout clean before and after inspection. No Lean build, Git mutation or project write was performed for this integration review.

## Exact preservation and identities

I independently compared complete Git trees, including modes and blob identities. Union `814a7a8349b278a413fa60af78c80a3a7eb33951` is exactly accepted main `241c2ce1e78860b8451a843949b71f60b8c2df25` plus the fourteen additions from independently reviewed source `27f2394bd9afb416ffc6ed753d57f04d0f082228`. The source candidate itself preserves every entry of its base `f8ea5f9d3cffc165f5d84dd96444836c806827eb`.

From that union, the final candidate changes only `LidoSRv3/Audit/AllGuarantees.lean` and `LidoSRv3/Audit/Trust.lean`, and adds five files under `audit/consolidation-settlement-requests/integration/`. All fourteen source/dossier additions, all accepted main entries outside those two wiring files, all consumed executors, Lake providers, configuration and dependency pins are preserved exactly.

All thirteen original receipt hashes and all four integration artifact hashes match both final Git blobs and working bytes. The retained independent source review is byte-identical to my external source report. All 1,249 source-input identities were recomputed against the integration workspace, with local bodies also checked against exact Git objects; all match. All eleven dependency package HEADs match the source receipt and exact manifest. The source review's nine scoped axiom sets and inherited evidence remain unchanged. `git diff --check` against accepted main passes.

## Public result and wiring

`AllGuarantees.lean:1` imports the actual public consumer. `Trust.lean:1` imports its regression module and lines 714–718 actively query the public theorem, source theorem, two public consumer instances and concrete decoded-loop/refund effects. Previous imports and queries remain intact. Existing provider coverage for the Guarantee, Tests and `audit.trio.consolidation` namespaces is unchanged and the build resolves all three new files.

The exact source previously reviewed remains the statement being exposed: the same successful `GatewaySettlement.execute` yields both the complete previous `GatewaySettlement.Success` certificate and `SettlementRequests.Effects`. Actual gateway decoding determines the width-valid inbox pairs and request attempts; their returned loop world is the world consumed by the refund. The outer quote occurs before vault value credit, and the inner fee read after that credit. No fee-equality, ABI-roundtrip, stage-success or callee-frame premise has been introduced by integration. The result is a conjunction about one execution, not a substitution of a disconnected helper proof.

## Validation evidence

The archived combined command is `lake build LidoSRv3.Audit.AllGuarantees LidoSRv3.Audit.Trust`, completed successfully with 1,700 jobs. The log explicitly records building SettlementRequests (1.7 s), its public theorem module (1.6 s), AllGuarantees (3.0 s), regression module (3.0 s), and Trust (2.1 s), with unchanged dependency caches reused. There are no error lines; inherited warnings remain. The new five Trust queries emit ordinary foundations only: the first four use `propext`, `Classical.choice`, `Quot.sound`, and the concrete effects regression uses `propext`.

The archived fresh global gate reports exactly 29 disclosed axioms, dependencies recomputed from the built environment and native-decision claims re-evaluated. This includes the existing test/native and production exceptions; it is not a globally foundations-only claim. The checker and policy bodies are preserved from accepted main. Hash and exact-source checks above support reuse of these archived successful runs; no redundant build was needed.

The original seven kernel regressions include the two public consumer instances. My previous source review independently ran normal Lean on all three new files and recomputed the nine scoped axiom sets. The 41 inherited Solidity artifact/fixture identities and three pinned Solidity bodies retain that review's acceptance. Historical 9+5 Solidity tests are identity-based reuse, with no fresh Solidity execution or newly compiled composition refinement claimed here.

## Boundaries retained

This is a typed suffix starting from an already payable-credited gateway world. Full stateful gateway admission, witness/quota/locator behavior, raw allocation provenance, complete decoder/memory and malformed-ABI correspondence, LOG ABI, cryptography, deployed runtime and gas behavior remain outside the result. Arbitrary modeled callee worlds do not yield a universal frame or net recipient-credit theorem. The exact request/refund world connection and final gateway balance assertion are established within those stated limits.

A later archive-only successor can reuse this acceptance after exact delta and artifact identity verification. No later commit, merge or site publication is certified by this report.
