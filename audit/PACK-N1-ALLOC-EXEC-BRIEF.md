# Pack N1-ALLOC-EXEC brief — allocation counts to executed wei

One composition parent. The parent is universal over source deposit
configurations, executable two-batch inputs, and two `Spec.Allocation`
records. It does not pin `depositSize` to a deployment constant.

## Frozen interfaces used

`Spec.Allocation.amount` is a validator count.
`SourceDepositConfig.depositSize` is linked explicitly to
`DepositParentTx.Inputs.depositSize`. The execution amount materializer uses
the latter field and the two executable batch key counts.

## Parent

`PAllocExec1.allocated_amount_times_deposit_size` states that when each Spec
amount equals the corresponding batch key count, honest amount execution
produces:

```
first executed wei  = first Spec amount  * cfg.depositSize
second executed wei = second Spec amount * cfg.depositSize
```

The two no-wrap premises preserve those equalities as mathematical `Nat`
wei while the execution fields remain `Uint256`.

## Kill-line

`PackN1AllocExecMutants.raw_validator_count_kill_line_refutes_parent`
negates the exact universal parent shape for a mutant that writes raw
validator counts into wei fields. Every parent premise is retained. The
two-key input begins with a stale amount of 65; honest execution recomputes
64 at `depositSize = 32`, while the mutant writes 2.

## Scope

This pack does not choose a fixed 32-ether deployment value, register
metadata, or change existing deposit and top-up parents. Registry and trust
integration are left to the integrator.
