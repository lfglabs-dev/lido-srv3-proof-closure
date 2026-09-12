# PR #287 independent exact-source review (READ-ONLY)

**Repo:** lfglabs-dev/lido-srv3-proof-closure
**PR:** #287 DRAFT
**Mode:** writer=false. Inspect only. No merge, push, comments, source edits, site, or deploy.
**No Cerebras. No full rebuild.**
**Host path `/var/lib/hermes-assistant`:** not searched (previous attempt 49c00b83 failed because it is not mounted). No invented bodies.

## Identity

| Item | Value |
|---|---|
| Isolated HEAD (`git rev-parse HEAD`) | `80e21927d68f9522d3016418319ca543cecb5072` |
| Parent / claimed base | `9c5b239b2d93cea0b8917de220550f01dded4f24` |
| Fetch | `origin pull/287/head` succeeded; both commits present as objects |
| Solidity pin (`lidofinance/core`) | `17005714f151e5502c559932319a3f2f74ac2436` |
| In-repo `lido-core` | empty submodule pointer; pin read from vendor clone at that commit (complete files) |
| 1489-identity receipt | **ABSENT** in this PR tree (`docs/1489-identity.md` not present; no `*1489*` files). **Not reused. Not host-cached. Not invented.** |
| In-repo top-up receipt | `audit/topup-router-committed/receipt.json` **FRESH this review** (SHA256 below). Independently hashed vendor pin files **MATCH** receipt `validated_inputs` for all eight `lido-core/...` Solidity paths. 73/81 other `validated_inputs` match disk in this clone; the 8 misses are the uninitialized submodule paths, recovered via vendor pin. mismatch=0. |

PR diff vs parent (10 files, all Added):

- `LidoSRv3/Audit/Source/TopupRouterCommitted.lean`
- `LidoSRv3/Tests/TopupRouterCommittedMutants.lean`
- `audit/topup-router-committed/README.md`
- `audit/topup-router-committed/check_receipt.py`
- `audit/topup-router-committed/dependency-inputs.json`
- `audit/topup-router-committed/failed-positive-branch-diagnostic.log`
- `audit/topup-router-committed/inherited-validation.json`
- `audit/topup-router-committed/receipt.json`
- `audit/topup-router-committed/source-validation.log`
- `audit/topup-router-committed/validation.log`

Receipt `integration_base` = parent `9c5b239b2d93cea0b8917de220550f01dded4f24`. Receipt `source_pin` = `17005714f151e5502c559932319a3f2f74ac2436`. Receipt `goal` = `all eight complete guarantees OPEN`. Receipt `independent_review` = pending (this document).

### Pin SHA256 (complete files at `17005714`, independently hashed this session)

```
4d5b83fc73736db6755ebbb58811ed499c3e6de622cce11a3ad8548800a34155  55709  contracts/0.8.25/sr/StakingRouter.sol
b4afeac2e4dab53d2b6d1cebcf41bfc670eb1ea069cb1d5bc0e07f1932bf9fe0   6296  contracts/0.8.25/lib/BeaconChainDepositor.sol
2a8db249155e8502e1132f14410b8d7b2a924512723ed07a08167477d8f8c073   9425  contracts/0.6.11/deposit_contract.sol
eacc19c668dd2ad94c7c0cffc5957181b8bf1ed2321c14c34c9845ea054a64ce   1511  contracts/common/interfaces/IStakingModuleV2.sol
3bf84b96fb155af2290e6b26bc0138de356442a9abe3ea0f5274497f9fbffc10  70838  contracts/0.4.24/Lido.sol
d7b36c2de36cfc68a3fa0812add4e9c55879188a08317166a0ab0f63baaffc63    536  contracts/common/interfaces/IDepositContract.sol
62e922f76a1db7756684d73db3151a02f6d8f0de51fac27922f0a4095ceb9d95   2842  contracts/0.8.25/sr/SRStorage.sol
22c28be7ceaf6ed841f18fc19296372ab246b1cfecc87902d49ee1670ed4aed6  13237  contracts/0.8.25/sr/SRTypes.sol
083ac5688804237329e50e4c966cae6b782bd9000f092a9740ddb738f234ea2a   2818  contracts/common/interfaces/ILido.sol
```

