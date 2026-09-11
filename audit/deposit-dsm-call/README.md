# Actual DSM STATICCALL before physical DEPOSIT admission

Additive source lot from main `9383467fe19c621cc5c37ea54e1d5585b9ba49ee`, core pin `17005714f151e5502c559932319a3f2f74ac2436`. The new runner obtains DSM through the actual modeled locator STATICCALL, decodes its canonical address, places that result into the context used by accepted ##326 physical admission, then executes the unchanged module/metadata/withdrawal/beacon consumer on the same World. Its success theorem retains **all** `DepositPhysicalAdmission.Effects` on the same Commitment; it adds the actual locator response, canonical address, static observation and equality of caller with that decoded DSM. No successful lookup/stage, supplied DSM, hcfg, hash injectivity, nonalias or funding premise is required.

The inherited Context type still contains a `depositSecurityModule` field for compatibility, but `resolvedContext` overwrites it with the executed response. The successful regression supplies 999 while the actual locator response is 7; false/none supplied physical fields are likewise replaced by #326. The positive regression transports through #326's actual positive module/withdrawal/beacon execution, preserving its suffix result rather than assuming one. Early rejection and late rejection after physical metadata have public whole-entry rollback instances.

## Exact source and compiler behavior

The source correspondence is StakingRouter.sol `deposit` at 943 and `_getDepositSecurityModule` at 1173–1175, including inherited `_checkAppAuth` at 1177. Full inherited router source and its 27 core/OpenZeppelin dependencies are vendored unchanged from #326 and hash checked. The fixture inherits the actual router and invokes its actual getter, authorization, registry and credential helpers. It does not replace the getter with an invented equivalent or execute the whole deposit transaction.

Fresh full inherited DsmHarness IR, solc 0.8.25, viaIR, optimizer 200, Cancun:

- `fun_deposit` calls `fun_checkAppAuth(fun_getDepositSecurityModule())` before membership/status.
- The getter executes `staticcall(gas(), LIDO_LOCATOR, buffer,4,buffer,32)` without a code-size precheck. Selector is `0x472c1776`, independently checked by `cast sig 'depositSecurityModule()'`. The request uses the router as caller, locator as target and zero value.
- A failed static call bubbles returndata before decoder/auth. `StaticCall.External` exposes no writable result World; `.forbiddenStateChange` is an actual failed call, not a successful mutation subsequently erased.
- On success, the compiler takes `min(32,returndatasize)`, runs `finalize_allocation` first, then checks the signed head-size subtraction and canonical address high 96 bits. The new decoder uses the accepted scalar wrapping allocator. After its success the cursor/copied range is small and nonwrapping, so the length test is precisely the 32-byte bound. High bits reject rather than silently truncate. Zero is a valid decoded address; authorization decides whether it matches. Trailing bytes are ignored.
- Ordinary no-code targets return empty successfully in the inherited low-level static model, then the decoder rejects. This is deliberately not the older 0.8.9 `StaticCall.call` code-checking discipline. Precompile dispatch remains outside the inherited ordinary-no-code model arm.

The DSM `cursor` and later `ModuleCall.Input.returnBuffer` are **separate phase inputs**. The positive fixture uses 128 and 512. No equality, next-pointer connection or full-memory continuity is claimed: getDepositableEther/ALLOC and their allocations are still omitted. Scalar guards are executed; memory expansion/copy/gas correctness remains a boundary. EVM returndata size is represented by the uint256 projection of the host list length, consistently with the old module decoder.

## Effects and remaining boundaries

The typed `locatorAttempts : List Live.NestedAttempt` preserves `isStatic=true`. The existing `attempts : List Live.Attempt` is exactly the old module/suffix journal. These are deliberately separate observations because old Live.Attempt has no static flag. The program runs lookup and decoder first; only `.ok dsm` invokes physical admission. It passes the identical entry World, as the static reply has no resulting World. This is not a claim that the two lists form a complete unified EVM trace, nor that arbitrary nested locator subcalls are recorded by the existing StaticCall.External type.

