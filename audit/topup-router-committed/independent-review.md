# PR #287 independent exact-source review

Reviewer: sole PR287 independent reviewer (this session).
Capability: READ-ONLY. No merge, push, comments, source edits, site, or deploy.
No Cerebras. No full rebuild. No host-path search (`/var/lib/hermes-assistant` not used).
Writer STOPPED at frozen head. Duplicate `49c00b83` INFRA_BLOCKED is **not** a technical verdict.

## Verdict

**VERDICT: CLEAN**

Exact defects vs pin `17005714` on `TopupRouterCommitted` composition: **none**.
`P-TOPUP` remains **OPEN**. All eight complete-guarantee boundaries remain **OPEN**.
STATUS `CHECKED` / Verity `CHECKED` does not close those boundaries.

## Frozen identity (verified before reads)

| Ref | SHA |
|---|---|
| PR head `git rev-parse HEAD` | `80e21927d68f9522d3016418319ca543cecb5072` |
| Parent / base | `9c5b239b2d93cea0b8917de220550f01dded4f24` |
| Solidity pin `lido-core` gitlink + vendor HEAD | `17005714f151e5502c559932319a3f2f74ac2436` |
| Subject | `Prove committed module-to-router beacon effects` |

Fetch of `origin pull/287/head` succeeded in this workspace. HEAD matched the frozen SHA before source reads. Parent fetched and diffed.

`git diff --stat 9c5b239b..80e21927`: 10 files, 8277 insertions, PR-local only:

- `LidoSRv3/Audit/Source/TopupRouterCommitted.lean` (+156)
- `LidoSRv3/Tests/TopupRouterCommittedMutants.lean` (+84)
- `audit/topup-router-committed/{README.md,check_receipt.py,dependency-inputs.json,failed-positive-branch-diagnostic.log,inherited-validation.json,receipt.json,source-validation.log,validation.log}`

Source 286 dependency already merged `51cf7e70` (base 9c / docd5 reviews complete). This increment is committed-module composition on that base.

In-repo `lido-core` is an empty submodule working tree with gitlink `160000 commit 17005714f151e5502c559932319a3f2f74ac2436` (`url = https://github.com/lidofinance/core.git`). Pin bodies were read as complete files from vendor `/workspaces/mission-a8310864/temp/lido-core-pin/` at that commit **and** from packet `lido-core/`.

## 1489-identity (source identity first)

`docs/1489-identity.md` is **absent** from:

- git tree at `80e21927` (`git ls-files` has zero `1489` paths)
- review packet
- checkout working tree

Record: **not FRESH, not cached, not reused, not invented.** Reuse of 1489 identity is therefore not performed. Accounting.sol 209-byte mismatch from a prior Accountant pass is **not** a finding for this PR.

## Packet (141 content files + wrapper)

Physical packet (same a582 workspace, no host-path dependency):

- dir: `/tmp/lido-topup287-review-80e21927/topup287-review-packet/`
- parent `archive.b64` SHA256 `d262910e21ba286030885458fa8b1856dc9b743e7f2b58eb160407654c054967`
- `packet.tar` SHA256 `3910748a5b5902f22244dca08ab46430f2d794de2a119cfa06e71d4e7d2c47e8` (matches stated tar SHA)
- on-disk files under packet dir: **142**
- content files excluding packet `manifest.json`: **141**

Packet vs git HEAD `80e21927`:

- **132** packet paths exist in the git checkout and SHA256-match HEAD (0 hash mismatches).
- **10** packet paths are not present as git working-tree files.

### Nine git-missing vendor pin Solidity files (empty `lido-core`)

These are packet-only because the in-repo submodule pointer is empty. They are **not** tracked-source mismatches. Independently hashed against pin `17005714`; all nine MATCH:

| Packet path | size | SHA256 (packet = pin) |
|---|---:|---|
| `lido-core/contracts/0.4.24/Lido.sol` | 70838 | `3bf84b96fb155af2290e6b26bc0138de356442a9abe3ea0f5274497f9fbffc10` |
| `lido-core/contracts/0.6.11/deposit_contract.sol` | 9425 | `2a8db249155e8502e1132f14410b8d7b2a924512723ed07a08167477d8f8c073` |
| `lido-core/contracts/0.8.25/lib/BeaconChainDepositor.sol` | 6296 | `b4afeac2e4dab53d2b6d1cebcf41bfc670eb1ea069cb1d5bc0e07f1932bf9fe0` |
| `lido-core/contracts/0.8.25/sr/SRStorage.sol` | 2842 | `62e922f76a1db7756684d73db3151a02f6d8f0de51fac27922f0a4095ceb9d95` |
| `lido-core/contracts/0.8.25/sr/SRTypes.sol` | 13237 | `22c28be7ceaf6ed841f18fc19296372ab246b1cfecc87902d49ee1670ed4aed6` |
| `lido-core/contracts/0.8.25/sr/StakingRouter.sol` | 55709 | `4d5b83fc73736db6755ebbb58811ed499c3e6de622cce11a3ad8548800a34155` |
| `lido-core/contracts/common/interfaces/IDepositContract.sol` | 536 | `d7b36c2de36cfc68a3fa0812add4e9c55879188a08317166a0ab0f63baaffc63` |
| `lido-core/contracts/common/interfaces/IStakingModule.sol` | 13120 | `4a98e89e763d19b45cb1ea422cec1c554fbd43c9f39c6bcc7a18aad64d46e193` |
| `lido-core/contracts/common/interfaces/IStakingModuleV2.sol` | 1511 | `eacc19c668dd2ad94c7c0cffc5957181b8bf1ed2321c14c34c9845ea054a64ce` |

Tenth git-missing packet file: `manifest.json` (packet wrapper, SHA256 `d770ee18a20ad15f36dc6dfa0cbd87b9f0b58c4a0f000467378d75d22964cd3f`). Not a Solidity pin body.

`IStakingModule.sol` is the V1 module interface (nonce / signing-key events). Consumed allocate surface is `IStakingModuleV2.allocateDeposits`. V1 presence in the packet is vendor completeness, not a producer mismatch.

## Consumed Lean SHA256 (git HEAD = packet)

Independently hashed this turn (not from looping `receipt.json`):

| Path | SHA256 |
|---|---|
| `LidoSRv3/Audit/Source/TopupRouterCommitted.lean` | `444c2b43d16a3b17996068a5dbdf203ac432478ace2cd4ad413af60b4784165f` |
| `LidoSRv3/Audit/Source/TopupModuleCall.lean` | `ebd2ab400e38891186aa298d84b860e20dd157e917219257c2888ccd9fd379d1` |
| `LidoSRv3/Audit/Source/TopupRouterContinuation.lean` | `496ba9905f6b5b42c854a58f88f4dbe6ea5849a4de12aba6ebb776fc642104da` |
| `LidoSRv3/Audit/Source/TopupLiveWithdrawal.lean` | `c8f154fe5ce744e87812090a7fdfb889c9ad28660491d8b1c686bb0a51f27d79` |
| `LidoSRv3/Audit/Source/TopupBeaconBatch.lean` | `55d8e5060e24c18caaacca152f0c69560392ca4809b11af54826013f4507126a` |
| `LidoSRv3/Audit/Source/TopupBeaconEffects.lean` | `bb6bb4e2f557c7da67ec151559b660aa88ad6f5229e026e73bfbf2728d92c469` |
| `LidoSRv3/Audit/Source/TopupRouterCredentials.lean` | `1917509309754b11fbeba8b70a9b73334a5ad18b3e3805bfb135287a58a4d53f` |
| `LidoSRv3/Audit/Source/TopupBeaconCommitted.lean` | `8cfa6ab58d9fb1f6ef558c3f0b8a6b8dd4897d3740e5c09d445c7e14ad02f54a` |
| `LidoSRv3/Audit/Verity/TopupTx.lean` | `142c68fce97927bce27ce777f9d075fa04f4b4a2801fc765540f68fa00491d01` |
| `LidoSRv3/Audit/Verity/TopupBeaconFundedTx.lean` | `536f5c81865f4c5b00fb7bb1b2440308a8a99a3190cb22e9ccd56c0a340c56e0` |
| `LidoSRv3/Audit/Source/TrioReserve1/CallData.lean` | `182787dda65d6cc315048e89212e1ef1bdb9d4c6a2084dad5413c303485d65eb` |
| `LidoSRv3/Tests/TopupRouterCommittedMutants.lean` | `5a373f9b95db6c9dadb94636d1681e24c553a7c02f26ad295339a85652df4d67` |
| `lake-manifest.json` | `c0fe05acab23cbfc27e79f1fd6983ebe5cc1e25e76be5132205e958f465c6e42` |
| `lean-toolchain` | `efac0b94923b2d8b6840cd35be9177ad0fc5ab2332f4f4311c98712cee92fdee` |
| `audit/topup-router-committed/dependency-inputs.json` | `9da678d5e0138af16655f2739e163e88abafe49651d3c2356d45cb6abb3a386e` |
| `audit/topup-router-committed/README.md` | `9e193741430793dcc72d4b8a36648125e89e08c86300d18ffb225f97af9cc4c2` |

