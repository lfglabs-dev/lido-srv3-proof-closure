# Gateway witness-batch harness prereview

Verdict: **CLEAN for the observed finite Solidity harness scope**, with the frozen five-file Solidity dossier verified. Final combined Lean candidate review remains separate. No blocking or nonblocking source finding. This is not acceptance of new Lean modules, complete TOPUP, consensus anchoring, module/funding effects or universal EVM refinement.

Read the complete 193-line harness, actual pinned TopUpGateway and CLValidatorVerifier, witness structures, GIndex, SSZ, WithdrawalCredentials and PausableUntil; inspected the relevant BLS calldata/SHA helpers and inherited role/initialization operations. Twelve consumed source files match exact core commit `17005714f151e5502c559932319a3f2f74ac2436`. No rebuild, project write or Git mutation was performed. The finalized README and receipt were subsequently read in full. Their reproduction command, explicit remappings, Forge1.5.0 and solc0.8.25 identities, seed0x20260909 and existing exit0 results are now included in the reviewed dossier.

## Genuine source execution and fixture setup

`TopupGatewayWitnessBatch.t.sol:15–26` inherits TopUpGateway without overriding topUp, verifier, evaluator, storage getter or admission operations. Constructor setters and the real internal role grant prepare a standalone implementation fixture. The real role modifier and resumed check execute; the fresh pause slot is zero at timestamp1000. This does not exercise proxy initialization or establish deployed authorization/configuration.

The locator and router at lines29–45 are explicit fixtures. The router returns configured WC and records the hash of all five actual ABI arguments. It executes no StakingRouter module, withdrawal, funding or beacon deposit. `anchor` at line113 mocks only EIP-4788 at the exact timestamp request, returning a constructed root. The genuine CL verifier, BLS and SSZ path still runs; no SHA mock, fabricated verifier Boolean or verifier override supplies success. Both GIndex configurations are deliberately identical with pivot0; this is no fork-transition test.

## Independent tree and serialization

Lines60–111 compute LE256 using an octet loop and the validator leaf with builtin SHA on independently constructed eight fields. Full48-byte pubkeys plus16 zero bytes are used; expected WC is the separate configured word, and the actual slashed integer encoding is reproduced. This fixture does not call Lido SSZ/BLS helpers to construct its expected root.

The two ordered validator leaves share the other leaf as proof[0]. Depth1 begins at hash(zero32,zero32);39 extensions build the remaining empty subtrees to registry depth40. proof[40] mixes actual length2 encoded little endian. Validators occupy field11 of an independently reduced64-position state with37 named-schema positions and opaque other roots. Six state siblings occupy41–46. The header puts state at3, includes independently encoded slot4096/proposer18, and adds three siblings47–49. In-place reductions read each sibling before overwriting its level; operands of later pairs are not overwritten by earlier writes. In particular proof[48] is hash(slot,proposer), as the actual verifier requires. These paths correspond to state index150*2^40+i and header index1430*2^40+i, for i=0,1.

These are synthetic length-two structural fixtures. Other state roots do not encode full semantic state fields, and the mock does not authenticate a consensus root or deployed fork. No arbitrary-list or membership-converse conclusion follows from these tests.

## Meaningful observed checks

- Lines127–155 execute actual topUp and compare all router argument arrays, including positional key/operator pairing, derived pubkeys and independently calculated headroom in wei. The full uint64 fuzz domain mostly reaches zero-headroom cases; the separate bounded-domain fuzz and explicit30/21ether example exercise positive and minimum-cutoff values. Timing checks are at fixed timestamp1000 and are conditional on the sum of produced limits.
- Lines157–169 verify actual exact revert bytes and source priority: pubkey width before duplicate-index rejection; activation before bad Merkle proof; bad proof before pending-addition overflow; corrected proof then panic0x11; changed same-type WC then InvalidProof. Slot4096/epoch32 yields epoch128, so activation129 is a real competing failure.
- Lines171–176 verify that slashed/exited validators still require valid proofs but then skip pending addition, even at uint256.max, and return no positive timing update. This covers both exclusion predicates across the two entries.
- Lines178–183 check pending-array admission and the actual zero epoch-divisor panic0x12. Constructor permits that divisor; the harness does not invent a constructor guard.
- Lines185–191 directly corrupt both actual namespaced config words and read the genuine uint64 count, target at bit160 and minimum in slot+1. The compiler layout independently confirms these locations. `layoutOnly` at slot0 is only a compiler type-layout witness, not the storage used by actual getters. Arbitrary words are not claimed reachable setter states.

