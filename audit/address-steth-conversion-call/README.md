# ADDRESS physical reverse-conversion consumer

Author candidate; requires independent exact-source review. Exact parent `ee24f9dc158ed25cec118a8ab8cd3a4fc59942f1`. Only three new Lean modules and this dossier are added. The previous quote lot is unchanged.

## Consumed result

`AddressStETHConversionCalls.conversion` replaces the remaining reverse-conversion StaticExternal in the actual WstETH unwrap executor used by the full wrapped permit batch runner. It executes the body against `req.target` and the supplied actual World. The canonical request theorem proves selector `7a28fb88`, one full uint256 word, zero value, 36-byte transport, decoding of the actual amount, and encoding of the concrete result. It is not an unused encoder or a supplied successful reply.

The target is the low160 address decoded by accepted `AddressWrappedTokenCalls.stETHAddress` from **qualified WstETH slot7 on the actual preburn World**. This world is after that item's actual transferFrom and outer unwrap zero-value transfer, before burn. The old TokenEffect is retained in full and binds the same received value to the burn sequence, fresh slot7 reread for mutable stETH.transfer, its amount payload, returned captured value, queue amount guards, forward quote and enqueue. The new Item additionally retains the full enhanced ee24 WrappedItem and explicitly ties the same `received`, transferred/unwrapped worlds and journals to the derived reverse and forward formulas. Different targets and rates are permitted; no frame/nonalias invariant appears.

Public `actual_wrapped_physical_conversion_permit_batch` retains the exact entire ee24 public conclusion as `PhysicalQuotePermitEffect`: the complete accepted permit JoinedEffect **and** enhanced physical-forward-quote Transcript, same IDs, worlds and attempts. It then adds a Transcript of the stronger conversion Items on those same per-item worlds. The root failure theorem retains whole-entry rollback including permit and earlier successful items. The old arbitrary-conversion theorems/domains are untouched.

## Pinned body and compiler order

Core pin `17005714f151e5502c559932319a3f2f74ac2436`, `contracts/0.4.24/StETH.sol:329–334`:

```
require(_sharesAmount < UINT128_MAX, "SHARES_TOO_LARGE");
return (_sharesAmount * _getShareRateNumerator()) / _getShareRateDenominator();
```

The actual overriding helpers are `Lido.sol:1271–1277,1298–1307,1481–1483,1495–1497,1539–1541`. Existing ee24 `internalEther` and `internalShares` are reused without a physical-storage adapter. All low/high128 fields come from actual qualified Word reads:

| Slot | Low128 | High128 |
|---|---|---|
| `6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6` | total shares T | external shares E |
| `81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f` | buffered ether B | deposited post report D |
| `096e465397f38e659238ccd5d5a2c434ced54a63fd8d694045bfb058ab9d8112` | CL validators V | CL pending P |

`I=B+V+P+D`, `S=(T+2^256-E)%2^256`, result `((amount*I)%2^256)/S`. The consumed old width lemma derives I<2^130 and excludes all three SafeMath addition overflows without a totals premise. Raw SUB and MUL wrap. Strict `<2^128-1` is preserved, not relaxed to <=. S=0 is INVALID/empty outward failure, including amount0; I=0 with S!=0 returns0. Underflow T<E and oversized output are admitted. There is no inverse/rate-roundtrip identity claim.

**Reverse getter order differs from the forward quote.** Full unmodified `audit/address-steth-quote-call/Lido.asm`, lines7048–7105, tag651→652 calls denominator380/internalShares first, then numerator378/internalEther. It then jumps to shared tag461 (lines4352–4372): MUL, zero check, INVALID, DIV. Within internalEther, buffered1203 precedes CL528, then the three SafeMath adds. Parent's initial provisional “internalEther first” wording was corrected from this complete assembly before implementation and explicitly acknowledged; no premise or theorem domain was changed. Since these are pure bounded reads, no arbitrary read callback is introduced to make getter order observably different. Strict-width rejection before zero-divisor failure is tested.

Complete helpers/physical operations in that same full assembly: denominator380→shares890→packed1058→SLOAD430; buffered1203 and CL528 use the same packed getter; low mask128 and high division2^128 at tag1058. Actual literals/data constants and their keccak preimages were checked in ee24; all 111 original receipt hashes are revalidated by `check-evidence.py`, as are exact Git provider bytes. No stale conceptual totalSupply or totalPooledEther interpretation is substituted.

