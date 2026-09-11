# ADDRESS: actual wrapped transferFrom → unwrap → request enqueue

Candidate source base: `1d0709e937934bd9d8eaaaa84dd59504d9810255`.
Core reference: `17005714f151e5502c559932319a3f2f74ac2436`.
Only three new Lean files and this dossier are added. Existing request, unwrap,
claim/unwrap bridge, project wiring and package pins remain unchanged.

## Public result and actual composition

`PAddress1.actual_wrapped_transfer_request_enqueue` derives the new `JoinedEffect`
from successful execution of the complete new runner. Its first conjunct retains
**all** of `AddressWrappedTokenCalls.JoinedEffect`, including the prior caller,
actual unwrap conversion/burn/stETH transfer, returned Word, quote, checked amount,
truncating shares cast, physical enqueue, events and ordered attempts.

The new conjunct identifies that same execution's first returned world. The actual
WSTETH CALL decodes `transferFrom(ctx.sender, ctx.self, originalAmount)`, with token
context `{self := wstETH, sender := ctx.self}`. `canonical_outer_call` is used in
`joined_success`: the old unwrap dispatcher delegates this selector to the new
executed adapter. The canonical arguments are therefore consumed, not merely
proved for an unused encoder. The result binds `TransferFromEffect` on the first
CALL's actual zero-value-transfer world to the same transferred world consumed
by unwrap, its same token effect, quote and enqueue. The first attempt returns
canonical bool true and has no nested external attempts.

`actual_wrapped_transfer_request_failure_restores` proves whole entry-world
rollback on any returned failure, including errors after token transfer/approval,
after unwrap burn/callback, or at the later queue amount/quote/enqueue stages.
Attempt journals remain diagnostic traces; they are not committed EVM logs.

## Source correspondence and ordering

| Pinned source | Executed model / derived observation |
|---|---|
| OZ 3.4.0 `ERC20.transferFrom`, lines 152–156 | `transferFrom`: `_transfer` completes before the allowance expression and `_approve`; the reply is encoded true. |
| `_transfer`, lines 208–217 | `move`: sender zero then recipient zero; empty concrete hook; checked sender subtraction/write; **fresh** recipient read on that debited world; checked addition/write; Transfer. |
| allowance expression, line 154 | `spend` reads `_allowances[sender][msg.sender]` on the post-transfer world, checks subtraction before `_approve`'s guards. |
| `_approve`, lines 272–278 | owner zero then spender zero; allowance write; Approval. |
| `WstETH.unwrap`, core lines 69–75 | Unchanged actual callee from the base: conversion STATICCALL before burn, qualified balance/supply writes, actual stETH transfer with 0.6.12 minimum32 decoder, then returned conversion Word. |
| `WithdrawalQueue._requestWithdrawalWstETH`, core lines 383–394 | Unchanged wrapped caller: transferFrom, unwrap, amount admission, STATICCALL shares, existing physical enqueue and Transfer. |

The prior exact `WstETH.asm` is reused and rechecked against the base, not rebuilt.
At assembly lines 1935–2047, `_transfer` returns before the allowance SLOAD and
`_approve`; around 3770–3850, sender SSTORE precedes recipient SLOAD and later
recipient SSTORE/Transfer LOG3. This agrees with the source model even for
sender=recipient. The arbitrary alias case is modeled by actual sequential
reads/writes rather than an injectivity premise. SafeMath addition rejects a Nat
sum ≥2^256, equivalent to the source wrapped-add `c >= a` guard for uint256 inputs;
subtraction guards precede the corresponding subtract/write.

Balances use mapping base 0; allowances use nested mapping base 1 with owner first,
spender second. All token storage is contract-qualified by WSTETH. No queue-root
projection of the old standalone unwrap helper is used. Compiler storage layout,
source/npm identity and independent Keccak preimages are in
`correspondence-inputs.json`; the two corresponding native slot checks execute
against the actual imported physical helpers.

