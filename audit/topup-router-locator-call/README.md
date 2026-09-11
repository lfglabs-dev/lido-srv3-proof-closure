# TOPUP actual locator selects the complete timing/getter/root/module/history path

Base: accepted336 `295e6c676b61de1815b7027a49ed8bc5fe5b8b3f`.
Pinned core: `17005714f151e5502c559932319a3f2f74ac2436`.

`PTopupRouterLocatorCall.actual_locator_timing_credential_root_module_memory_history`
derives the actual gateway-to-LOCATOR `stakingRouter()` request and successful
raw response, canonical160 router and successful scalar allocation. That router
replaces `ctx.sender` before the physical credentials getter and the actual
root/module/physical continuation. `ctx.self` remains the supplied Lido address;
`e.gateway` is the caller of the locator, credentials and beaconroots calls.
The locator allocation's returned next pointer is actually used as the
credentials getter cursor. The original `ctx.sender` is not used downstream.

The complete 335 public conjunction is copied verbatim into `TimingEffects`,
with a byte comparison in the validator. It includes the earlier full physical
credentials membership/type/word evidence, actual authenticated witness rows,
exact sum and cap, module CALL and decoder, zero/positive physical effects and
scalar cursor facts. It also retains the exact intermediate result, actual
produced loop total, all journals, and final history world/event/packed fields.
The new public result equation connects this same run to the new result's World,
suffix and ordered observations, preceded by the actual locator attempt.
The public theorem has only the successful complete new execution premise.

Execution order is length/config guards, temporal guards, locator STATICCALL,
physical credentials getter/prefix02, actual roots, actual module/continuation,
then history. The executable calls `TopupTimingHistory.finish/execute`, so it
does not execute the temporal prefix a second time. Its relation to the old
public run follows from the guards already executed before the locator. The
sole length reread is the existing pure one on identical World/config/rows,
covered by the unchanged unconditional `execute_projection`. The root loop and
module are executed once; the recorded loop output supplies history's total.

The universal failure theorem restores the complete pre-prefix World. Lookup
failure retains the actual locator attempt and no suffix. Later failure retains
the locator plus all reached credentials/root/module attempts and rolls back
all modeled world effects. No frame, successful-stage, sum, funding, fit,
role-address equality, byte-width or SHA-totality premise was introduced.

## Source and complete compiler correspondence

The unchanged complete 2519-line `audit/topup-credential-call/solidity/GatewayWitnessHarness.ir`
was reused by exact byte identity to base336 and its original compiler input/
output. All 22 original bodies and compiler metadata Keccak were checked:
17 pinned core sources, four accepted OpenZeppelin 5.2 sources, and the unchanged
GatewayWitnessHarness fixture. That harness inherits the actual TopUpGateway
and CLValidatorVerifier without overriding their operations. Its recorded
profile is solc 0.8.25+b61c2a91, viaIR, optimizer200, Cancun. This is a fixture
profile, not a production bytecode identity claim.

| Pinned source / complete IR | Executed connection |
| --- | --- |
| TopUpGateway163–184; IR372–479 | Existing lengths/count then short-circuit checked block distance, checked uint64 root-age addition, old-root and prior-timestamp guards, before any locator attempt. |
| TopUpGateway185; IR480–489 | Four-byte selector `ef6c064c`, independently Keccak-derived from `stakingRouter()`. Actual STATICCALL caller is gateway, target is supplied immutable locator, value zero. No EXTCODESIZE precheck. |
| IR490–497 | Actual failed STATICCALL bytes bubble before allocation or decoding. Forbidden state change follows the inherited typed static-call error path. |
| IR498–511; helper1685–1695 | Copy min32 of word-sized returndata length; finalize allocation; signed wrapped ADD/SUB head check; first-word load; reject unless canonical160. The existing `copied_signed_guard` establishes the bounded signed-head equivalence. `decode_fields` derives next=cursor+32 and next<2^64; no bound is supplied. Trailing bytes are ignored. |
| IR512–538 | `expr_7`, the decoded router, is the actual credentials STATICCALL target. `_24=mload(64)` consumes the locator allocator's next pointer. Physical membership/module storage is qualified by the same router. |
| IR541–548,829 | The same physical credentials word passes prefix02 and is stored into the actual validator leaf. Existing root calls/proofs and actual module arguments consume it. |
| Existing 335 source consumers | `routerContext ⟨Lido,router⟩=⟨router,Lido⟩`; the selected router determines the actual module caller/address, packed block cap, credentials storage, and physical continuation context. |
| TopUpGateway233–235; IR1113–1130 | The same executed loop total, including positive limits with zero allocations, controls the final packed history update/event on the actual post-module World. |