These eight `lido-core/...` receipt hashes equal the vendor pin hashes above. FRESH match. Not a cached 1489 table.

### PR / producer Lean SHA256 (this HEAD)

```
444c2b43d16a3b17996068a5dbdf203ac432478ace2cd4ad413af60b4784165f   9561  LidoSRv3/Audit/Source/TopupRouterCommitted.lean
5a373f9b95db6c9dadb94636d1681e24c553a7c02f26ad295339a85652df4d67   4832  LidoSRv3/Tests/TopupRouterCommittedMutants.lean
ebd2ab400e38891186aa298d84b860e20dd157e917219257c2888ccd9fd379d1  11668  LidoSRv3/Audit/Source/TopupModuleCall.lean
496ba9905f6b5b42c854a58f88f4dbe6ea5849a4de12aba6ebb776fc642104da  21853  LidoSRv3/Audit/Source/TopupRouterContinuation.lean
8cfa6ab58d9fb1f6ef558c3f0b8a6b8dd4897d3740e5c09d445c7e14ad02f54a  17871  LidoSRv3/Audit/Source/TopupBeaconCommitted.lean
142c68fce97927bce27ce777f9d075fa04f4b4a2801fc765540f68fa00491d01  86138  LidoSRv3/Audit/Verity/TopupTx.lean
5d8f8c0d8819ea69837d111abb579ea47d4b43dcaed0f69b866c6de2b3355980  13100  audit/topup-router-committed/receipt.json
9e193741430793dcc72d4b8a36648125e89e08c86300d18ffb225f97af9cc4c2   3984  audit/topup-router-committed/README.md
```

`TopupModuleCall.lean` SHA256 also equals inherited-validation.json identity check `ebd2ab400e38891186aa298d84b860e20dd157e917219257c2888ccd9fd379d1`. Continuation and TopupTx match inherited identity checks.

Surface of this increment is **StakingRouter.topUp** at pin `StakingRouter.sol:717–758` (after rounded-target preamble), **not** V3 Accountant / VaultHub / StETH.

## Composition (producer bytes → encoding bounds → consumer payload/value)

Assessed from complete Lean + complete pin Solidity, not from compile logs.

### Producer bytes

Pin `StakingRouter.sol:717–718`:

```
IStakingModuleV2(stateConfig.moduleAddress)
  .allocateDeposits(smDepositableEthAmountRounded, _pubkeys, _keyIndices, _operatorIds, _topUpLimits);
```

No `{value:}` on that CALL. Interface `IStakingModuleV2.allocateDeposits(uint256,bytes[],uint256[],uint256[],uint256[])` returns `uint256[] allocations`.

Lean producer (`TopupModuleCall`):

- `moduleAddress` = `Address.ofNat` of ERC-7201 config word (`% 2^160`). `address_packed` under `address < 2^160`.
- `typedCall` maps roundedTarget / pubkeys / keyIndices / operatorIds / limits; WC/type/returndata left empty (unused by encoder).
- `payload i = TopupBeaconEffects.serialize (allocateCalldata (typedCall i))`.
- `allocateCalldata` (`TopupTx.lean:1408–1421`): selector word + five-arg ABI head/offsets/tails for those five arguments at `StakingRouter.sol:717-718`.
- `serialize`: first word as **4** bytes, remaining words as 32-byte ABI words.
- `call` = `CallData.invoke ... payload (word 0)` — **value 0**.
- Independently computed keccak256(`allocateDeposits(uint256,bytes[],uint256[],uint256[],uint256[])`) selector prefix = **`783b8a65`**, matching `allocateDepositsSelector = 0x783b8a65`.

This is the producer byte path. It is not a universal compiler-encoder theorem (OPEN 3).

### Encoding bounds

`decodeReturn` (logical ABI word-array reader):

- `length < 32` → `.empty`
- `offset ≥ 2^64` → `.empty`
- `offset+32 > length` → `.empty`
- `count ≥ 2^64` → `Panic(0x41)`
- extent `offset + 32 + 32*count > length` → `.empty`
- else `readWords count (drop (offset+32))`