`receipt.json` was **not reread** for this report. If needed as a file identity: it is present in both git and packet under `audit/topup-router-committed/receipt.json`. Pin/producer hashes above were taken from disk files, not from that JSON.

No `sorry` / `axiom` / `native_decide` in `TopupRouterCommitted.lean`, `TopupModuleCall.lean`, `TopupRouterContinuation.lean`, or the mutants. `#print axioms` on the three source theorems is present in source.

## 1259 dependency identities

`audit/topup-router-committed/dependency-inputs.json` (packet = git):

- `setup_module`: `LidoSRv3.Tests.TopupRouterCommittedMutants`
- `package_source_closure`: **1259** `{module, path, sha256}` entries
- `local_import_count`: 66 (`LidoSRv3` paths)
- `selected_core_sources`: **7** toolchain files
- scope text: packages matched pinned Git bodies; seven selected toolchain identities, not a full kernel audit. Unchanged imports matched frozen PR286 base `9c5b239b`.

Lake pins in `lake-manifest.json` (11 packages), matching the recorded package revs:

| package | rev |
|---|---|
| verity | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |
| evmyul | `f7e4ee0dc8f8d5265ce822a937ab5be771f182e9` |
| mathlib | `fabf563a7c95a166b8d7b6efca11c8b4dc9d911f` |
| plausible | `63045536fe95024e6c18fc7b48e03f506701c5bc` |
| LeanSearchClient | `c5d5b8fe6e5158def25cd28eb94e4141ad97c843` |
| importGraph | `5c7542ed018c78194f1e2b903eaf6a792b74c03d` |
| proofwidgets | `24b0d9dc081c5423f8eec7e866c441e5184f29d9` |
| aesop | `e3cb2f741431ce31bf73549fb52316a57368b06f` |
| Qq | `f46324995fca5f0483b742e4eb4daec7f4ee50d2` |
| batteries | `fa08db58b30eb033edcdab331bba000827f9f785` |
| Cli | `92564e5770e4d09f2d86dfbf8ada1e9c715b384c` |

`lean-toolchain`: `leanprover/lean4:v4.31.0`.

Seven selected toolchain sources independently rehashed this turn against `/root/.elan/toolchains/leanprover--lean4---v4.31.0/src/lean/` — **all seven MATCH**:

| Toolchain source | SHA256 |
|---|---|
| `Init/Data/Nat/Div/Basic.lean` | `67f894497257111dff81a5b3bab0f849cc53f31a3c62656333366ad62ab63a58` |
| `Init/Data/Nat/Div/Lemmas.lean` | `3046e785238fe8afe1f0b40f02902ee1cef13589ba8fcb045bc48f16ad4412c0` |
| `Init/Data/List/Basic.lean` | `0774d161811a270679183d643457db96c402a984243f409b8065a0c1c1a81af7` |
| `Init/Data/List/Lemmas.lean` | `06bad4028ffe4157c9bcb4f6d0d3544f798e8d4660e6e9150c48c615b3394f40` |
| `Init/Data/Fin/Basic.lean` | `fcf6cfb3553deaf9eb88e62c51e7ab6c54c1d873953f65f2216b154034b7fc31` |
| `Init/Control/Except.lean` | `aa636cde2cc6b43865afd068d4076a259f6a4769a91b47d17e7ca7be0d6b7405` |
| `Lean/Elab/Tactic/Omega.lean` | `7a81cef2ff724f9f690993d01aef906b200ca11c36f72fb57f9e6e5eaf4ec45e` |

`.lake/packages` is **not mounted** in this workspace. The 1259-entry closure document is present and internally well-formed (1259 unique-shape SHA256 hexes; package counts aesop 132, batteries 186, verity 90, evmyul 58, importGraph 10, LeanSearchClient 4, mathlib 678, plausible 13, proofwidgets 8, Qq 14, plus 66 local `LidoSRv3`). Missing lake caches are **not** a TopupRouterCommitted-vs-pin defect and are **not** INFRA_BLOCKED (PR source + pin + packet are available; no full rebuild was requested).

## Pin surface consumed by this PR

Subject is **`StakingRouter.topUp` after the rounded-target preamble**, not V3 Accountant / VaultHub / StETH.

`StakingRouter.sol` at pin (complete file, SHA above), lines 717–758:

1. `IStakingModuleV2(stateConfig.moduleAddress).allocateDeposits(smDepositableEthAmountRounded, _pubkeys, _keyIndices, _operatorIds, _topUpLimits)` — even if rounded target is 0 (queue cursor), after the paused-Lido guard at 713–715 (**preamble, OPEN**).
2. Unchecked loop 722–733: `% 1 gwei` → `AmountNotAlignedToGwei`; then `> _topUpLimits[i]` → `AllocationExceedsLimit`; then `amount += allocations[i]`.
3. `amount > smDepositableEthAmountRounded` → `ModuleReturnExceedTarget`.
4. `amount > 0`: snapshot router balance; `LIDO.withdrawDepositableEther(amount, 0)`; WC bytes; `BeaconChainDepositor.makeBeaconChainTopUp(DEPOSIT_CONTRACT, wcBytes, _pubkeys, allocations)`; `assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)`.
5. `emit StakingRouterETHTopUp(_stakingModuleId, amount)` always.

`IStakingModuleV2.sol`: `allocateDeposits(uint256,bytes[],uint256[],uint256[],uint256[]) returns (uint256[] memory allocations)` — zeros allowed; sum ≤ depositAmount; wei.

`Lido.sol:869–885`: `canDeposit`; auth staking router; `ZERO_AMOUNT` if `_amount == 0`; `_spendDepositableEther`; seed increment **only if** `_seedDepositsCount > 0` (top-up passes 0); `stakingRouter.receiveDepositableEther.value(_amount)()`.

`StakingRouter.sol:665–669`: `receiveDepositableEther` auth Lido, `emit DepositableEthReceived(msg.value)`. Lean encodes this selector as `0x13ae8460`.

`BeaconChainDepositor.makeBeaconChainTopUp` (lines 72–106): empty pubkeys **return**; length mismatch revert; per key: pubkey length 48; **skip zero amounts**; `< 1 ether` → `DepositAmountTooLow`; gwei `> uint64.max` → `AmountTooLarge`; dummy 96-byte signature; `deposit{value: amount}`.

