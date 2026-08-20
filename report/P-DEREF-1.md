# P-DEREF-1

Theorems: `PDeref1.closure` (abstract parent) and `SolidityDereference.verity_observe_refines_source` (verity refinement); YAML cites both explicitly. Wave 3 kill-lines `DereferenceMutants.packed_config_clobber_kill_line_refutes_parent` and `reentrant_callback_overwrite_kill_line_refutes_parent` are negations of `closure`'s full predicate shape on syntactic mutants of `applyInterleaving`.
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Almost every SRv3 action looks up `moduleStates[id].config.moduleAddress` after `_requireModuleIdExists`. If that slot can be zero, or can change under a re-entrant callback, the router would CALL `address(0)` or a swapped module. The intended guarantee: on every reachable registry state, a dereferenceable id yields the same nonzero address it was registered with, and that binding survives the normal writers (status / accounting / params / shares / add-another-module).

## Modeling

- Reachable states: `emptyRegistry`, or `migrateStorage old` for an already-`WellFormed` `old`, or `addModule` of a fresh id with `address ≠ 0`, `address < 2^160`, `fresh < 2^24`, `lastModuleId < 32`.
- **`migrateStorage` is the identity** (`DereferenceCorrespondence.lean:51`). Old-layout contents are an explicit input (`audit/P-DEREF-1.md`). `_migrateStorage`’s actual copy from `smOld.stakingModuleAddress` is not executed.
- `Interleaving` writers: `staticCallback`, `setStatus`, `updateAccounting`, `updateParamsOrShares` are **no-ops** (`applyInterleaving` returns `s`). Only `addFreshModule` can change state, and it refuses to overwrite a registered id.
- No module removal / replacement at this pin — modeled by omission.
- Verity `observeDeref` reads two model-local maps (`moduleIdPositionsSlot`, `moduleStatesSlot`). `VerityRepresents` is a stipulated coupling, not keccak(`abi.encode(id, slot)`). `ROUTER_STORAGE_POSITION` is OPEN.
- `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`. Supplemental child, not one of the eleven public guarantees (`PDeref1.lean:9–10`).

## Proof

**`reachable_wellFormed`.** Induction on `Reachable`. Empty: no registered ids. Migrated: `WellFormed old` is the constructor hypothesis. Added: the new id gets the constructor’s nonzero / `< 2^160` proofs; other ids inherit from the IH.

**`source_deref_exact_reachable`.** `Dereferenceable` is `registered = true`; `sourceDeref` is `if registered then some (moduleAddress id)`. Nonzero is `reachable_wellFormed`.

**`deref_stable_under_all_interleavings`.** Induction on the interleaving list. Each step: `existing_binding_preserved` by cases — the four no-ops are `simp`; `addFreshModule` either no-ops or writes a *different* id (`h : registered id` plus “cannot add an already-registered fresh” forces `id ≠ fresh`).

**Facade `closure`.** Rewrite with stability, then apply `source_deref_exact_reachable` on the original state (so the address after interleaving equals the *original* `s.moduleAddress id`).

**`verity_observe_refines_source`.** From `VerityRepresents`, the position map is nonzero iff registered, and the address word decodes to `s.moduleAddress id`. Then `observeDeref` succeeds, and the observation map records that word. Address round-trip uses `address < 2^160`.

## Issues

## Resolution

**Restyle.** The executable view is `getStakingModuleAddress` (`observeDeref` is the same function).

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1 | A+D | Abstract is `PDeref1.closure`; Verity is `verity_observe_refines_source`. |
| 2–10, 16–18 | A | Fictional `Reachable` / layout / packing named in `missing`; `Reachable` not rebuilt. |
| 11, 15 | C | `observeDeref` is a view and returns `0` for a zero address. |
| 14 | A | `ofNat` wrap documented. |

## Wave 3 (2026-08-20) — make the parent load-bearing

Prior closure was almost content-free: the four writers were `id`, so stability
was vacuous, and the only counterexamples lived in disconnected mutants
(`replaceAddress`, `uncheckedDeref`). Wave 3 adds two syntactic mutants of the
parent's own transition `applyInterleaving` that refute `PDeref1.closure`
itself with premises retained:

* `mutantApplyInterleavingClobber` — one-line edit: `.setStatus id _` now
  `{s with moduleAddress := if q = id then 0 else s.moduleAddress q}` (wide
  `SSTORE` clobber of the packed `ModuleStateConfig` word, issues 4/18).
  Kill-line `packed_config_clobber_kill_line_refutes_parent` is
  `¬ ∀ s hs id h steps, sourceDeref (mutantRunInterleavingsClobber s steps) id = some (s.moduleAddress id) ∧ …`
  at witness `registeredOne` (Reachable via `migrated`, `WellFormed`), id `1`
  (`Dereferenceable`), steps `[.setStatus 1 0]`. Mutant deref is `some 0 ≠ some 0xBEEF`
  with `decide`; honest theorem holds because that arm is `id`.

