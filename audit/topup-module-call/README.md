# TOPUP module call and raw return transport

This increment starts at StakingRouter.sol:717, after the caller computed the
rounded target. The source pin is `17005714f151e5502c559932319a3f2f74ac2436`.
It extends the accepted post-module continuation without changing that module,
the delivered trio, the registered parents, or dependency pins.

`TopupModuleCall` reads the module address from the low 160 bits of the actual
namespaced config word, serializes the existing five-argument encoder, and
passes those bytes with value zero through `CallData.invoke`. The arbitrary
external interpreter receives that request and the provisional World. Its raw
reply is decoded into words; its returned World enters the existing guards,
withdrawal, beacon loop, balance assertion and final event.

`call_success_origin` derives the actual external reply and attempted request
from successful execution. `decodeReturn_encoded` proves an arbitrary canonical
word-array roundtrip, with arbitrary trailing bytes and a length below 2^64.
`program_success_origin` derives the raw reply, successful decode, and the exact
allocation/World continuation from any successful program. `program_encoded`
composes canonical bytes with that continuation. Root failure restoration is
the existing Live.run rule, not a new EVM rollback correspondence theorem.

There are nine public source theorems, 29 kernel examples and one positive
composition theorem, with seven ordinary axiom queries. The positive scenario
reuses the accepted withdrawal/beacon proof on the module's returned World.
Other tests cover zero-target module effects, malformed replies, exact bubbling,
packed address reads, and a later budget failure rolling back module effects.
The zero-target fixture deliberately changes the router balance: this adapter
does not promise conservation across arbitrary module behavior.

The validation receipt distinguishes fresh direct Lean checks from the cached
1274-job Lake replay. Imported sources and package pins are compared against
their Git versions; selected core source hashes are retained. This does not
certify every toolchain/dependency binary or claim a full rebuild.

Eight Forge tests exercise the actual imported SRStorage getter,
IStakingModuleV2 interface and compiler CALL/return decoder. One property runs
1024 cases. A further 64 vectors exported by the actual Lean encoder are
compared with compiler-produced calldata and return bytes. The harness is a
callsite harness with an explicitly arbitrary raw-response module; it does not
execute the full StakingRouter preamble or full Solidity beacon continuation.
The generated vector source is retained with its generator and raw JSON.

## Boundaries retained

- Authorization, input admission, target computation and module registration
  precede this adapter. Inputs are typed values at that point, not a proved
  decoding of the external topUp ABI.
- Module implementation, callback restrictions, module balance effects and
  aggregate inter-call history remain open. The callee is an arbitrary external
  interpreter. The next phase preserves its effects; it does not assume a frame.
- The payload reuses the accepted word encoder. The 64 byte comparisons are
  finite differential evidence, not a new universal compiler encoder theorem.
- The logical byte decoder omits compiler memory allocation and opcode gas.
  The inspected compiler allocates before checking array extent: a count of
  2^59 in a short return produces Panic(0x41), while the logical decoder rejects
  the byte extent with an empty fault. Both observations are retained in tests.
  The count >=2^64 guard is separately represented as Panic(0x41).
- Live.CallData.invoke checks code size before the call. The inspected modern
  typed CALL rejects a no-code target through its empty return decode instead.
  The failure result agrees; no-code attempted-call traces are not identified.
  Successful Live calls derive their positive-code domain in the origin theorem.
- Canonical roundtrip has no claim about memory/gas admission for enormous
  arrays. Revert ABI, compiler/X execution, Keccak/SHA correctness, beacon
  identity, runtime provenance and complete TOPUP guarantees remain open.

Independent exact-candidate review is required before integration. All eight
unfinished guarantees remain OPEN. Site PR426 is never merged or deployed.
