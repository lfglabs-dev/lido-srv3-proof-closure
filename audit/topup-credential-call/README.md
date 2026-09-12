# TOPUP credentials STATICCALL consumed by root/module memory effects

Base: `f193ebf96beef3f5e1e1568fc9f2b906c0192299` (accepted329).
Core: `17005714f151e5502c559932319a3f2f74ac2436`.

`PTopupCredentialCalls.actual_credential_root_module_memory_effects` derives the
actual gateway→router credentials request, its successful raw reply, first-word
bytes32, prefix02 and scalar allocation bounds. The returned word replaces
`e.credentials`; the same actual root/witness loop consumes that replacement
and produces the arrays passed to the actual module CALL. The complete previous
`PTopupMemoryCalls.actual_root_module_memory_effects` conclusion is retained:
ordered authenticated rows/limits, exact sum and cap, zero or physical positive
effects, actual module return decoding and both scalar allocation/cursor facts.
The result equation relates the actual new result's world and both downstream
journals to precisely that old consumer, preceded by the real lookup attempt.
It is not an unused oracle adapter or an assumed successful earlier stage.

The universal failure theorem restores the complete initial World, including
late memory/continuation failures after a successful module. Lookup failures
and wrong prefix retain their lookup attempts and execute no root or module.
Length/config admission executes before the lookup; the old runner's second
check is a pure recheck on identical config and paired rows. No length or
successful stage premise is supplied to either public theorem.

## Exact source and compiler mapping

The unchanged `audit/topup-gateway-witness-batch/solidity/TopupGatewayWitnessBatch.t.sol`
is compiled as `GatewayWitnessHarness`, inheriting unmodified TopUpGateway and
CLValidatorVerifier. `solidity/compile.py` materializes each exact pinned Git
body into standard JSON, using already available Mac solc 0.8.25, viaIR optimizer 200
Cancun. There are 22 inputs, all byte-identical to the original inherited gateway
fixture receipt: 17 core, four OpenZeppelin 5.2 bodies, one harness. The OZ bodies
are reused from accepted DEPOSIT DSM vendoring and checked against the original
fixture hashes. Input, actual raw output, complete optimized IR, compiler binary
hash/version, metadata source Keccak and independent selector hash are retained.
This is the fixture profile, not an assertion of production bytecode identity.
The initial input-collection attempt missed the OZ import namespace and stopped
before compilation; it was corrected to use the existing accepted bodies.

| Source / retained complete IR | Consumed new model |
| --- | --- |
| TopUpGateway159–175; IR372–438 | Existing checkLengths reads the packed gateway config on `e.before` and checks nonempty/count/matching lengths before lookup. Rows pair witness/index/pending as in the retained typed domain. |
| TopUpGateway189; IR512–517 | Actual lowLevelStaticCall from `e.gateway` to `ctx.sender`, zero value, selector `0xf85c6ceb` + exact 32-byte moduleId, 36 bytes total. No EXTCODESIZE precheck is executed here. |
| IR519–525 | Failed STATICCALL bubbles actual bytes before any successful-return allocation/decoder. Forbidden-state-change failure remains distinct at the typed external boundary, then bubbles empty. |
| IR529–538; helper1685–1695 | `copied=min(32, word(returndatasize))`, finalizeAllocation first, signed wrapped ADD/SUB size check, unrestricted first-word mload. `copied_signed_guard` proves the signed comparison equals the natural check for this bounded copied size. `decode_fields` derives copied 32, next=cursor+32 and next<2^64 without a bound premise. Trailing bytes are ignored. |
| TopUpGateway190/334–338; WithdrawalCredentials.getType/isType2; IR541–548 | `wc.val / 2^248 = 2` checked before roots. Only the prefix is required; no invented zero-middle/address-canonical restriction. |
| TopUpGateway204–228; CLValidatorVerifier44–85; IR590–995 | `resolved e wc` overwrites the supplied credentials with the same decoded uint256 converted to Digest. IR538's `expr_8` is stored into validator leaf offset 32 at 829 and flows through the same SHA tree. Existing pubkey/order/activation/slot/root/index/leaf/proof/headroom stages remain unchanged. |
| Retained router/module/physical/memory consumers | The old runner executes once on that resolved environment and the same World. Public proof applies the whole previous public theorem to this actual success, retaining all its conditions and effects. |