* `mutantApplyInterleavingReentrant` — ` .staticCallback` now writes
  `0xCAFE` over id 1 (issue 6). Kill-line `reentrant_callback_overwrite_kill_line_refutes_parent`
  same shape at `[.staticCallback]` → `some 0xCAFE ≠ some 0xBEEF`.

Both are cited in `audit/guarantees.yaml` `reproduction.expected` and
`fidelity.covered`. Honest `closure` still holds (`lake build` green); the
mutants show it is falsifiable and that the packing / re-entrancy exclusions
are load-bearing, not vacuous. Residual gaps (migrateStorage = id fiction,
keccak `ROUTER_STORAGE_POSITION`, `last+1`/unique-address, `uint24` vs `Nat`,
`DereferenceYulBridge` syntax-only) stay in `fidelity.missing` honestly.


1. **YAML theorem name is not the facade theorem.**
   `guarantees.yaml` cites `verity_observe_refines_source` as both abstract and verity. The exported guarantee theorem is `PDeref1.closure`, which does **not** mention `observeDeref`. The Verity refinement lives in the source module and is not re-exported by the facade.

   *Scenario.* `lake build LidoSRv3.Audit.Guarantees.PDeref1` and look for `verity_observe_refines_source` in that namespace: it is not there. `AllGuarantees.all` does not include this supplemental child. Calling the Verity plane CHECKED oversells a source-file helper plus a hypothesized `VerityRepresents`.

2. **Mapped `ROUTER_STORAGE_POSITION` / keccak layout is OPEN while the row is CHECKED.**
   `audit/source-map.yaml` maps `SRStorage.sol` 12–78 (the ERC-7201 position and membership). Lean `VerityRepresents` uses model-local slots 0 and 2. `audit/P-DEREF-1.md`: no claim on `ROUTER_STORAGE_POSITION` hash or compiler-emitted SLOAD.

   *Scenario.* A proxy whose `ROUTER_STORAGE_POSITION` is wrong still “satisfies” `verity_observe_refines_source` if you fill the toy maps by hand. The mapped storage span is not what `observeDeref` reads.

3. **`migrateStorage = id` plus `Reachable.migrated` makes any well-formed fiction reachable.**
   *Counterexample to “reachable ⇒ came from `initialize` + real migration.”* Pick `old` with `registered 7 = true`, `moduleAddress 7 = 1`, `lastModuleId = 7`. `WellFormed old` holds. `Reachable (migrateStorage old)` holds. `closure` says deref(7) = 1. Deployed `_migrateStorage` might have remapped, skipped, or refused that old row. The model cannot be wrong about migration because it does not do migration. `audit/P-DEREF-1.md`: “old-layout migration bytes are an input.”

4. **Interleavings do not implement the writers they are named after.**
   `setStatus` / `updateAccounting` / `updateParamsOrShares` do not even update the status/accounting/share fields (those fields do not exist on `RegistryState`). They are aliases of `staticCallback`. The induction therefore proves: “doing nothing, or adding a *new* module, does not change an old address.” That is true and almost content-free. A real `setStatus` bug that clobbered the packed `config` word (address lives in the same struct) is unrepresentable: there is no packed word.

   *Scenario.* Packed `ModuleStateConfig` write for status uses a wide `SSTORE` that zeros `moduleAddress`. Live deref returns `0`. Model `setStatus` is `id`, `closure` still holds. The CHECKED “survives every source-permitted interleaving” claim is about a state type that cannot store the bug.

5. **`VerityRepresents` is an assumption of the Verity theorem.**
   If the maps do not satisfy the coupling, `verity_observe_refines_source` does not apply.

   *Scenario.* A `ContractState` produced by a real `initialize` / `_addModule` under keccak map slots. Nothing proves it satisfies `VerityRepresents` (model-local slots 0 and 2). Fill those two maps by hand to match `s` and the theorem holds; leave them empty and the theorem does not apply. The “executable mapping transaction” is a lookup in whatever maps the caller already filled.

6. **`staticCallback` is a name, not a re-entrancy semantics.**
   `applyInterleaving _ .staticCallback = s`. If a callback could `SSTORE` the old id’s address directly, that action does not exist in `Interleaving`.

   *Scenario.* Module `getStakingModuleSummary` calls back and writes `moduleStates[id].config.moduleAddress = attacker`. Live deref returns `attacker`. Model interleaving has no such constructor; `closure` still reports the original address. Tests include a `replaceAddress` mutant that *shows* the property fails if such a writer exists — and then the writer is excluded from `Reachable` / `Interleaving`.