## Validation, with scope

- Normal Lean 4.31.0 targeted source build: 1267 jobs, active new source 1.8s.
  Public/test build: 1269 jobs, active public 1.5s in the first test build and
  final tests 1.8s. Warm unchanged dependencies and inherited warnings are retained.
  Nine exported source theorems, two public theorems, 13 kernel examples and one
  public rollback instance; nine active axiom queries contain only `propext`,
  `Classical.choice`, `Quot.sound`. No new axiom, sorry or native_decide.
- `validate.py`: 1252 actual imported/new source identities, 11 package pins,
  old local source identity and selected imported olean byte identity. The scoped
  axiom query is a fresh environment inspection, not a full All/Trust build.
  `build-identities.json` binds final source/artifacts and exact Lake traces.
- Native FFI: ten executable complete-chain/ordering/rollback checks plus two
  independent physical Keccak preimage checks. Complete positive executions are
  diagnostics, **not** kernel-positive theorem instances. Existing official
  EvmYul native support is compiled into a temporary dylib with recorded inputs.
- Fresh Solidity compilation/execution: 13 tests, including one fuzz ×1024 with
  seed `0x20260911`. Eight inherited actual queue/token tests are freshly executed
  alongside five added tests (self-transfer/events/nested allowance, late allowance
  rollback, balance-error priority, recipient overflow, zero priority/zero amount).
  WQ and extended tests compile with solc **0.8.9**, optimizer200, London, legacy
  pipeline. The **actual unmodified WstETH** deployed creation artifact is reused
  byte-for-byte from solc **0.6.12**, optimizer200, Istanbul, legacy pipeline.
  No fresh token compilation is claimed. Forge version is 1.5.0-v1.5.0.
  Token/queue/test compiler metadata cover 11/17/19 actual sources respectively.
  The actual STETH implementation remains a configured fixture double.

Commands from the proof repository root:

```sh
lake build LidoSRv3.Tests.AddressWrappedTransferCalls
python3 audit/address-wrapped-transfer-call/validate.py
python3 audit/address-wrapped-transfer-call/check-correspondence.py
python3 audit/address-wrapped-transfer-call/run-diagnostics.py
(cd audit/address-wrapped-transfer-call/solidity && forge test --match-contract ActualWrappedTransferTest --fuzz-seed 0x20260911)
```

The initial Solidity import attempt outside the new fixture root failed allowed
path resolution; the final fixture copies exact prior sources into this dossier.
The initial source errors were address namespace/bound and canonical list/Word
normalization, and test errors were a missing explicit Word-valued amount for
rewriting. The validation script initially retained the old public filename in
its NEW list. All errors are retained as `development-*` logs and diagnosed;
they are not final successful-build evidence. No unchanged failed build was
repeated as a purported fix.

## Remaining boundaries

This is the typed World/Exec source composition under the selected physical token
layout, existing queue storage lens, explicit contract contexts and imported
hash/word implementations. It is not bytecode/deployed code identity, full EVM
dispatch/gas/ABI/memory/compiler equivalence, or a proof of arbitrary malformed
calldata decoding. The public canonical caller uses typed160 addresses and a
Word amount, zero CALL value and the actual generated payload; trailing calldata
and uint160 cleanup in the adapter do not establish a full external ABI theorem.

The outer pause/array/batch admissions and initial storage/layout provenance
remain scoped as in the preceding one-item request. STETH conversion, transfer,
queue quote and any subsequent STETH callbacks remain external. The new WSTETH
transferFrom has no external call in the pinned empty-hook inheritance; the
subsequent unwrap does. Its returned world is preserved, so neither post-burn
nor post-transfer final balances/conservation are claimed across arbitrary
callbacks. No fit, nonalias, frame, initial allowance or successful-stage premise
has been added. No global ADDRESS delivery/closure claim follows from this slice.
