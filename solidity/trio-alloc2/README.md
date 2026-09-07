# ALLOC-2 pinned Solidity execution

This harness executes the exact pinned MinFirstAllocationStrategy and Math256
sources in an in-process Istanbul EVM, compiled with solc 0.8.9, optimizer 200
(the corresponding configuration in the pinned core hardhat.config.ts). It is
not deployed-bytecode reproduction, gas equivalence, or a Verity execution claim.

From this directory:

```
npm ci --ignore-scripts --no-audit --no-fund
node differential.mjs ../../audit/trio/alloc2/receipt-60f2c38c-dce8-4ee6-8344-f300fec330b9.json
```

The source manifest `audit/trio/alloc2/differential-source-identity.json` must
match both the current Lean files and the successful remote receipt's verified
overlay. Missing/truncated vector output and stale sources fail closed. To update,
run `prepare_slice.py`, submit the isolated remote slice, reconcile its successful
receipt, and copy the new per-file manifest before comparing that receipt.

32 vectors are actually evaluated by Lean and compared against three EVM paths:
internal step, public-library delegatecall plus original caller array, and direct
public-library call. Five arithmetic calls and four malformed ABI calls bring the
total to 105 exact return/revert byte comparisons. All successful public-library
calls also check that the caller's array retains the original values. Panic codes
and raw empty decoder reverts are compared byte-for-byte. Cases include truncated
capacities (including failure after a visited row), surplus capacities, overfull
rows, earliest ties, higher closed rows, zero demand, and maximum-word boundaries.

`audit/trio/alloc2/solidity-execution.json` records input/output bytes, pinned source
hashes, compiler settings, linked bytecode hashes, runner and npm lock hashes, and
the Lean receipt/overlay identity. Ganache's optional µWS native binary is missing
for local Node 18.19.1; its built-in JS fallback completed execution. No RPC server,
public-chain transaction, or existing account credential is used.

Still outstanding: actual Verity execution, byte-memory/ABI correspondence proofs,
parent-shaped mutation tests, arbitrary callee rejection and late parent rollback,
and ALLOC-1 producer composition. These executions supplement, not replace, the
universal correspondence proofs and full production/test/trust gates.
