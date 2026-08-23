# Campaign node 1 — router produces ExecutesAllocation

One node, one PR. Same guarantee ID `P-ALLOC-EXEC-1`. Keep
`A-DEPOSIT-32-ETHER` named. Keep two-batch (not an n-frame lift).
Alloc-exec multiply-only stays a lemma.

## What the parent says

`PAllocExec1.router_produces_executes_allocation`

∀ cfg, inp, template, first, second, with `RouterWordBounds` and
`first.amount + second.amount = actualDepositsCount`:

the construction `routerDepositInputs` (keys := allocation amount,
wei := amount * cfg.depositSize) yields `ExecutesAllocation` and
`LinksSource`. LinksSource is a theorem of the router, not a caller hyp.

## Kill-line

`raw_count_router_kill_line_refutes_parent`: mutant router sets
`amount = keys` (raw count as wei). On the canonical 2+3 / 32 witness,
`ExecutesAllocation` fails.

## Non-goals

- Do not invent a 32-ether pin.
- Do not re-document ALLOC ↛ LinksSource.
- Do not lift to n-frame.

## Build

    lake build LidoSRv3.Audit.Guarantees.PAllocExec1
    lake build LidoSRv3.Tests.PackN1AllocExecMutants