7. **`addModule` does not assign `lastModuleId + 1` and does not reject duplicate addresses.**
   Solidity `_addModule` (SRLib 183–231): `newModuleId = lastModuleId + 1`, loops existing modules to revert `StakingModuleAddressExists`, requires a nonempty name, valid WC type. Lean `addModule` writes whatever `fresh` the constructor is given (`fresh < 2^24`, unused, `lastModuleId < 32`). Two reachable states can share the same address on different ids; ids need not be consecutive.

   *Scenario.* `Reachable.added empty 7 0xA …` then `added … 3 0xA`. Both ids dereference to `0xA`. Live `_addModule` rejects the second add. `closure` holds for both. The CHECKED “registered address” theorem is not the router’s allocation of ids.

8. **Capacity is `lastModuleId < 32`, not `modulesCount >= 32`.**
   Solidity `_addModule` reverts when `getModulesCount() >= 32`. Lean `Reachable.added` requires `s.lastModuleId < maxModules`. Because ids need not be consecutive (issue 7), you can have `lastModuleId = 31` and one registered module, and then be unable to add; or `lastModuleId = 0` and (via migration) 32 registered ids.

   *Scenario.* `Reachable.migrated` of a WellFormed old state with 32 registered ids and `lastModuleId = 0`. Lean allows it. Live `_addModule` would already be at the module-count cap. `closure` still holds. The CHECKED Reachable predicate is not the router’s cap.

9. **`DereferenceYulBridge` is imported and unused; it is syntax-only SLOAD AST.**
   `PDeref1.lean` imports the bridge. No theorem mentions `abstractDereferenceSload`. The file itself says it does not bind `ROUTER_STORAGE_POSITION` or execute SLOAD.

   *Scenario.* Change the Yul AST to `SSTORE` or a wrong mapping base. `closure` and `verity_observe_refines_source` still hold. The CHECKED Verity plane is not that AST.

10. **Zero address is excluded only at `addModule` / `WellFormed`.**
   Deployed `_migrateStorage` copies `smOld.stakingModuleAddress` with **no** zero check. Lean refuses to call a zero address reachable.

   *Scenario.* Old layout has `stakingModuleAddress = 0` for a still-listed module. Solidity copies 0; later deref is `address(0)`. Lean `Reachable.migrated` requires `WellFormed old`, so this state is out of `closure`. Completeness of Reachable is the hole: the interesting zero-address case is defined not to exist.

11. **`observeDeref` is a writer, not a view.**
    Live `_requireModuleIdExists` + `moduleStates[id].config.moduleAddress` is a pair of SLOADs. `observeDeref` (`DereferenceCorrespondence.lean:167–174`) on success does `writeMapUint observedAddressesSlot id (addressToWord address)`. The refinement `verity_observe_refines_source` *requires* that write (`:199`).

    *Scenario.* A deref view used inside `getDepositAllocations` / `topUp` / status updates. Live storage is unchanged. Lean “executable mapping transaction” dirties slot 6. A later read of `observedAddressesSlot` sees a value no pinned function stored. The CHECKED Verity deref is not the router’s lookup; it is a logging SSTORE the source does not perform.

12. **`applyInterleaving` does not preserve `WellFormed`.**
    `Reachable.added` requires `address ≠ 0`, `address < 2^160`, `fresh < 2^24`. `applyInterleaving (.addFreshModule fresh address)` (`:121–123`) only rejects `registered ∨ address = 0 ∨ lastModuleId ≥ 32`. It will install `address = 2^160` or `fresh = 2^24 + 1`, and it sets `lastModuleId := fresh` (not `last + 1`).

    *Counterexample.* Start from `emptyRegistry` (Reachable, WellFormed). Interleave `addFreshModule 1 (2^160)`. The result has `registered 1 = true` and `moduleAddress 1 = 2^160`, so `WellFormed` fails. `closure` still holds of id `1` only if it was already dereferenceable — it was not — so the theorem is silent. The “every source-permitted interleaving” set is larger than `Reachable` and contains states the nonzero / 160-bit lemmas do not cover. A subsequent `observeDeref 1` would `wordToAddress`-wrap `2^160` to `0` and revert `StakingModuleUnregistered` while the abstract `sourceDeref` returns `some (2^160)`.