The complete relevant getter/allocator/entry loop paths were read, including
actual root response, leaf credential store, proof loop and amount calculation.
The later gateway→router topUp call at IR1002–1100 and final gateway history
write are not newly represented. Their presence in the complete archived IR
must not be confused with execution by this new typed phase.

## Boundaries retained explicitly

- Role/pause, block distance/root age, LOCATOR.stakingRouter, outer topUp ABI
  admission and the actual gateway→router topUp call/role binding are excluded.
  `e.gateway` and `ctx.sender` retain their supplied address roles; no equality
  premise or deployed-locator/body authentication is introduced.
- Getter is an actual typed read-only STATICCALL. Its arbitrary callee body is
  not a proof of StakingRouter's storage-backed getter. Ordinary zero-code targets
  succeed empty then fail allocation/decoder; precompile dispatch is outside
  that inherited zero-code arm.
- `credentialCursor` and module `returnBuffer` are separate explicit scalar
  phase inputs. Earlier memory provenance, their relationship, actual writes,
  copies/overlap/aliasing with free-pointer storage and opcode gas are not
  proved. In particular this is not a full compiled memory theorem merely
  because scalar guards and byte values follow the inspected IR.
- Typed roots/SHA, physical storage hash interpretation, arbitrary module/
  callback effects and the older continuation boundaries remain unchanged.
  No SHA-totality, successful-stage, frame, keccak-injectivity, byte-width,
  sum, funding or alignment premise was added. pendingBalanceGwei remains a
  legitimate paired source argument, not invented storage.
- Error constructors distinguish source error classes; complete error LOG/
  revert ABI encoding and deployed bytecode refinement are not newly proved.

## Checks

Normal named `lake build LidoSRv3.Tests.TopupCredentialCall` passes 1,360 jobs,
including all three additive modules. Seventeen named kernel regressions cover
selector/caller/moduleId, raw/short/trailing decoding, allocator error order,
ordinary zero-code attempt, actual batch success and overwrite, complete phase
ordering, prefix and lookup failure before roots, length failure before lookup,
and late post-module rollback. A concrete whole-batch success instantiates the
full public theorem. Constant structural SHA in these kernel fixtures is
explicitly not independent cryptographic evidence.

Five fresh FFI diagnostics exercise independently constructed SHA trees.
`make-vector.py` uses Python hashlib to form three actual witness leaves and
50-word branches to a common root. The existing EvmYul SHA FFI verifies them
through the typed actual root calls; the actual credentials getter accepts only
the exact request. The positive batch consumes allocations [1 ETH,0,2 ETH] and
runs the existing physical continuation. Original supplied credentials 999 are
overwritten. Another prefix02 credential, corrupt root and corrupt proof reject;
a late scalar module allocation failure is observed. These are IO diagnostics,
not kernel-evaluated success proofs or native axioms. Runtime source hashes and
fresh native-library build commands are retained.

No Forge runtime was rerun. The unchanged inherited gateway fixture's historical
seven tests (three 1024-run fuzz properties) are reused only for their original
scope and exact 22 input identities. This lot's new checks are the normal Lean
proofs/regressions, five FFI diagnostics and fresh complete compiler IR.

`validation/validate.py --write` records actual registered import/source/artifact
identities and fresh ordinary scoped axiom closures. Default mode compares
without rewriting outputs. The actual closure contains 1,343 sources at 11 pins;
25 fresh named ordinary axiom sets use only propext/Classical.choice/Quot.sound.
Three current normal artifact identities are recorded. Combined All/Trust checks and independent exact
source/IR review belong to root integration; scoped results do not claim a
future combined global gate. This checkout edits only the three new Lean files
and this dossier. Failed development compiler/proof iterations do not provide
proof credit; final logs contain only accepted declarations.

The complete compiler stdout/IR and build logs are retained verbatim. The sole raw
whitespace exception is the compiler IR blank EOF (line2519), preserved exactly
as irOptimized plus its documented appended newline. Source/nonraw diff-check
passes; unrestricted diff-check reports that single exception.