Proved: `encodeWords_length`, `readWords_encoded`, `decodeReturn_encoded` (canonical `offset=32` + arbitrary tail, `length < 2^64`). Canonical roundtrip does **not** certify compiler memory allocation failures. Retained prior discrepancy (PR283, not re-kernelled): Solidity `count=2^59` Panic 41 vs Lean `.empty`. **OPEN 4.**

`program` binds: module CALL → decodeReturn → `TopupRouterContinuation.program` on `continuationInput i allocations` and the **module-returned World**. `program_success_origin` derives raw reply + decode from success; no reply field on Input.

### Consumer payload / value

Pin after decode (`StakingRouter.sol:721–758`):

- Unchecked loop: gwei alignment, `allocations[i] > _topUpLimits[i]`, wrapped sum `amount`.
- `amount > smDepositableEthAmountRounded` → `ModuleReturnExceedTarget`.
- `amount > 0`: `LIDO.withdrawDepositableEther(amount, 0)` then `BeaconChainDepositor.makeBeaconChainTopUp(DEPOSIT_CONTRACT, wcBytes, _pubkeys, allocations)` then assert router ETH unchanged; else skip.
- Always `emit StakingRouterETHTopUp(_stakingModuleId, amount)`.

Pin callees:

- `Lido.sol:869–885` `withdrawDepositableEther(_amount, _seedDepositsCount)` with seed 0 on top-up; value `_amount` to `receiveDepositableEther`.
- `BeaconChainDepositor.sol:66–107` `makeBeaconChainTopUp`: empty keys return; length mismatch revert; skip zero amounts; `deposit{value: amount}`.

Lean consumer (`TopupRouterContinuation.program`):

- `guardSum` = alignment then limits-index (`Panic(0x32)` if short limits) then `AllocationExceedsLimit` then `(acc+a) % 2^256`.
- `total > roundedTarget` → `ModuleReturnExceedTarget`.
- `total = 0` → event-only, no withdrawal/helper.
- else `Live.run (TopupLiveWithdrawal.suffix callee ctx (word total))` then `helper` then `finish` (router balance restored vs pre-suffix, else `Panic(0x01)`).
- Withdrawal suffix: skip if amount 0; else `withdrawDepositableEther ... amount (word 0)` — **value = total**.
- Helper: empty pubkeys early-return (source line 73); else length check then beacon loop. `helperAmount`/`helperCount` are 0 on empty keys; else `allocSum` / `nonzeroCount` of allocations (mathematical sum, not the wrapped guard total). README states this theorem alone does not equate the two sums.

`TopupRouterCommitted`:

- `continuation_success`: success of existing continuation ⇒ executed `guardSum` total, `total ≤ roundedTarget`, and either zero-event world or `PositiveEffects` (actual withdrawal + helper, helper ledger vs post-withdrawal world, physical countSlot increment, concatenated attempts, router event). **No funding, initial-capacity, input-length, or amount-admission premise.**
- `execute_success_program`: `Live.run` success ⇒ raw program result.
- `module_execute_success`: success of **complete existing** `TopupModuleCall.execute` ⇒ real module request, raw bytes, `decodeReturn`, guard total/target, and the same continuation effects on the **module-returned** World. **No module reply or later world is an input premise.**

New files: no `sorry` / `admit` / `axiom` decls. `#print axioms` only on the three theorems. Mutants: empty-key amount/count 0; 3 ETH positive branch not discharged via zero disjunction; arbitrary module may change router balance 7→12 with zero allocations; malformed reply rolls back.

Solidity tests: `fresh_run: false`; inherited module-ABI / beacon tests only. Not new full-router EVM execution. Not used as closure.

## Premises vs displayed claims

Displayed (headers, README, receipt `scope`/`goal`, theorem comments):

- Necessary effects of **existing** router/module execution on committed runs.
- Arbitrary module and withdrawal interpreters remain parameters.
- Physical preservation of those interpreters and omitted router preamble remain obligations.
- Adapter starts **after** rounded-target preamble (`StakingRouter.sol:717–758`).
- Not compiler ABI/memory/gas equivalence; not pre-module conservation; not complete TOPUP.
- Receipt goal: **all eight complete guarantees OPEN**.