13. **`addModule` / interleaving can *decrease* `lastModuleId`.**
    `addModule` (`:53–56`) sets `lastModuleId := fresh`. After `Reachable.added empty 10 0xA`, `lastModuleId = 10`. Interleave `addFreshModule 3 0xB` (3 unused, 10 < 32): `lastModuleId` becomes 3. Live `_addModule` does `newModuleId = lastModuleId + 1` and only increases.

    *Scenario.* Two adds as above. Lean cap `lastModuleId < 32` is still true (3 < 32) and a later `addFreshModule 31 0xC` is allowed. Live after id 10 is assigned, the next id is 11; you cannot add 3 or jump to 31. Combined with issue 7 (non-consecutive ids), the CHECKED Reachable / Interleaving generators are not the router’s id allocator, and the cap test is applied to a field the model is free to rewind.

14. **`observeDeref` coerces `id` through `Uint256`, so `2^256` aliases `0`.**
    `verity_observe_refines_source` calls `observeDeref (id : Uint256)`. `Uint256.ofNat (2^256) = 0`. `applyInterleaving` will install `fresh = 2^256` (issue 12: no `fresh < 2^24` check). `sourceDeref` on `2^256` returns `some address`. `observeDeref 0` looks at position map key 0.

    *Counterexample.* From `emptyRegistry`, interleave `addFreshModule (2^256) 0xA`. Abstract deref of `2^256` is `0xA`. Verity observation of that id reads slot key `0`. If id 0 is unregistered, `observeDeref` reverts `StakingModuleUnregistered` while `sourceDeref` succeeds. The CHECKED refinement’s `id : Uint256` coercion is not the unbounded `ModuleId`. Live ids are `uint24` and cannot be `2^256`.

15. **`observeDeref` extra-reverts on address 0; live exists-then-returns 0.**
    Live `_requireModuleIdExists` is EnumerableSet membership, then a packed-field read that **returns** `address(0)` if that is what was copied (issue 10: migration has no zero check). `observeDeref` (`:167–174`) reverts `StakingModuleUnregistered` if `wordToAddress(moduleStates[id]) = 0` even when the position map is nonzero.

    *Scenario.* Position `[7] ≠ 0`, packed word low-160 = `0` (old-layout copy). Live deref returns `0`. `observeDeref 7` reverts. `verity_observe_refines_source` assumes `WellFormed` so this state is excluded. The CHECKED Verity deref is a different function than the router’s lookup: it refuses the zero address the live view would return.

16. **`lastModuleId` is `uint24` on chain; Lean stores an unbounded `Nat`.**
    Live `_addModule` does `lastModuleId = uint24(newModuleId)`. Interleave `addFreshModule (2^24) 0xA`: Lean `lastModuleId = 2^24`. Live store is `uint24(2^24) = 0`. Next `_addModule` would allocate id `1` again.

    *Counterexample.* After that interleaving, Lean cap `lastModuleId < 32` is false (`2^24 ≥ 32`), so further adds are blocked. Live last is 0, so another add is allowed (and may collide). Combined with issue 13 (rewind) and issue 7 (non-consecutive ids), the CHECKED cap field is not the packed `uint24` the router increments.

17. **Module id `0` is in-model-registerable.**
    Live `_addModule` starts at `lastModuleId + 1` with `lastModuleId` initially 0, so the first id is 1. `Reachable.added empty 0 0xA` (0 unused, address ≠ 0, 0 < 2^24, last 0 < 32) is a legal Reachable state. `closure` says deref(0) = 0xA.

    *Scenario.* Lean reachable registry with only id 0. Live `_requireModuleIdExists(0)` is false (never inserted). `source_deref_exact_reachable` holds of a module id the router cannot have. Combined with issue 14 (`2^256` aliases 0 in Verity), id 0 is both a phantom registered id and the wrap residue of out-of-range ids.

18. **`VerityRepresents` stores a bare address word, not the packed `ModuleStateConfig` slot.**
    Live `moduleStates[id].config` packs `moduleAddress` with `stakeShareLimit`, `status`, `withdrawalCredentialsType` in one word (`SRTypes.sol:118–136`). `VerityRepresents` (`DereferenceCorrespondence.lean:178–182`) couples `storageMapUint moduleStatesSlot id` to `wordToAddress` of a *bare* address. `observeDeref` then `addressToWord`s a clean 160-bit value into `observedAddressesSlot` (issue 11).

    *Counterexample.* Packed word `0xBEEF | (7 << 160)` (address `0xBEEF`, share-limit 7 in the high bits). `wordToAddress` still yields `0xBEEF`. Live SLOAD of that slot returns the full packed word; a wide write of “just the address” zeros status/WC/limit (issue 4). Lean’s map cannot store the packed word and the CHECKED observation writes a stripped address. `verity_observe_refines_source` is a lookup in a map that is not the router’s packed config slot.
