I'll treat this as a source-completeness supplement only: verify the 57-file packet against Git/receipt identities, then read the previously missing EvmYul callees.Packet is present. Next I’ll verify its 57 hashes against Git/receipt identities and read the previously missing EvmYul callees.Resuming the source-completeness supplement: verify the 57-file packet against Git/receipt, then read the missing EvmYul callees.Packet and HEAD identity confirmed. Next I’ll hash-check all 57 files and reconcile selected-core vs EvmYul inventories.Packet hashes match Git/pin. Next I’ll reconcile EvmYul vs receipt identities and read the selected-core callees.GasConstants is in the packet but not the 61 validated inputs — I’ll confirm that against the 16 selected-core list, then read the EvmYul callees.Inventories are distinct: 16 selected-core are Lean `Init` files; packet EvmYul is 15 validated + GasConstants. Reading those callee bodies next.The 16 receipt `selected_core` files are Lean `Init`, not EvmYul. Packet EvmYul is 16 files (15 in the 61-set plus GasConstants). Reading the remaining callees.Reading the remaining EvmYul callees that the composition actually calls: Θ, SHA-256 precompile, mload/mstore, and gas.I have hash identity and callee coverage. Distinguishing the three inventories, then issuing the supplement verdict.Source-completeness supplement to CLEAN event 1953. Original PR284 report is unchanged. HEAD is still `191a807d07607fa08c2eb80b32db995014d89095`. P-SSZ-1 and all eight stay OPEN.

## Identity (unchanged)

| Item | Value |
|---|---|
| HEAD | `191a807d07607fa08c2eb80b32db995014d89095` |
| Parent | `85ca4fb709ee52edbb2c2993ce42ccaf6705237b` |
| Pin | `17005714f151e5502c559932319a3f2f74ac2436` |
| EvmYul pin | `f7e4ee0dc8f8d5265ce822a937ab5be771f182e9` |
| Archive | decoded SHA-256 `4e1a5ecf24bab7348f11fcdd8684cc1f6d254941e13b50393515580c8869a477` |

Git remains authoritative. Packet is access help.

## Packet vs Git / receipt

| Check | Result |
|---|---|
| Archive decoded vs claimed `4e1a5ecf…` | **match** |
| 57/57 packet bytes vs `source-manifest.json` | **match** |
| 35 proof files vs `git cat-file HEAD` SHA-256 | **35/35** |
| 6 Solidity vs pin `git show HEAD` SHA-256 | **6/6** (`d6e89f69…`, `8fd24cfa…`, `0187cc6a…`, `9591e9af…`, `2653bd4b…`, `91ef497b…`) |
| 15 EvmYul in the 61-set vs receipt `validated_inputs` | **15/15** |
| `GasConstants.lean` vs 1116 closure | **match** `906cda79711e73ca…` |
| `GasConstants.lean` in the 61-set | **absent** (not a hash mismatch) |

## Three inventories (do not collapse)

| Name | Count | What it is |
|---|---|---|
| Closure | **1116** | `package_source_closure`. Includes **15 local imports** (the 15 `LidoSRv3/Audit/Source/Ssz*.lean` modules). Test file is **not** in this 1116. Split: mathlib 681, batteries 186, aesop 132, evmyul 53, local 15, Qq 14, plausible 13, importGraph 10, proofwidgets 8, LeanSearchClient 4. |
| Validated inputs | **61** | Direct SHA list. **Includes** `LidoSRv3/Tests/SszBlsCompositionMutants.lean`. Split: 15 EvmYul + 15 local Lean + 1 test + 6 core + 4 pins + 20 audit. Original local gap was 15 EvmYul + 6 core = 21; those 21 are now in the packet and hash-match. |
| Selected core (receipt) | **16** | `dependency-inputs.json` `selected_core_sources`: Lean **Init** (`ByteArray`/`Array`/`UInt`/`Fin`/`BitVec`/`List`/`Platform`). **Not** EvmYul. **Not** in the packet. Hashes recorded only. |

