# SSZ typed source-entry root STATICCALL composition

This increment replaces the supplied `RootOracle` in an executable typed
CL-validator entry with the existing physical-world low-level STATICCALL
primitive. The root bytes returned by that call are decoded and consumed by
the subsequent index, validator-leaf and proof verification. The public
consumer is `PSsz1.actual_root_staticcall_validator_branch`.

It adds a result alongside the existing initialized compiled-harness theorem.
It does not connect that compiled harness to this typed entry, establish a
full CL calldata/memory decoder, or alter any existing published guarantee.
AllGuarantees, Trust, registry and site integration belong to the root agent.

## Source correspondence

Core source pin: `17005714f151e5502c559932319a3f2f74ac2436`.
Reviewed `CLValidatorVerifier.sol:44-56,89-108`, `BLS.sol:516-561`,
`GIndex.sol`, `SSZ.verifyProof` and the existing Live/StaticCall/LowLevel semantics.

| Pinned source action | Executed consumer |
| --- | --- |
| `_verifySlot` runs its SHA pair, checked proof-length subtraction and sibling comparison first | `run` matches the existing `sourceSlot` before evaluating any root call. A failure returns an empty root-attempt list. |
| `BEACON_ROOTS.staticcall(abi.encode(childBlockTimestamp))` | `call` directly invokes `audit.trio.consolidation.lowLevelStaticCall`, with the literal 160-bit address, the actual caller, zero transferred value and a 32-byte zero-extended big-endian uint64 payload without selector. |
| Low-level call to an address without code succeeds with empty data | The reused primitive records one accepted empty reply without consulting the external interpreter. RootNotFound is then raised by the source guard. BEACON_ROOTS is not a precompile; this does not expand the primitive's treatment of arbitrary precompile addresses. |
| Static execution can reject or attempt a forbidden state operation | The existing `StaticCall.External` receives the physical Live world and request but no writable returned world. Rejection and forbidden-state-change become failed attempts; no successful-call premise is supplied. |
| `!success || data.length == 0` precedes `abi.decode(data,(bytes32))` | `decode` rejects failure and empty success as RootNotFound, requires at least 32 bytes, and decodes the first word. Trailing bytes are allowed. |
| GIndex construction, validator leaf construction and proof verification follow the root read | `afterRoot` executes the existing `sourceWrapper`, `sourceLeaf` and `sourceVerify` in that order, with the root decoded from this call. `source_entry_projection` checks structural agreement with the earlier typed sourceEntry, but no RootOracle or duplicate call is executed by run. |
| `_verifyValidator` uses that root in its final proof | `run_success` and the public consumer derive an independent `SszProofFold.Branch` whose root is `firstWord (fromBytes data)` for the actual successful static-call bytes. |

The root-attempt trace contains exactly one accepted request on whole-entry
success. It retains failed root attempts and does not record calls when slot
checking failed. It observes this root STATICCALL only; typed SHA operations
are not claimed to be a complete physical call transcript. The world is
unchanged on every outcome within these read-only typed semantics.

The public theorem assumes only whole-run success. Target, payload, successful
external reply, code-bearing root target, the bytes32 guard, slot/index/leaf
successes, and the branch consequence are derived. It assumes neither a supplied
root nor that root's authenticity nor successful intermediate stages.

## Explicit semantic boundary

`StaticCall.External` remains the deployed external-contract interpretation;
this increment does not implement or prove the EIP-4788 history-ring contract,
consensus anchoring, deployed code identity or root freshness. SHA is the
pre-existing typed precompile interpretation. The typed slot/index/leaf/proof
steps remain read-only computations; their execution has not been joined to
the initialized compiled-memory state from PR310. Raw whole-entry ABI decoding,
EVM.X opcode/gas equivalence and exact Lean revert bytes remain outside this
increment. None of these limitations weakens existing claims.

## Exact validation

- Scoped Lean build: `lake build LidoSRv3.Audit.Guarantees.PSsz1RootCall LidoSRv3.Tests.SszRootCallRegression` passed (806 jobs; existing dependency cache reused).
- 13 kernel regressions, using `decide +kernel`, not native-decision axioms: concrete timestamp octets; successful pinned-index entry with 50 proof words and one root attempt; root-only mutation failing the proof; trailing data accepted; slot mismatch before rejected root; slot SHA failure before short-proof guard; rejected and forbidden-write replies retained; empty reply; short reply before invalid leaf; no-code success-empty rejection; index before invalid leaf; root guards before invalid index.
- `validate.py` checks all actual three-target source import closures against inherited base or package git bodies and independently queries theorem axioms through the existing checker. All new reported results use only foundations (`propext`, `Classical.choice`, `Quot.sound`); no new axiom.
- 9 fresh Solidity tests invoke the complete, unmodified pinned `_verifyValidator` through a minimal harness with real SHA and a 50-word proof. The finite external responder enforces the exact timestamp payload and can return success, changed-root, trailing, empty or short bytes, reject, or try a forbidden write. This fixture is not an implementation of the EIP-4788 contract.
- Solidity tests pass under solc 0.8.25, viaIR, optimizer 200, Cancun. All compiler metadata input hashes were checked against source bytes, and all six imported core files matched their pinned git bodies. No reused Solidity-test claim.

Reproduce Lean/source validation from the repository root:

```sh
lake build LidoSRv3.Audit.Guarantees.PSsz1RootCall LidoSRv3.Tests.SszRootCallRegression
python3 audit/ssz-root-call-composition/validate.py
```

Solidity command (the remapping points to the checked pin):

```sh
FOUNDRY_SRC=audit/ssz-root-call-composition/solidity \
FOUNDRY_TEST=audit/ssz-root-call-composition/solidity \
FOUNDRY_OUT=audit/ssz-root-call-composition/forge-out \
FOUNDRY_CACHE_PATH=audit/ssz-root-call-composition/forge-cache \
forge test --remappings contracts/=/tmp/lido-ssz-proof-committed/lido-core/contracts/ --threads 2 -vv
```

`receipt.json` binds the source and evidence files. Its base is the exact
pre-increment source revision, avoiding a self-referential commit hash.
Independent exact-head review and public registry integration are pending.