STATUS.md still lists `P-TOPUP-1` / `P-TOPUP-2` Abstract/Verity **CHECKED** with classification **IMPLEMENTATION_PENDING**. Fidelity: beacon-address provenance **OPEN** as `A-TOPUP-BEACON-ADDRESS`; `_verifyValidator` / 0x02 WC / block-distance / live wei conversion / allocateDeposits policy / withdraw / makeBeaconChainTopUp / gwei vs wei / 48-byte pubkeys / keccak oracle / `pendingBalanceGwei` remain named gaps. Metadata does not close P-TOPUP (`guarantees.yaml`: Lean statements are authority; metadata never closes evidence).

Theorems do **not** claim those closures. CHECKED rows are classification, not this increment’s theorem.

No overclaim found relative to the scoped composition.

## P-TOPUP remains OPEN

`P-TOPUP` / `P-TOPUP-1` / `P-TOPUP-2` are **not** closed by this PR or this review.

## All eight OPEN (assessed, not hidden)

1. **Parent ABI / auth / registration / rounded-target preamble** — starts at `StakingRouter.sol:717` after preamble. Typed inputs, not a proved `topUp` ABI decode. **OPEN.**
2. **Arbitrary callee** — no module implementation, no callback restriction, no pre-module conservation. Zero-allocation fixture may change router balance. **OPEN.**
3. **Payload encoder** — reused word encoder + prior finite vectors. Not a universal compiler encoder theorem. Selector agreed by independent keccak of the pinned signature, not a keccak proof inside this increment. **OPEN.**
4. **Logical decoder vs compiler alloc/gas** — `2^59` short return: compiler Panic 41 vs Lean `.empty` (retained). `count ≥ 2^64` Panic 41 matches the separate guard. **OPEN.**
5. **No-code traces** — Live early `codeSize` ⇒ no attempt; 0.8.25 typed CALL attempts then decoder-fails. Outcome-only failure agrees; origin derives positive-code on success. **OPEN.**
6. **`Live.run` rollback** — model rule, not an EVM/X revert-ABI theorem. **OPEN.**
7. **Beacon address, hash correctness, runtime provenance, aggregate history** — `A-TOPUP-BEACON-ADDRESS` and related assumptions remain. **OPEN.**
8. **Complete TOPUP / P-TOPUP** — **OPEN.** Do not treat this increment as closing them.

Inherited Solidity is not full-router fidelity credit. SHA / deployed-root context remain external trust. Guard wrapped sum vs helper `allocSum` equality is not proved here (`A-TOPUP-NOWRAP`).

## What this increment does prove (scoped)

On success of the existing module executor: producer CALL bytes (selector `783b8a65`, five-arg ABI, value 0) occurred; raw reply decoded under the stated uint64/extent bounds; decoded allocations and module World entered the existing continuation; continuation success yields executed guard total ≤ rounded target and either the zero event or the positive withdrawal (**value = total**, seed 0) plus helper effects relative to the **post-withdrawal** World.

That matches pin `717–758` at the stated abstraction. It is not compile-only: producer, bounds, and consumer value/payload were read against complete pin files.

## Severities

| Sev | Item |
|---|---|
| Critical | None found in this increment’s stated composition claim |
| High | None in-scope. **P-TOPUP remains OPEN** (program-level, not a hole in `module_execute_success`) |
| Medium | All eight unfinished guarantees OPEN (listed). No compiler equivalence. No pre-module conservation. Wrapped `guardSum` ≠ helper `allocSum` not proved. Decoder/gas split retained. Live vs typed-call no-code traces. `Live.run` ≠ EVM rollback. Beacon/runtime provenance OPEN |
| Low | In-clone `lido-core` submodule empty (pin recovered from vendor; hashes match). 1489-identity.md absent (recorded, not blocking). Solidity `fresh_run: false`. Receipt `independent_review` was pending. No kernel rebuild this review (ordered) |

**Not claimed, not granted:** compiler equivalence, preamble/auth, universal ABI encoder, EVM rollback, keccak/SHA functional correctness, beacon identity, runtime provenance, full TOPUP / P-TOPUP.

DRAFT. Integration still requires the eight OPENs, not this review, to close.

VERDICT: CLEAN
