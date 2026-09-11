# Physical StakingRouter credentials getter consumed by TOPUP

Base `f00863276fbe279c566328ed4ae90f5bf223a38e`; core pin
`17005714f151e5502c559932319a3f2f74ac2436`. Three new Lean files and this audit
packet only. Existing source, All/Trust, dependencies and site are unchanged.

The selected getter's dispatcher executes on the exact STATICCALL request made
by `TopupCredentialCall.run`. It decodes moduleId from those actual calldata
bytes and reads storage qualified by the request target. The public theorem
`PTopupPhysicalCredentialGetter.actual_physical_credential_root_module_memory_effects`
retains every conjunct of the prior actual credentials/root/module memory
consumer, including exact result/world/journal identity, actual root and module
calls, ordered authenticated witness/limit evidence, cap and sum, zero or
physical positive effects, and scalar decoder/cursor bounds. The same existential
credentials word is additionally proved to be the physical selected word, with
canonical 32-byte response, nonzero physical membership, type byte 2 and preserved
low 248 bits from the actual router credentials slot. There is no unrelated
successful getter equation supplied to the public theorem.

`run` substitutes `dispatch hash` directly into the previous execution. Its
unchanged universal failure theorem restores the complete initial World;
registration errors bubble their canonical custom-error bytes and keep the
actual failed static attempt. Existing lookup-before-root/module observations,
ordinary no-code behavior, allocation-before-decoder order, prefix check and
late rollback remain effective. No model of deposit execution is called by this
new getter; only the accepted physical storage helpers are reused.

## Exact source/IR correspondence

The existing complete `audit/topup-module-nocode/router-ir.txt` is sufficient:
BatchRouter inherits unmodified pinned StakingRouter; compiler metadata is
solc 0.8.25+commit.b61c2a91, viaIR optimizer 200 Cancun. No compiler or Forge runtime
is rerun in this increment. `validation/compiler-reuse.json` compares all 28
retained compiler inputs against pinned core Git objects, accepted vendored OZ
bodies and the unchanged fixture, including metadata Keccak identities. It also
rechecks the complete IR hash and independently computes the ERC7201 root and
both selectors. This is the fixture profile, not production bytecode identity.

| Pinned source / complete retained IR | New executed model |
| --- | --- |
| StakingRouter639–642; IR2814–2829 | Selected selector 0xf85c6ceb, no caller authorization, nonpayable guard, signed ABI head check and actual calldataload(4); response mstore/return32. `dispatch_request` proves the generated request actually traverses this decoder with the same id. |
| StakingRouter1099–1107, SRUtils45–47, SRStorage66–68; IR4249–4260 and5152–5160 | `_getModuleState` first checks UintSet.contains. Its `_positions[id]` slot is keccak(encode32(id) ++ encode32(routerRoot+2)); any nonzero word passes. There is no array length/index-consistency requirement in contains. Zero returns canonical `StakingModuleUnregistered()` bytes 0xd41d6282. |
| SRStorage30–32, SRTypes118–135/174–190; IR2821–2826 | Config at keccak(encode32(id) ++ encode32(routerRoot)); WC type is bits 232–239. No Active check, enum conversion or type-validity check is inserted. Status bits 224–231 are not interpreted. |
| StakingRouter1012–1014/1046–1049, WithdrawalCredentials.setType; IR4537–4543 | Actual router WC at routerRoot+4, retain low 248 bits and replace high byte with selected uint8. The reused `selected_fields` proof identifies these exact parts. |
| SRStorage14–16; IR4502–4535 | Namespace root 0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000 is independently recalculated from its exact preimage. Mapping hashing remains the existing explicit hash parameter. |
| f008 actual credentials consumer | Physical canonical response is passed through the actual inherited static transport and scalar decoder. The decoded same word overwrites e.credentials and enters the actual validator trees; public proof consumes this relation, not a separate unused body lemma. |

The selected dispatcher rejects other selectors as outside its modeled slice;
it does not claim that the real router rejects all other selectors. The initial
less-than4 check and head arithmetic use EVM word projections of host lengths.
Trailing calldata is permitted. Generic arbitrary request values are rejected
by nonpayability, while actual generated STATICCALL requests always carry zero.

## Retained boundaries

Physical membership here means the source's nonzero `_positions` word. It does
not establish deployment/setter reachability, registry-array consistency or
collision freedom. No storage frame, hash injectivity, membership, type, range
or successful-stage premise was added. The actual static interpreter reads its
supplied World and exposes no writable return World.

This is a typed storage getter/ABI slice, not a whole compiled callee-memory or
gas proof. Callee memory allocation/copy/resource behavior and deployed router
code identity remain outside. Existing physical-root/hash interpretation and
all f008 boundaries remain: role/pause/timing/root age/locator and outer gateway
ABI, actual gateway→router topUp call/role binding, final gateway history write,
separate caller-side cursor provenance/copies/aliasing, typed SHA/root response
and arbitrary module/callback semantics. The added getter body has canonical
success and unregistered bytes; this does not claim full error ABI coverage for
all inherited later stages.

## Checks

Normal named `lake build LidoSRv3.Tests.TopupPhysicalCredentialGetter` passes
1,366 jobs. Seventeen kernel regressions cover physical preimages and selected
word, canonical request dispatch and trailing calldata, module/caller/target
roles, no status/enum guard, representative type bytes including 255, nonzero maximal position, early
registration error, short/wrong-selector rejection, full actual batch and trace,
unregistered-before-return-decoder, type1 rejected by the gateway, and late
post-module rollback. A concrete success instantiates the complete new public
consumer. These structural kernel examples retain the explicitly partial
constant SHA fixture from earlier tests.

Four fresh FFI diagnostics reuse byte-identical independent Python SHA vectors
from f008: actual physical getter → three actual root calls → module allocations
[1 ETH,0,2 ETH] → positive physical continuation; missing membership before any
root; changing the physical WC low bits causing exact invalidProof; and physical
type1 rejected by the gateway before roots. The old supplied e.credentials=999
is replaced by the actual stored/selected word. These are IO runtime diagnostics,
not native axioms or kernel-evaluated whole-success theorems. Runtime sources,
reused vector identities and temporary native-library commands are recorded.

The actual import closure contains 1,349 sources at 11 exact package pins;
24 fresh named ordinary axiom sets contain only propext/Classical.choice/Quot.sound.
Three normal module/artifact identities are retained.

The validator recomputes scoped ordinary axiom closures in the actual registered
regression environment and checks every imported old source against base or
package pins. `--write` records JSON; default mode compares without rewriting.
Global All/Trust validation and independent exact full source/IR review remain
root integration tasks. No new Forge execution or compiler replay is claimed.