`validation/correspondence.json` pins the complete reused compiler artifacts and
checks the ordered relevant IR segment, including absence of a code precheck,
allocator/head/canonical guard order, resolved target and credential-leaf store.
The complete remaining root/module/history paths retain their reviewed source
identities and scope; this additive theorem does not reprove a compiled EVM
interpreter for those paths.

## Explicit phase boundaries

- The immutable locator identity is supplied. The real STATICCALL is executed
  against an arbitrary typed read-only callee; this is not a proof of deployed
  LidoLocator's body, immutable storage construction or initialization.
- Role/pause, full external gateway ABI, and the outer gateway-to-router
  `topUp` CALL/dispatch remain outside this composition. Selecting Context.sender
  does not execute or prove that omitted outer CALL, its role binding or gas.
  Initial deployment/storage and the supplied Lido/gateway roles remain as before.
- The initial locator cursor is a scalar phase input. Its actual returned next
  is used for the next scalar getter allocation, but module `returnBuffer` remains
  a separate explicit later phase input. Full memory writes/copy/aliasing, earlier
  free-pointer provenance, outer-call allocation and opcode gas are not claimed.
- The inherited zero-code STATICCALL arm describes ordinary EOAs/undeployed
  targets, which return empty successfully and then fail decoding. Precompile
  dispatch is outside that arm's correspondence; this boundary is not silently
  discharged by the new successful-code theorem.
- Existing typed SHA/precompile/root replies, physical hash interpretation,
  arbitrary module/callback world changes, semantic logs and error constructors
  retain scope. No keccak injectivity, metadata frame, alignment or balance
  assumption was added. `pendingBalanceGwei` remains a legitimate source argument.

## Verification receipts

Normal `lake build LidoSRv3.Tests.TopupRouterLocatorCall` passes 1372 jobs.
The three current normal Lean artifacts/setup/trace identities are recorded;
no skipKernelTC, native theorem axiom or nonstandard proof option was used.
Nineteen kernel computations cover exact request, canonical zero/max and high-bit
rejection, short/trailing responses, allocator-before-head/canonical error order,
length/count/timing priority, revert/forbidden/no-code behavior, actual address
selection, full journals, consecutive getter cursor allocation, positive-limit
zero-allocation history, zero-limit skip and late rollback. A concrete full
success starts with the deliberately wrong supplied router 999 and actually uses
returned router 2. It instantiates the public theorem; a twentieth named theorem
uses the universal public rollback proof. Kernel fixtures use a structural hash
model and do not themselves establish independent cryptographic evidence.

Eight fresh native IO diagnostics use unchanged independently generated f008
SHA roots/50-word branches through the existing SHA FFI. They exercise the new
locator runner with successful physical positive execution, zero allocations
with positive authenticated limits, altered credentials, altered root, temporal
failure before lookup, late full rollback, uint64 age overflow and a changed
locator selecting absent physical router storage. The original supplied router
and credentials are overwritten. These are runtime diagnostics, not additional
kernel axioms; native runtime/vector identities and commands are retained.

Eight fresh Forge tests use the actual inherited Gateway and the independent
SHA fixture. The locator fallback checks the actual gateway caller and exact
four-byte selector and returns raw configured bytes. Tests cover actual selected
router consumption, trailing bytes, short/noncanonical replies, revert bytes,
ordinary no-code, timing priority and length priority. The selected-router test
uses a new recorder and verifies the old recorder is untouched. No gateway or
verifier operation is replaced; the router recorder and locator fallback remain
fixture boundaries. These eight tests are newly executed, with 23 exact source
inputs and three actual compiled artifacts/metadata retained. The old seven
fixture tests/fuzz properties were not rerun or newly credited. No production
bytecode or Lean-kernel theorem is inferred from Forge runtime success.

`validation/validate.py --write` records source/normal artifact identities and
fresh ordinary scoped axioms; default compares without rewriting. The actual
registered regression closure contains 1355 sources at 11 exact package pins.
All 27 named ordinary axiom closures contain only propext, Classical.choice and
Quot.sound. The final default comparison passes. These are scoped checks;
AllGuarantees/Trust wiring, combined global gates and independent exact source/
IR review belong to root integration.

Development failures supplied no proof credit: an explicit Word-value projection
and a namespace opening fixed initial proof elaboration errors; a copied native
runner path was corrected before its successful diagnostics. The first receipt
validator expected a non-inlined root-age function name and stopped after its
successful source/axiom checks. The retained `development-validator.log` records
that failure; the corrected validator checks the actual inlined guard sequence,
and `readonly-validation.log` is the final full PASS. No unchanged failed proof
build was retried. Only the three additive Lean modules and this dossier changed.