Packet EvmYul is a **fourth** list of **16** files (`evmyul@f7e4ee0d`): the 15 from the 61-set **plus** `EVM/GasConstants.lean`. That is the previously missing callee set, including GasConstants.

Receipt `validated_local_count` **16** = 15 local imports + 1 direct test. Distinct from both “16”s above.

## EvmYul callees now read (16)

Bodies in the packet, used by pubkey → 7 pair SHA → same-state verifier:

| File | Role for this increment |
|---|---|
| [`EVM/GasConstants.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/EVM/GasConstants.lean) | Fee schedule (`Gmemory=3`, `Gcopy=3`, `Gverylow=3`, `Gcallstipend=2300`, …). Imported by `Gas.lean` / `StateOps.lean` / `Semantics.lean`. |
| [`EVM/State.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/EVM/State.lean) | `EVM.State` extends `SharedState .EVM` (`pc`, `stack`, `execLength`). |
| [`State.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/State.lean) | Yellow-paper `σ` / `A` / `I`. |
| [`SharedState.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/SharedState.lean) | `State` + `MachineState`. |
| [`MachineState.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/MachineState.lean) | `gasAvailable`, `memory`, `activeWords`, `returnData`. |
| [`MachineStateOps.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/MachineStateOps.lean) | Real `M` / `mload` / `mstore` (32-byte extent, big-endian lookup). |
| [`SharedStateOps.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/SharedStateOps.lean) | Real `calldatacopy` into `executionEnv.calldata` + `M` on `activeWords`. |
| [`EVM/Semantics.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/EVM/Semantics.lean) | `call` → `Θ`; `Θ` address **2** → `Ξ_SHA256`. |
| [`EVM/PrecompiledContracts.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/EVM/PrecompiledContracts.lean) | `Ξ_SHA256`: gas `60+12*ceil(len/32)`, then `ffi.SHA256 I.calldata`. |
| [`FFI/ffi.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/FFI/ffi.lean) | `@[extern "sha256"] opaque sha256`. Crypto stays external. |
| [`EVM/Gas.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/EVM/Gas.lean) | `C'`, `Ccallgas`, `memoryExpansionCost` (`MLOAD`/`MSTORE`/`CALL`/`CALLDATACOPY`). |
| [`Maps/AccountMap.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/Maps/AccountMap.lean) | `toExecute`: `t ∈ π` → `Precompiled`. |
| [`State/ExecutionEnv.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/State/ExecutionEnv.lean) | `I` including `calldata`. |
| [`StateOps.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/StateOps.lean) | `lookupAccount`, `addAccessedAccount`, `calldataload`. |
| [`UInt256.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/UInt256.lean) | `ofNat`, `fromByteArrayBigEndian`. |
| [`Wheels.lean`](/tmp/lido-ssz-review284-191a807d/ssz284-review-packet/sources/evmyul/EvmYul/Wheels.lean) | `BE`, `toByteArray`, `readBytes`/`readWithPadding`, `ByteArray.write`. |

These are real memory / Θ / precompile-2 / opaque SHA callees, not renamed payload fields. Composition wiring from event 1953 is unchanged.

Init `selected_core_sources` (16) remain identity-only; not required to re-open composition.

## Still OPEN (unchanged)

- P-SSZ-1 / `all_eight_guarantees`
- ABI / field extraction / key offset-extent / proof layout
- init / depth / memory `< 2^251` / surrounding opcode gas
- slot / proposer / EIP-4788 root / GIndex prefix
- compiled ABI / World / account / revert-rollback
- SHA cryptography (`ffi.sha256` opaque; size-32 hypothesis)

ALLOC-1 / ALLOC-2 / RESERVE-1 untouched. PR283 not reopened.

No new composition defect. Completeness gap from event 1953 (15 EvmYul + 6 core locally missing) is closed by packet bytes that match Git/pin/receipt. GasConstants is the extra EvmYul body: in 1116, not in 61, now read.

VERDICT: CLEAN
