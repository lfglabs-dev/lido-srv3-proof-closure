# TOPUP: source-byte deposit CALL and concrete beacon callee effects

This increment connects the **existing TOPUP source calldata journal** to a new source-shaped `DepositContract.deposit` interpreter, through the delivered complete-payload `CallData.invoke`. Success is derived from actual source fields, source amounts and physical code/funds/tree-capacity conditions. The callee does not receive a success flag, expected credit, balance-preservation premise or root-match premise.

Scope is the new per-deposit consumer. **The registered `TopupTx`, PR267 `TopupFundedSourceTx` and its funded `sourcePushLoop` remain unchanged and do not call this new interpreter.** The new multi-call `loop` executes actual payload calls and supports whole-world rollback, but this dossier does not derive its amounts from the Lido withdrawal or prove aggregate Lido funding/conservation for that loop. No guarantee/assumption status is changed.

## Sources and execution

Pinned source: [lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436](https://github.com/lidofinance/core/tree/17005714f151e5502c559932319a3f2f74ac2436).

- [BeaconChainDepositor.sol](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/lib/BeaconChainDepositor.sol#L66): variable-value TOPUP calls at lines 66–107 and root/signature/endian helpers thereafter. It skips zero amounts and checks minimum/uint64-gwei before depositing. It does **not** check exact gwei alignment itself.
- [deposit_contract.sol](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.6.11/deposit_contract.sol#L101-L159): actual pinned Solidity 0.6.11 callee, not a copied 0.8 implementation or boolean oracle. The body checks three field lengths, minimum, gwei divisibility and uint64 amount; emits the event; reconstructs and checks the root; checks capacity; increments count and performs binary-carry insertion. This body has no outgoing value transfer or balance writer.
- Existing `TopupTx.sourceBeaconCalldata` and `DepositDataRootCorrespondence.computeDepositDataRootWithAmount` are consumed unchanged. The four-byte selector is `0x22895118`. Canonical source bytes contain 128/224/288 head offsets and all 48/32/96 field bytes, totaling 420 bytes.
- Existing `Live.World`, physical account-indexed storage, `CallData.invoke` and `ABI` are imported unchanged. `invoke` performs the actual provisional sender debit and recipient credit before dispatch. A callee rejection restores that provisional transfer and all callee state. The source model's body preserves these credited balances by proof of its actual writes.

The compiler storage-layout artifact in this dossier confirms `branch` at slots 0–31, `deposit_count` at 32 and `zero_hashes` at 33–64. New Lean code uses these physical slots, with no synthetic count/branch counters in the world. The deposit body writes the count and one branch slot; it does not execute constructor or getter bodies.

## Independent obligations proved

`TopupBeaconCallee` implements a raw complete-payload decoder and the source deposit body. `deposit_balances`/`dispatch_balances` derive the successful callee frame by examining every body path and its real branch insertion. `insert_exists` derives termination from `0 < count+1 < 2^32`; no successful-insertion premise is supplied to the positive consumer.

`insert_selection` characterizes the first odd quotient of the incremented count. Every lower quotient is even; exactly one branch slot is written. Its value is a separate `List.range'`/`foldl` specification over the original lower branch words, not the recursive insertion's own returned node. `BranchEffect` combines this independent selection/value/footprint with the actual physical count increment. It holds over arbitrary initial branches; no initial reachable-tree-history invariant is claimed. The specification's `counted` world changes only count slot 32; the fold reads lower slots because the proven selected height is less than 32.

`reconstructed_source` relates the independently transcribed callee hash chain to the existing caller helper on the same fields and `msg.value / 1 gwei`. The root parameter is taken from the existing helper, and its equality to the callee recomputation is proved. The consumer does not assume a root-match predicate.

`TopupBeaconEffects.encode_abiWord` proves byte recovery from the existing positional ABI word encoder with source octet bounds. `sourcePayload_eq` proves the journal serialization equals an independently assembled canonical byte payload, and `decode_sourcePayload` recovers all three byte arrays and the helper-computed root. Serializing every journal entry to 32 bytes would put 28 zero bytes before the selector and is rejected by a regression.

`source_push_success` derives the actual `CallData.invoke` success, exact request/attempt, all-account debit/credit relation, incremented physical count, exact semantic event fields and `BranchEffect`. Its premises are actual code and funds; exact source field lengths 48/32/96; minimum, gwei alignment and uint64 amount; correspondence between the source input amount and that same call value; and tree capacity. It accepts arbitrary old caller/callee balances and permits self-transfers with their proper unchanged-balance meaning. The conclusion is not an alias for executing the program, and no successful-reply/frame/output hypothesis is provided.

`failure_restores` restores the entire `Live.World` for an error from the new multi-call program. Regressions execute one accepted callee call which changes balances, count, branch and event, then a second root-mismatching call; rollback removes the first call's committed effects while retaining attempted-call observations.

## Boundaries retained

- The theorem is a source-model correspondence for the new per-call consumer, not a compiler/EVM equivalence or a replacement of the old name-based primitive globally. The PR267 funding/withdrawal connection, parent entry admission and old dual-journal integration remain open.
- Hash data flow is instantiated with the existing opaque SHA operation. All digests have the typed 32-byte/octet shape. SHA correctness, precompile/gas/failure behavior, compiler/runtime identity and cryptographic uniqueness remain open. Lean deterministic tests use an explicit zero hash solely to isolate ABI, guard and world effects; they are not SHA tests. The separate Solidity execution uses actual SHA.
- The decoder proves exact decoding of canonical source outputs. Equivalence to every malformed, aliased, overlapping, noncanonical or overflow-sensitive solc 0.6.11 ABI input remains open. The dispatcher implements only `deposit` at its configured target; unsupported targets/selectors are rejected. It does not claim the contract's getters/interface/constructor semantics.
- `Live.Log` carries words. The event representation retains all 192 bytes of the five fixed-width accepted fields (48+32+8+96+8), one word per byte; little-endian amount and previous count are preserved. Solidity LOG topic/data ABI is tested by the independent actual-Solidity harness, not proved by this Lean encoding. Error data in Lean is a UTF8 semantic identifier, not the Solidity `Error(string)` ABI.
- `Live.World.balances` uses natural numbers. The per-call relation derives the funded value transfer but does not prove initial ledger reachability or an aggregate uint256 asset bound. No no-wrap/physical-reachability claim is imported from PR267.
- An arbitrary selected target under code/funds conditions is not deployed immutable provenance. The canonical address literals and pinned deployment metadata do not close **open A-TOPUP-BEACON-ADDRESS**. No assumption catalogue, root guarantee, pin or baseline metadata was edited.

## Validation and reproduction

The targeted check covers 24 theorems, 27 regressions and eight principal axiom queries (ordinary `propext`, `Classical.choice`, `Quot.sound` only).

See `receipt.json`, `validation.log`, `axioms.log`, `validated-inputs.sha256` and `source-check.json` for the exact input set and targeted validation. Reproduce Lean from the proof repository root:

```sh
lake build LidoSRv3.Audit.Source.TopupBeaconCallee LidoSRv3.Audit.Source.TopupBeaconEffects LidoSRv3.Tests.TopupBeaconEffectsMutants
```

The isolated harness under `solidity/` imports the **unmodified pinned Solidity 0.6.11 callee**, with its own compiler/configuration and no shared Foundry/profile edits. Its reproduction command and actual result are recorded in `solidity-validation.log`. Four tests include 1024 fuzz cases over admissible counts, branch values, deposit amounts and old callee balances; deterministic cases cover all 32 carry heights, minimum/maximum uint64-gwei value and final admissible count. Assertions inspect transferred ETH, actual physical count/changed branch, event ABI, source guard precedence, rejection rollback and outer rollback after a later root failure. `solidity-storage-layout.json` comes from the 0.6.11 compiler. This is executable finite evidence, not a universal Lean-to-EVM refinement proof.

No full-repository Lean build, deployment, current-chain read or new production-address acceptance is claimed. `REVIEW.md` is to be supplied by the independent exact-candidate reviewer after authoring is frozen.
