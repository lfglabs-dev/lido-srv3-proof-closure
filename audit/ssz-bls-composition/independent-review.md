I'll review PR #284 at the exact claimed HEAD in read-only mode: confirm git identity, then inspect BLS/SSZ composition against the claimed theorems and remaining OPEN items.HEAD and parent match the claimed SHAs. Next I’ll read the composition sources and machine-check theorems, axioms, and manifests.The 16 theorems and 31 kernel examples match the claim on paper. Next I’ll check the actual BLS/SSZ call wiring and machine-verify hashes, pins, and manifests.lido-core is empty in this clone, so I’ll fetch the pin and the prior BLS/SSZ definitions next.Resuming the exact-head review: I’ll finish BLS/SSZ wiring, pin/manifest checks, and theorem/sorry/axiom counts, then issue the verdict.The prior file reads are cached; I’ll pull the composition module, BLS/SSZ callees, and remaining identity checks in parallel.Identity matches. Next I’ll finish the composition module, Solidity BLS/SSZ bodies, and axiom/hash checks.Composition wiring looks real so far. I’ll now count theorems/examples, read axioms, and hash-check Git files against the receipt.I’ll finish callee definitions, axioms, remaining OPEN fields, and the 31-kernel vs 9-ordinary count.I have enough to close the composition check. Confirming a few remaining identities, then I’ll issue the verdict.Independent exact-head review of [lfglabs-dev/lido-srv3-proof-closure#284](https://github.com/lfglabs-dev/lido-srv3-proof-closure/pull/284). Git is authoritative. PR283 was not reopened. P-SSZ-1 is not closed.

## Identity

| Item | Value |
|---|---|
| HEAD | `191a807d07607fa08c2eb80b32db995014d89095` |
| Parent | `85ca4fb709ee52edbb2c2993ce42ccaf6705237b` (accepted #282 merge) |
| Pin | `17005714f151e5502c559932319a3f2f74ac2436` (`lido-core` gitlink) |
| Files | **18** (matches claim) |
| Subject | `Compose actual BLS validator leaf with raw SSZ proof verification` |
| Packet `4e1a5ecf` | **absent** (not a blocker) |

Lake pins in `lake-manifest.json` match receipt `package_pins` (11/11). Parent SSZ modules, `lakefile.lean`, `lake-manifest.json`, `lean-toolchain`, `foundry.toml` are unchanged vs `HEAD^` and match receipt hashes. Guarantee / ALLOC / RESERVE files are untouched.

Pinned Solidity SHA-256 at `17005714` matches `source-check.json` / compiler-input identities:

- `CLValidatorVerifier.sol` `d6e89f69…`
- `BLS.sol` `0187cc6a…`
- `SSZ.sol` `91ef497b…`
- plus `ValidatorWitness.sol`, `BeaconTypes.sol`, `GIndex.sol`

## Composition (real, not rename / opaque Nat)

This increment **does** compose real BLS leaf calls with the same-state SSZ verifier.

Control flow in [`LidoSRv3/Audit/Source/SszBlsComposition.lean`](/tmp/pr284-review/repo/LidoSRv3/Audit/Source/SszBlsComposition.lean):

1. **Pubkey** — `pubkeyRun` → parent `blsCall` (`SszShaCallMemory.lean:188`): `mstore(0x20,0)` + `calldatacopy` of 48 calldata bytes + SHA-256 precompile 2 + success∧`returndatasize==32` + `mload(0)`.
2. **Seven pairs** — `merkleRun` threads **one** `EVM.State` through seven `pairRun`s: `(a,b),(c,d),(e,f),(g,h)` then `(l10,l11),(l12,l13)` then `(l20,l21)`. Matches `CLValidatorVerifier.sol:60–85` / `BLS.sol:516–534`.
3. **Leaf** — `leafRun` = pubkey + seven pairs with `expectedCredentials` as a separate argument and `chunk` = `sourceUint256` little-endian (not a bare `Nat`).
4. **Verifier** — `verifyLeaf` feeds `leaf.digest` **and** `leaf.state` into parent `SszProofCalldataLoop.verify` (`SSZ.sol:179–254`).

`verify_leaf_success` is an iff against independent `validatorTree` / `sourceVerify`, not a supplied leaf digest. `pairDigest` / `merkleDigest` / `pubkeyDigest` are computed FFI outputs.

Harness [`audit/ssz-bls-composition/solidity/SszBlsComposition.t.sol`](/tmp/pr284-review/repo/audit/ssz-bls-composition/solidity/SszBlsComposition.t.sol) inherits unmodified `_validatorHashTreeRoot` and calls unmodified `SSZ.verifyProof`. Slot / EIP-4788 root / GIndex construction stay out of the harness, as claimed.

## Theorems / tests / axioms vs claim

| Claim | Observed |
|---|---|
| 16 theorems | **16**, all with bodies |
| 31 kernel examples | **31** `example`s (`decide +kernel` / `rfl` / lemma `rw`) |
| 9 ordinary | **9** `#print axioms` queries |
| 18 files | **18** |

No `sorry`, `admit`, added `axiom`, `native_decide`, or `bv_decide` in the two new Lean files.

Axiom log (theorems only): `propext`, `Classical.choice`, `Quot.sound`.

Receipt Lean hashes match Git HEAD:

- `SszBlsComposition.lean` `dae0997c41b32ed337300594b730e6b8b22c267c4d13c36ac60c9ba65230831f`
- `SszBlsCompositionMutants.lean` `72c57b819798ca7ea051d3cb85a5c1433c10e46d3bfb8e13a76e946ef03f9e96`

Recorded `lake env lean` exits are 0 on imported caches (not a full rebuild; not re-run here). `checkout_head_at_validation` is the parent `85ca4fb7`; file bytes at `191a807` match the validated hashes.

Manifest machine-check: `validated-inputs.sha256` 40 present hashes OK; 21 missing are `.lake/packages/evmyul` (15) and unpacked `lido-core` (6). Pin gitlink + separately fetched core pin hashes cover the Solidity identities. `dependency-inputs.json`: 1116 package-source entries, 15 local imports, 16 selected core sources.

## Remaining OPEN (do not close P-SSZ-1)

Receipt `all_eight_guarantees`: **OPEN**. [`PSsz1.lean`](/tmp/pr284-review/repo/LidoSRv3/Audit/Guarantees/PSsz1.lean) not in the diff.

Still outside this increment:

- ABI / field extraction / key offset-extent / proof layout
- init / depth / memory `< 2^251` / surrounding opcode gas
- slot / proposer / EIP-4788 root / GIndex prefix into this suffix
- compiled ABI / World / account / revert-rollback
- SHA cryptography (`shaOutput` opaque FFI, size-32 hypothesis)

ALLOC-1 / ALLOC-2 / RESERVE-1 untouched.

VERDICT: CLEAN
