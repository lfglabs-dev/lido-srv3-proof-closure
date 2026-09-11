# Source and compiler correspondence

Core pin: `17005714f151e5502c559932319a3f2f74ac2436`. Existing complete caller artifact/assembly: `audit/account-physical-pause/Lido.asm`, byte-identical to accepted full37-input provider `ee24f9dc158ed25cec118a8ab8cd3a4fc59942f1`. All referenced caller code belongs to that complete compiled Lido, not a miniature replacement.

| Executed obligation | Complete relevant source and compiler path | New consumer |
| --- | --- | --- |
| Report, getter, checked fees before mint | Existing ReportFeeMint pure source stages; Accounting403–406 positive-fee guard | `collect`/`prepare`, then zero-fee guard in `execute` |
| Mint enters accounting lookup before auth/pause | Lido894–900; Lido.asm5646ff tag193 → tag466, return through tag393 to tag395, then tag556 → tag397 | CALL executes after preparation and before `finish` invokes mint |
| Accounting lookup | Lido1422–1427; assembly12045ff tag466 → tag538 → tag725 | `AccountingCall.call`, selecting actual source getter |
| Physical locator | Lido120–121/1557–1559; UnstructuredStorageExt.getLowUint160; assembly13222ff tag538 → tag1069 at16404 → SLOAD getter tag430 → shared AND tag1238 at15918 | `locatorPosition` = d92bc316…4be223; `locator` reduces the read word to low 160 |
| Request and code guard | Assembly14584ff tag725 constructs selector9624e83e, four input bytes, zero CALL value,32 output bytes, masks target, checks EXTCODESIZE; no-code reverts empty before call | physical request, `Environment.code` presence guard, no fictitious no-code attempt |
| CALL opcode and failure | Shared assembly4974ff tag501: GAS, CALL; failed call copies and bubbles complete returndatasize | attempt `isStatic=false`; source getter reply is consumed; generic rejected reply retains bubbled bytes |
| Legacy return validation | tag502 checks `RETURNDATASIZE < 32` with unsigned LT; tag503 MLOAD of output first word; no canonical high-bit rejection | `decodeAddress` applies unsigned word-size minimum, reads first 32 bytes, permits trailing data |
| Address cleanup and auth | Lido1394–1396; assembly10959ff tag395 masks returned address to low 160, compares CALLER and otherwise reverts APP_AUTH_FAILED | decoder's low 160 result is written to derived metadata and actual mint authorization derives caller equality |
| Real immutable getter | LidoLocator public immutable accounting and constructor assignment; fresh LidoLocator.asm1220ff nonpayable/minimum selector dispatch, selector at1312 → tag19 at1618 → immutable load → tag34 mask/MSTORE → tag36 exact32-byte RETURN | `getter` checks zero value and first four selector bytes, emits ABI encoding of typed immutable, returns unchanged World by executed body |
| Actual implementation/proxy relevance | scripts/scratch/0083-deploy-core.ts and0090-upgrade-locator.ts; complete OssifiableProxy + ERC1967Proxy/Upgrade + Proxy bodies retained; getter selector does not select any proxy admin function | effective deployment/code identity remains context; fresh fixture executes real upgradeable proxy and getter |
| Proxy forwarding evidence | Fresh OssifiableProxy.asm2014ff tag58 copies calldata, DELEGATECALLs selected implementation, copies return and returns/reverts exact bytes | exercised in Solidity; no Lean proxy/implementation-slot/constructor/upgrade theorem is claimed |
| Post-mint payments and treasury | Existing FeeDistribution.modules and ReportFeeTreasuryCall.distribute, followed by TreasuryCall's 0.8.9 STATICCALL on the actual post-module ACCOUNT World | unchanged actual distribution is called by `finish`; entire340/324 effects retained by replay theorem |
| Whole failure | Existing source transaction rollback plus new root wrapper | original incoming World restored, including both metadata fields and all report/payment writes |

## Caller/callee distinction

The CALL opcode is dictated by the original Lido solc 0.4.24 artifact even though ILidoLocator.accounting is declared view. It must not be replaced with the treasury caller's 0.8.9 STATICCALL semantics. The old decoder uses an unsigned minimum 32-byte check and address cleanup at use; it does not implement the newer canonical-address or signed head-size rejection. Literal Lean byte vectors and actual full-Lido raw-callee tests independently cover these differences.

The source-specialized getter always produces its actual canonical 32-byte return. Thus its successful decoder acceptance and immutable-value equality are derived; the public specialized CALL does not accept caller-injected arbitrary return bytes. Short/dirty/reverting/mutable auxiliary callees test the compiler caller fragment outside that source-specialized guarantee. In particular the mutable-callee test succeeds and retains its SSTORE on a successful CALL: the proof makes no assertion that arbitrary CALLs preserve the World.

The target-code table represents effective code at the physical address. The deployment's proxy/implementation/configuration identity and successful constructor remain explicit boundary inputs. The current physical locator low 160 read is executed inside the new consumer; it is not replaced by a supplied immutable locator. Source getter World preservation is a theorem about its body, not an environment frame premise.

## Memory and resource scope

For this fixed return, the old caller sets CALL output size 32 and then loads that first word only after the unsigned minimum-return check. Earlier memory layout, the free-memory pointer, copying provenance, memory expansion/resource failure and full instruction refinement retain the accepted ABI/memory/gas boundary stated in `audit/address-steth-quote-call/README.md` and `audit/account-treasury-call/README.md`. The Lean decoder projects host raw length to uint256 before its unsigned test; no new host-length bound is assumed. There is no dual-dynamic-array allocation or new free-memory allocation guard in this caller branch to replace with an invented pointer condition.

The fresh getter's return path is the simple immutable/mask/MSTORE/32-byte RETURN sequence, with nonpayable and selector dispatch accounted for. Constructor checks and proxy dispatch are covered as fixture source evidence, not added formal execution claims. Production compiler profile, deployed bytecode identity and universal memory/resource success are not inferred from diagnostic test passes.
