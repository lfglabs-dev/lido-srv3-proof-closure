# Independent review: TOPUP wei arithmetic slice

Verdict: CLEAN for the scoped arithmetic increment at exact commit `ca5f64a92bb00cecfa344f8797743ed4e5b4f43e`, relative to `4a71f8ed12f484b2792fa082345ba05d1b3f10d4`. This is not acceptance of the full TOPUP-2 guarantee, live execution correspondence, or a sequential-call invariant.

Reviewer: independent site_audit agent; no authorship of the TOPUP proof, tests or receipts. Review was read-only except this report. Concurrent untracked SSZ files were not included. No Lean or Foundry build was launched by this reviewer.

## Source and specification review

Read the complete new source and test modules, all files in audit/topup-wei, lakefile.lean, lean-toolchain, foundry.toml, the relevant pinned Solidity bodies and declarations, and the inherited Solidity harness. The Solidity submodule is clean at `17005714f151e5502c559932319a3f2f74ac2436`.

- GatewayConfig uses the actual uint64 storage fields: maxValidatorsPerTopUp, targetBalanceGwei and minTopUpGwei. ValidatorInput matches uint64 effectiveBalance/exitEpoch, bool slashed and uint256 pending balance. These types constrain inputs, not the desired computed no-wrap conclusion.
- evaluate follows TopUpGateway.sol:403-414: exit/slashed early return, then checked effective+pending addition, target comparison, subtraction, minimum comparison. In particular, an unchecked caller does not turn the helper addition into unchecked arithmetic. The source-executing harness exercises this distinction.
- The count premise is the explicit source guard at lines 174-175. From count and target below 2^64, the product count*target*10^9 is below 2^256. The proof derives conversion and accumulation exactness without assuming the desired sum bound. Natural subtraction follows the prior target comparison.
- The independent postconditions are useful: roundtrip of each limit, exact gateway sum, and exact sum of arbitrary returned allocations bounded by the actual router block cap. They do not substitute a greedy allocator and do not identify the gateway sum of limits with deposited value.
- Router per-key success conditions match the alignment and corresponding-limit checks. A shorter allocation list is permitted by this arithmetic loop; an overlong list cannot pass all guards. The mathematical admission predicate intentionally collapses error identities and does not establish which revert wins when alignment failure and an eventual out-of-bounds access compete.
- routerBudget correctly takes the minimum of the arbitrary module allocation and uint64 cap in wei, then removes gwei dust. router_success derives the true allocation sum before relying on the source final comparison. The cap check is therefore not a circular no-wrap premise.
- The theorem covers successful arithmetic admission. No claim is established about direct calls with arbitrary unbounded gateway limits, live storage extraction, ABI pairing, module share calculation, SSZ/auth/freshness checks, external execution, rollback, or accumulation across calls. The README preserves these obligations.

## Tests and trust

The Lean regression witnesses distinguish early filtering from checked overflow, pending-balance omission, wrong units, per-key/alignment/aggregate guards, extremal uint64 products, short/long allocation lists and rounding. The unrestricted-word wrapping example demonstrates why the count/domain argument matters. These witnesses exercise the arithmetic slice, not a Solidity differential bridge.

The Solidity harness imports and inherits the pinned TopUpGateway and invokes its unchanged internal evaluator. It seeds typed storage directly, explicitly excluding initialization and authorization. Its independent expected result uses successive subtraction rather than copying the helper's checked sum. The checks compare values, exact Panic(0x11) on overflow, filtering precedence and conversion. The dedicated active and successful-gap fuzz distributions avoid the general random exitEpoch test being the only distribution. Router execution is not tested and no Lean FFI comparison is claimed.

The retained Lean log reports a successful targeted 495-job build and [propext, Quot.sound] for gateway_wei_bounds and router_success. There is no native_decide, bv_decide, explicit axiom, sorry or other proof escape in these new proof/test modules. The retained Foundry log reports five passing tests, including three fuzz tests at 1024 runs each, compiled with solc 0.8.25. Those results were inspected and reused, not rerun by this reviewer.

## Receipt checks performed by the reviewer

- All six validation.json file hashes match the files and their exact ca5f64a9 git objects, including both validation logs.
- Test, lean-toolchain and lake-manifest hashes match validated-inputs.sha256 and validation.json; root dependency/configuration files are unchanged from the base.
- The exact source used for the Lean build is recoverable from the current source by replacing `723-734` with `726-732` and `cap check at 737` with `cap check at 741`. Both replacements occur in the opening source-reference comment. Its SHA256 is the recorded `9bbe96984f450105623082f1f28b3f4322c73904268c6b42f94896ecbc2b9d07`. The final source SHA256 is `254edfae1e8948850b65d682cc03d94fa0fdc05323b463767c6d79b9d2746372`; no executable declaration/proof differs from the tested source.
- Re-ran the read-only check_source.py: all four files equal the immutable source git objects and all 24 anchors are present. This checks identity and anchors, not semantic equivalence by itself.
- OpenZeppelin 5.2.0 matches the pinned package.json alias. The local tarball matches both recorded SHA256 and SHA512 integrity; all 353 extracted regular files match tarball contents. The Foundry remapping therefore uses the recorded dependency source. The harness imports real pinned Solidity, not a replacement evaluator.

## Acceptance boundary

No blocking source/proof/receipt finding for this arithmetic increment. Integration should preserve its scoped wording and immutable evidence. Error-code/guard-priority correspondence for the router, the existing PTopup2 parent bridge, physical inputs and sequential history remain separate work; CLEAN here does not close them or authorize website publication.