`deposit_contract.sol` (complete 178-line bodies, packet = pin): pubkey 48 / WC 32 / sig 96; `msg.value >= 1 ether` and multiple of 1 gwei; little-endian 64-bit gwei; SHA256 deposit-data root; Merkle branch; `MAX_DEPOSIT_COUNT = 2^32-1`.

Preamble **not** in this increment (OPEN): `_checkAppAuth`, `_validateTopUpInputs` (empty keys, array lengths, 48-byte pubkeys), Active status, WC type 2, `maxTopUpPerBlockWei`, `getDepositableEther`, target-share allocation, gwei rounding, `LidoDepositsPaused` on zero-rounded + `!canDeposit`.

## Composition: producer bytes → encoding bounds → consumer payload/value

### Producer (`TopupModuleCall`)

Header: starts **after** the preamble computed the rounded target. No module implementation, authorization, target computation, compiler ABI/memory/gas equivalence, or pre-module balance invariant.

- Packed module address: ERC-7201 `moduleSlot`; `Address.ofNat` = `% 2^160`; `address_packed` under `address < 2^160`.
- `typedCall` zeros WC/type/returndata (WC is read later, after withdrawal, in the continuation helper).
- `payload i = TopupBeaconEffects.serialize (allocateCalldata (typedCall i))`.
- `serialize`: 4-byte selector word then 32-byte argument words.
- `allocateCalldata` (TopupTx): selector `allocateDepositsSelector = 0x783b8a65` + 5-word head (roundedTarget + four dynamic offsets) + `bytes[]` / three `uint256[]` tails. Matches pin `allocateDeposits(uint256,bytes[],uint256[],uint256[],uint256[])`.
- `call`: `CallData.invoke callee ctx (moduleAddress ...) (payload i) (word 0)` — **value 0**, matching pin (module CALL is not payable / no ETH).
- `allocateEntry_value = 0` (`rfl`).
- `CallData.invoke`: early `codeSize = 0` → empty error **without** attempt; else provisional transfer; arbitrary `External`. Successful origin theorem derives positive code-size and traces the actual request.

### Encoding bounds (`decodeReturn`)

Logical ABI word-array reader:

- `length < 32` → `.empty`
- `offset ≥ 2^64` → `.empty`
- `offset+32 > length` → `.empty`
- `count ≥ 2^64` → `Panic(0x41)`
- extent `offset+32+32*count > length` → `.empty`
- else `readWords`

