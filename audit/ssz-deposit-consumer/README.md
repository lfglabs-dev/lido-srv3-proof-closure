# SSZ-1: the deposit CALL consumes the root inputs

This increment supports the promise that the deposit root is bound to the
public key, withdrawal credentials, signature and amount actually consumed
by the deposit call. The public consumer is
`PSsz1.actual_deposit_call_binds_root`, imported by AllGuarantees, queried by
Trust and registered as the current deposit-path result under P-SSZ-1.
The separate CL verifier path remains OPEN; this is not full SSZ-1 acceptance.

`SszDepositConsumer.consumedInput` reads only the concrete decoded `Fields`
and actual `Request.value`. Every byte bound follows from UInt8; the amount
is `msg.value / 1 gwei`. There is no independent helper input or root-match
premise. `deposit_success_consumed` inverts the actual callee guards to derive
48/32/96-byte field widths, uint64 gwei range and exact gwei divisibility.
`dispatch_success_consumed` binds these fields to the same decoded payload.
`push_success_consumed` consumes the actual CALL wrapper and dispatcher after
the provisional value transfer. The public theorem consumes that result.

The independent callee reconstruction follows the pinned deposit contract's
hash chain. `reconstructed_consumed` proves forward equality with the
BeaconChainDepositor helper for those exact fields: 48-byte key plus 16 zero
bytes; 64-byte signature prefix and 32-byte suffix plus 32 zeros; the nested
signature root; credentials paired with the key root; eight little-endian
amount bytes plus 24 zeros paired with the signature root; final two-digest
preimage. The existing opaque SHA produces exactly 32 bounded bytes. No
injectivity, root inversion or relation to a separate CL transaction is used.
The uint64 amount bound is derived from the executed callee guard, not added
to the input domain. All entry payloads admitted by the existing interpreter
are quantified; canonical alignment or independent successful stages are not
new hypotheses.

## Source correspondence and limits

The pin is core 17005714f151e5502c559932319a3f2f74ac2436:
BeaconChainDepositor.sol:110–153 and deposit_contract.sol:101–159.
The existing caller ABI serialization, concrete callee decoding and CALL
interpreter are unchanged. This result does not establish general malformed
ABI acceptance equivalence with solc 0.6.11, exact revert/event byte encoding,
or complete TOPUP/DEPOSIT entry composition. These remain explicit limitations
of the respective source interpreters, not newly accepted global assumptions.
The existing canonical source-payload decode theorem remains available.

SSZ-1's other path still needs the actual CLValidatorVerifier internal calldata
frame to consume its same witness, fourth credentials argument, dynamic proof
array, validator index, timestamp request and returned EIP-4788 root in the
already-proved typed leaf/branch result. A universal relation between separate
validator-proof and deposit transactions is not a Solidity obligation. The
historical Nat.pair / synthetic EncodingInput results remain historical and
are not refinement targets for the actual bytes.

Accepted general compiler, declared Verity semantics, cryptographic, general
gas and consensus boundaries remain unchanged. ALLOC-1, ALLOC-2 and RESERVE-1
are unchanged and outside this improvement scope.

## Checks

The current combined source includes integrated DEPOSIT303 and retains both
public registrations. The 1461-job facade build and full 29-exact-axiom Trust
check pass. New four production results and the public facade use only
propext, Classical.choice and Quot.sound. The full repository still has its
23 existing native fixture axioms and three existing production exceptions.
Actual import manifests were checked against 1592 source bodies and 11 Lean
package pins. The core Solidity pin is separate from those package pins.
Main-registry, UX2 mutation, public-surface and proof-escape checks pass.
The latter namespace inventory does not cover all audit/trio fixtures.

The runtime programs are unchanged; no new concrete execution fixtures or
Forge run are claimed. The universal inverse and forward correspondence
proofs are the new validation. One initial UX2 mutation invocation refused
dirty source inputs; sources were committed before rerunning successfully.
Independent review of the exact frozen candidate is still pending.