The complete actual WstETH0.6.12 source/assembly are reused at `audit/address-wrapped-token-call/solidity/token/src/core/WstETH.sol:67–73` and `.../WstETH.asm:2924–3179`, tag114. Positive unwrap guard, SLOAD7/uint160 cleanup, 36-byte canonical STATICCALL with EXTCODESIZE guard, failure bubbling, >=32-byte returndata decoder and returned amount capture occur before burn208. Slot7 is reread after burn for the 68-byte stETH.transfer CALL. Its decoded return value is discarded. No same-target assumption replaces either read. OZ burn's actual balance→fresh supply sequence remains the accepted implementation.

## Source/compiler evidence and fixtures

All 37 original full Lido source inputs are copied byte-identically from ee24 and bound to its original core/npm source identities. A fresh 38-input compilation is justified by the **new** `ConversionHarness.sol`: it inherits full Lido and overrides only mutable transfer to invoke an explicit controller hook. It never overrides either quote/conversion or their physical rate helpers. `ConversionHarness.asm` and compiler artifact contain the complete new legacy assembly; metadata source keccaks are checked for every input. Profile: solc0.4.24+e67f0147, optimizer200, Byzantium. Original compiler warnings, including SHR in unrelated ECDSA code under Byzantium, are retained; no Lido signature-body correctness is claimed.

Direct reverse tests deploy the exact unmodified Lido artifact retained from ee24. WstETH0.6.12 deployment artifact is also reused byte-for-byte. Queue source bodies and solc0.8.9+e5eed63a optimizer200 London runtime objects/metadata are unchanged; the new0.8.9 test fixture justifies its compilation. Complete prior Lido, WstETH and queue assemblies are reused only after exact identity checks, without gratuitous rebuilds of those old projects.

The composed Solidity fixture constructs the queue with underlying targetQ, then explicitly changes WstETH slot7 to targetA with high-bit junk. All three are actual Lido-derived instances. A mutable transfer controller uses explicit Foundry storage hooks to model the arbitrary mutable-world boundary: after item1 it switches slot7 to targetB and changes targetQ's physical rate. This is **not** a theorem or claim that actual Lido.transfer implements such writes. Item1 converts7→700 at targetA; item2 converts8→1600 at targetB; queue targetQ independently quotes3 and4 shares after callbacks. Real WstETH signature/nonce/allowance implementation is exercised in these tests but remains an external permit-body boundary in Lean.

## Results and limits

- `source-build.log`, `public-build.log`, `test-build.log`: normal builds PASS, final1278 jobs. Sixteen `decide +kernel` regressions cover canonical bytes, packed words, strict max, zero/raw-wrap/overflow, target qualification, address cleanup, and conversion-before-burn error priority. Two public kernel instances: empty successful complete effect and paused root rollback. Nonempty positive composed runs are native/Solidity diagnostics, not mislabeled kernel instances.
- `validation.log`: 1261 actual imported/new source identities, 11 pinned packages, nine fresh ordinary scoped axiom sets. Only propext/Classical.choice/Quot.sound; old consumed local sources and normal selected oleans match exact source provider. No new axiom/admit/native_decide or supplied success-stage premise.
- `native.log`: four fresh FFI diagnostics PASS: actual dynamic targets/rates and captured700/1600 outputs/3/4 enqueue shares; later reverse INVALID restores permit, earlier item, slot7 and storage; capturedzero follows actual queue guard; selected no-code target triggers actual wrapper code guard and root rollback. Keccak diagnostics are separate from kernel evidence.
- `solidity-test.log`: 11 real Solidity tests PASS, including1024 full-Lido reverse fuzz inputs, exact boundary/error bytes, raw multiplication/subtraction, oversized return, different target/rate callback composition, and later INVALID rollback of real permit nonce/allowance, supply/balance, earlier IDs, target/rate writes. No full-suite failure was encountered in this lot.
- `compiler-check.log` / `compiler-identities.json`: exact111 parent receipt hashes,37 original inputs,38 fresh fixture inputs, compiler metadata source keccaks, unchanged queue executable objects/metadata, actual deployment and full assembly identities.

The model retains the accepted typed-list/typed-call ABI, memory and gas boundaries. It does not prove generic malformed dispatch, arbitrary memory continuity, gas exhaustion, complete bytecode refinement, or a unified low-level EVM instruction trace. INVALID is represented as outward `.bubbled []`; consumed subcall gas and distinction from other empty failure categories are outside that semantic abstraction. The target-specific body interpreter is the declared implementation specialization for the actual selected request; runtime bytecode recognition is not added. Constructor identities/context, arbitrary mutable permit/transfer replies and nested journals retain their existing boundaries. Full successful body evidence does not authenticate permit signatures. Address0 keeps the accepted Live storage convention.

Raw generated assembly bytes retain the compiler CLI EOF blank line. Receipt records raw diff-check exception separately from filtered PASS. Reused old raw assembly exceptions are identified by their hashes; no claim that their raw diff checks passed is made.
