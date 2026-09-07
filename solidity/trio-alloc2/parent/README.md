# Pinned parent execution comparison

From this directory install the exact lock with `npm ci`. From repository root:

```
node solidity/trio-alloc2/parent/run.cjs audit/trio/alloc2/receipt-411a7646-5694-42fc-9173-37012c66f717.json
```

The successful Lean receipt must match every current composition source hash.
The runner compiles and links the pinned actual SRLib parent and compares eight
model executions, including exact input/output bytes, revert kind and module-call
order. It also checks selected transaction frame observations. Results are
written to audit/trio/alloc2/parent-execution.json; command exit zero is required.
See audit/trio/alloc2/checkpoint-parent.md for scope and remaining proof boundaries.