`reject` line117 observes zero persistent router call-counter effects after rejection. Since reversion also rolls back an earlier router counter write, this observation alone is not a trace proof of no transient router call. Here the source placement and concrete expected pre-router errors independently justify the intended order. Keep that distinction in downstream claims. No harness change is required.

## Evidence and remaining bounds

The supplied log records solc0.8.25 successful compilation and seven passing tests: three fuzz properties of1024 runs plus four deterministic tests, zero failures/skips. I inspected this existing log, not a fresh reviewer execution. The finalized README records the full actual command/remappings and seed0x20260909, with exit0 in the receipt. All 23 source/configuration hashes and four artifact hashes match local bytes; all 17 core source entries also match the pinned Git objects. The reused OpenZeppelin5.2.0 archive hash matches and every one of its 353 regular extracted files is byte-identical to its archive member. No package installation or compilation was rerun. The storage-layout JSON records the genuine inherited Storage fields and agrees with the literal getter checks.

The harness does not test denied roles, pause/age/distance boundary combinations, maximum batch cardinality, all malformed witness shapes, root-call failures, SHA failure/short returndata, router failure/reentry, raw ABI memory behavior, final event ABI, uint32 timing horizons or full parent rollback/funding. These are coverage boundaries, not findings against this bounded witness-to-router-arguments test. The pending Lean consumer requires its own exact-candidate review.

## Frozen identities

- `/Users/thomas/work/lido/local-lido-proofs/audit/topup-gateway-witness-batch/solidity/TopupGatewayWitnessBatch.t.sol`: `feddd9ebdd11e9dc1d0eb0fdf4f3da59e5e059ad7c41aa022b9875af0a20dee5`
- `/tmp/lido-gateway-witness-solidity.log`: `e4bcbbddef7dbf39abbd737b990275d10178b3635d77542d5f769d336869bab4`
- `/tmp/lido-gateway-witness-storage-layout.json`: `6c917bd2c4f0054e19aaff69453703681e7c3597fea2766f2cb193127410325e`

Pinned source hashes:

- `contracts/0.8.25/TopUpGateway.sol`: `a7ffb654fb4d8d83ba14a6d9452663f786e9a21434be3ce9b7205c546526b7b4`
- `contracts/0.8.25/CLValidatorVerifier.sol`: `d6e89f6975e4fa02f758bf461a98ac2d689296b5c92d03ffd4e43a22d0b3d7ed`
- `contracts/common/lib/GIndex.sol`: `2653bd4ba89c349f3db36f21a8afc6a24e0e233816d9b608f46d048feb601d1f`
- `contracts/common/lib/SSZ.sol`: `91ef497b972bbee0fe89043034e6bd62fa0c1059f22874d4826bc6164a22009b`
- `contracts/common/lib/BLS.sol`: `0187cc6a6b1aaa833317695d88795db431fa237452213e8c3872a0f444dceb7c`
- `contracts/common/interfaces/TopUpWitness.sol`: `34135d561e4d8c3f1585cdbc15d20f568e36bb37db6c8d4444a8d0cd48cef44d`
- `contracts/common/interfaces/ValidatorWitness.sol`: `8fd24cfab7402233029756e52e59198b0d9cbf0a42e5c07d9fa2338ed731a5f7`
- `contracts/common/lib/WithdrawalCredentials.sol`: `cf5e77be0c5d522d853d19a4c5284e53fa0fb149a9902f77648a8f6d5584636c`
- `contracts/common/utils/PausableUntil.sol`: `f27405a7f52a15f7e1b10a73ae57ed69fe6514aaba821415e5584458546cf255`
- `contracts/openzeppelin/5.2/upgradeable/access/AccessControlUpgradeable.sol`: `d32578f73ad0a24f65d8208033226cc5567a9df2a57fabadf644f6e4e7f172a4`
- `contracts/openzeppelin/5.2/upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol`: `b6b854fdb69cfe58d7494f6cfc1920a68b504c32e97f6028b6d62a844bc17426`
- `contracts/openzeppelin/5.2/upgradeable/proxy/utils/Initializable.sol`: `a8b7eafa0fdc7cb5a644c8c61a8e4c51e031d5e1e6f268f72dbe18b768ead56e`

Final dossier receipt SHA256: `574d6521222d86653acce547434f03fc590c45510adab6775fe02b2870ed65b7`. README SHA256: `8c74af6f31c76dae043d3d13e77e5fe2eded57781660386a0a4e949f959b0f19`. The README explicitly retains the persistent-counter-versus-transient-call distinction raised during prereview. No unresolved finding remains in this bounded harness review.