The full old physical-admission Commitment still uses entry-selected WC and module data, consumes the module-returned World for physical metadata, then performs the old withdrawal/beacon suffix. Outer execute restores the complete entry World on any error, including late failures, while retaining static/module/suffix observations.

Constructor locator identity, caller/context/contract identities, selected allocation, separate phase-memory origins, omitted getDepositableEther/ALLOC and preservation of captured values across that omitted prelude remain open. Actual WC/module address are captured before those calls and cap afterward. This increment closes the *supplied DSM address* boundary in the adapter, not the whole source entrypoint. Constructor maxEB is not universally 32 ETH; fixed 32 ETH beacon calls, linked-library deployment identities, arbitrary external interpreter/environment, natural ETH ledger, semantic logs/errors, opaque Keccak/SHA, runtime/gas and calldata/memory boundaries remain #326's explicit limits. No old source/AllGuarantees/Trust wiring is changed here.

## Validation and the tracing discrepancy

- `lake build LidoSRv3.Tests.DepositDsmCall`: 1331 jobs, exit0. Final tests actively compiled in 3.1 seconds; source/public were already successfully compiled in this lot and accepted from current cache. This is not a fresh entire-dependency rebuild. Earlier build/parser errors and an earlier successful build are archived in development.log.
- 20 executable kernel examples, plus kernel late-outcome theorem, positive execution transport and three public instances (positive, early rollback, late rollback). No new native_decide, sorry or project axiom. Six freshly recomputed active scopes contain only foundations; rollback/lookup scopes use propext/Quot.sound.
- `validate.py` passes 1314 imported/new source identities, 11 pins and 6 active axiom sets, checking every consumed old local source against 9383 and selected local cached artifact bytes. It **writes** source-inputs.json and axioms.json; read-only reviewers should inspect it and intercept/redirect those writes rather than mutate the frozen checkout.
- Normal Forge suite: 9 tests pass, including two 1024-run fuzz tests, all 32 short lengths, canonical zero, noncanonical high bits, arbitrary trailing bytes, actual caller/selector, actual physical WC, and forbidden SSTORE. The 27 vendor inputs match326; all 28 actual harness compiler metadata source Keccak identities were independently checked. This is a fixture compiler profile, not deployed bytecode identity.
- An additional `forge test --root audit/deposit-dsm-call/solidity --match-test testNoCodeSuccessThenDecoderRejection -vvvv` **FAILS** the test's exact empty-returndata assertion. `no-code-trace.log` records a nested locator STATICCALL ending `[Stop]`, followed by a router revert described as `call to non-contract address`. The same unchanged artifacts under `-vv` immediately pass the exactbytes assertion (`no-code-check.log`). This is a tracing-mode discrepancy and must be examined by independent review, not silently counted as green. The attribution to Foundry diagnostics is an inference from the unchanged artifacts and verbosity-only difference. Credit no-code call ordering to full IR plus the observed Stop/revert trace, and normal exactbytes only to the nontracing test; there is no unconditional all-modes Solidity exactbytes claim.
- Fresh full optimized IR is preserved byte-for-byte, including its compiler stdout blank EOF. Any sole new blank EOF diff-check finding is an explicitly retained raw-output exception, not an unconditional diff-check PASS.

Reproduce from repository root:

```sh
lake build LidoSRv3.Tests.DepositDsmCall
PYTHONDONTWRITEBYTECODE=1 python3 audit/deposit-dsm-call/validate.py
forge test --root audit/deposit-dsm-call/solidity --fuzz-seed 0x20260911 -vv
forge inspect --root audit/deposit-dsm-call/solidity DsmHarness irOptimized
```

Source lot is for independent exact-source review before integration. No merge, site change, deployment or publication is included.
