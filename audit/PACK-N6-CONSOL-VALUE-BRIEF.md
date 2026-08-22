# Pack N6 — Consolidation value-bearing request calls

## Claim

`justified_interpreter_forwards_exactly_msg_value` covers every successful
execution of the justified vault request interpreter when:

- the existing pinned source guards commit the batch;
- the gateway nonzero premise is supplied by the caller;
- the entry state records the same `msg.value` as the source inputs; and
- the vault can fund that value.

The conclusion retains caller authorization, nonempty/aligned 48-byte key
arrays, checked fee multiplication, and exact-fee equality. It additionally
proves:

- fresh journal entries are exactly the committed request calls;
- the sum of fresh CALL values equals `msg.value`;
- the vault ETH delta is exactly `-msg.value`;
- `preservesEthBalance` holds; and
- every fresh frame is a request frame, so this parent performs no
  consensus-layer verification.

The execution uses `externalCallBindTo` with each committed request's fee.
That primitive checks funds, debits `selfBalance`, and appends the target,
value, and payload to the journal.

## Scope

This parent uses a justified interpreter. It does not claim official function
denotation success. It does not start the Bus, discharge the gateway nonzero
premise, model gateway delay/quota, perform consensus-layer verification, or
bridge to the ETH-1 parent.

## Kill-line

`zero_value_calls_refute_exact_forwarding` keeps the source commit and therefore
keeps gateway authorization, 48-byte validation, the multiplication bound, and
exact-fee equality. Its mutant executes the same request payloads through
zero-value CALL frames. The vault retains its balance, the forwarded sum is
zero, and the nonzero `msg.value` forwarding conclusion is false.

## Modules

- `LidoSRv3/Audit/Verity/ConsolidationValueTx.lean`
- `LidoSRv3/Audit/Spec/ConsolidationValueCorrespondence.lean`
- `LidoSRv3/Audit/Guarantees/PConsolidationValue1.lean`
- `LidoSRv3/Tests/PackN6ConsolValueMutants.lean`