`encodeWords_length`, `readWords_encoded`, `decodeReturn_encoded` (canonical offset=32, count `< 2^64`, trailing bytes allowed). Canonical roundtrip **does not** certify compiler memory allocation failures. Known retained discrepancy: compiler Panic 41 vs Lean `.empty` on some short/huge counts (OPEN #4).

`program`: bind module call → decode → `TopupRouterContinuation.program` on `continuationInput` **on the module-returned World**. `execute = Live.run program`. `program_success_origin` / `module_execute_success` consume executor success; no reply/later world as input premises.

### Consumer guards (`TopupRouterContinuation.guardSum` / program)

`guardSum` source order matches pin 722–734:

- empty amounts → `.ok acc`
- `a % 10^9 ≠ 0` → `AmountNotAlignedToGwei` **before** limits read
- empty limits → `Panic(0x32)` (array OOB)
- `a > l` → `AllocationExceedsLimit`
- else recurse `((acc+a) % uint256Modulus)` — pin `unchecked` add

Then `total > roundedTarget` → `ModuleReturnExceedTarget`.
`total = 0` → event-only success (pin skips withdraw/helper; still emits).
Else: `Live.run (TopupLiveWithdrawal.suffix ... (word total))` then `helper` then `finish` (router balance must equal pre-withdraw snapshot, else `Panic(0x01)` = pin `assert`).

`helper`: empty `pubkeys` → `pureExec` (pin `if (len == 0) return`); else length mismatch `ArrayLengthMismatch`; else `TopupBeaconBatch.loop`. `helperAmount` / `helperCount` short-circuit to 0 on empty pubkeys (mutants: empty keys amount 0 / count 0; positive fixture amount `3*10^18` / count 2).

`TopupBeaconBatch.loop` order matches helper: pubkey width 48 **before** zero skip; then `10^18` min and uint64 gwei **before** CALL; alignment is a callee condition (`Admissible`). Zero amounts skip without CALL (`Effects.zero`).

### Withdrawal (`TopupLiveWithdrawal`)

`suffix`: `amount.val = 0` → noop (even if every external would reject; no active/code/funding hypotheses). Else `withdrawDepositableEther external ctx amount (word 0)` — pin seed **0**.

`zero_seed_tail`: seed 0 creates no seed-accounting tail (pin 877–882 skipped).

`positive_success` still takes Pipeline/bunker/active/auth/demand/frame/oracle/funding hypotheses — those are the **withdrawal body's** admission facts, **not** premises of `TopupRouterCommitted.continuation_success`. Committed theorem only inspects a successful program result.

Callback: final value-bearing CALL `lido → router` amount with selector encoding `0x13ae8460`, log `DepositableEthReceived`.

### Helper / beacon

`TopupBeaconEffects.push` = `CallData.invoke (dispatch hash target) ctx target payload amount` with **value = amount** (pin `{value: amount}`).

Beacon deposit selector in TopupTx: `0x22895118`. Dummy signature 96 zero bytes. `scheduledDeposit_not_sourceDerived`. Source-byte path `sourceBeaconCalldata` / `executeSourceDerived` / `executeGuarded` binds returndata (`executeGuarded_binds_returndata = rfl`). Wrap-to-zero empty success; nonzero wrap reverts (underfunded push then `Contract.run` snapshot restore). `lidoPull` value 0; `creditPull` is model-added callee inflow on the Verity journal path.

Beacon address `0x00000000219ab540356cBB839Cbe05303d7705Fa` is a **source pin**, not discharged constructor/deployed provenance (`A-TOPUP-BEACON-ADDRESS` OPEN). `lidoAddress = 0xF00D` is a model pin.

Verity `Contract` has no executed module callee; returndata is instantiator-chosen (untrusted module). Live path uses arbitrary `External`. Both leave module implementation OPEN.

### Committed theorems vs displayed claims

`continuation_success`: from **program success only**, exists `total` with `guardSum = .ok total` and `total ≤ roundedTarget`, and either zero-event world or `PositiveEffects` (actual withdrawal run + helper run + core/balances from helper world + event append + concatenated attempts + helper ledger relative to **post-withdrawal** world + physical countSlot increment by `helperCount` + capacity only if `helperCount > 0`). Quote from source: *"No funding, initial-capacity, input-length or amount-admission premise is used."*

`execute_success_program`: `Live.run` success ⇒ raw program result (rollback wrapper is a model rule).

`module_execute_success`: producer CALL bytes + decoder bounds + continuation payload/value effects on the module-returned World. Arbitrary module effects before the suffix remain in that World. Mutants exhibit router balance `7 → 12` with zero allocations — no false pre-module conservation.

README (19 lines) and `guarantees.yaml` authority line: Lean statements are authoritative; metadata does not close evidence. README explicitly: this increment **does not deliver TOPUP-1 or TOPUP-2**; guard sum is unchecked wrapped total; helper uses mathematical sum only on a reached positive path; **this theorem alone does not prove these sums equal**; empty-key behavior retained; Live code-size vs typed-call traces differ; all eight complete guarantees remain OPEN.

Premises do **not** overclaim relative to pin 717–758 post-preamble. Displayed STATUS `P-TOPUP-1` / `P-TOPUP-2` CHECKED / Verity CHECKED / classification IMPLEMENTATION_PENDING does **not** close fidelity gaps ordered OPEN.

## P-TOPUP and the eight OPEN boundaries

`audit/STATUS.md`:

- `P-TOPUP-1` CHECKED/CHECKED, fidelity: beacon-address provenance remains OPEN as `A-TOPUP-BEACON-ADDRESS`, not a parent conjunct. Assumptions include `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-TOPUP-NOWRAP`, `A-VERITY-SCAFFOLD`, `A-TOPUP-BEACON-ADDRESS`, `A-SOLC-TRUSTED`, `A-RUNTIME-PROVENANCE`.
- `P-TOPUP-2` CHECKED/CHECKED, missing `_verifyValidator` / 0x02 WC / block-distance / `RootPrecedesLastTopUp`, same-block accumulation, live wei conversion, `allocateDeposits` policy, `Lido.withdrawDepositableEther` and beacon `makeBeaconChainTopUp`, gwei vs wei, 48-byte pubkeys, keccak memory-array oracle, `pendingBalanceGwei` trusted operator calldata.

Eight OPEN (unchanged; this PR does not close them):

1. Parent ABI / auth / registration / rounded-target preamble (`StakingRouter.sol` before 717). **OPEN.**
2. Arbitrary callee — no module implementation, no callback restriction, no pre-module conservation. **OPEN.**
3. Payload — reused accepted word encoder + finite byte checks; not a universal compiler encoder theorem. **OPEN.**
4. Logical decoder vs compiler alloc/gas — `count=2^59` class: compiler Panic 41 vs Lean `.empty`. Both retained. **OPEN.**
5. No-code traces — Live early `codeSize` ⇒ no attempt; modern typed CALL attempts then decoder-fails. **OPEN.**
6. `Live.run` rollback — existing model rule, not an EVM/X / revert-ABI theorem. **OPEN.**
7. Beacon address provenance, hash correctness, runtime provenance, aggregate history. **OPEN.**
8. Complete TOPUP / `P-TOPUP`. **OPEN.**

`guarantees.yaml` schema `lido-srv3-assurance-contract-v4`; P-ALLOC / P-DEPOSIT / P-ACCOUNT / P-RESERVE / P-CONSOLIDATION / P-ADDRESS / P-SSZ rows present; none close P-TOPUP.

## Mutants (consumed, not a rebuild)

`TopupRouterCommittedMutants.lean` (85 lines): `committed_success`, `committed_reaches_helper` (applies `module_execute_success` to inherited positive execution), `positive_suffix_effects` forces the 3 ETH branch (not the zero disjunction), empty-key `helperAmount/Count = 0`, positive amount/count, arbitrary-module balance 7→12, malformed-reply root rollback. Ordinary axiom queries only. No `sorry`.

## What this review is not

- Not a kernel rebuild (`lake build` not run; no Cerebras).
- Not a close of P-TOPUP or the eight OPEN items.
- Not a 1489-identity reuse.
- Not an Accountant / VaultHub / StETH review.
- Not a technical adoption of cancelled duplicate `49c00b83` INFRA_BLOCKED.

## Conclusion

Frozen HEAD `80e21927` on parent `9c5b239b` vs pin `17005714`: producer `serialize(allocateCalldata(...))` value-0 CALL selector `0x783b8a65` → `decodeReturn` uint64/extent bounds → `guardSum` alignment-then-limit then unchecked wrap → zero event or withdrawal seed-0 + helper empty-pubkey short-circuit / 48-byte / min / uint64 / dummy-sig deposit values → balance assert + `StakingRouterETHTopUp`. Packet 141 content files match git or are the nine empty-submodule vendor pin files (all pin-hash match) plus packet `manifest.json`. 1259-entry closure document present; 7 toolchain identities independently matched; lake package bodies not mounted (recorded, not a pin defect). Premises match displayed claims. No exact composition defect vs the pin.

**P-TOPUP remains OPEN. All eight OPEN.**

VERDICT: CLEAN
