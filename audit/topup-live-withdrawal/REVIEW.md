# Independent review: TOPUP concrete withdrawal consumer

Verdict: CLEAN for exact candidate `c029a44fcb85fd213f978477cea93f89355b6f46`, parent `34229c7e6fab217555d88e5448c17ccffcb05155`. No blocking or nonblocking finding identified in the claimed increment. This is acceptance of the bounded consumer, not closure of TOPUP-1.

Reviewer: independent agent `/root/topup_units`, who did not author this TOPUP consumer. Read-only project review; only this report was written under `/tmp`. No fresh Lean/Forge build, commit, push or project edit performed.

## Examined material and integrity

Read both new Lean files completely, all six audit artifacts, the relevant delivered `Pipeline`, `Live`, `Router`, `CallFlow`, `CallSpec`, `WithdrawalComposition`, `WithdrawalTail` and `Spending` definitions/proofs, and pinned Solidity withdrawal/receiver/top-up call sites. Applied the campaign delivery criteria and the prior bounded-consumer proposal.

The exact candidate adds eight files only: source, tests and six audit files. No existing test, foundation, common metadata, DEPOSIT file or registered `TopupTx` executor is modified. Compared the parent to `ee5f7f63c958a80edcf6265072ef84613f4369e2`: only the ten independent SSZ wrapper additions differ. The four foundation inputs listed in the receipt match their earlier delivered versions byte for byte; accepted ALLOC/RESERVE domains are unchanged.

All nine receipt input hashes and all nine `validated-inputs.sha256` entries pass independent recomputation. The validation-log hash passes. Committed artifacts match the reviewed working-tree bytes. Solidity `StakingRouter.sol` and `Lido.sol` match both their recorded SHA256 hashes and git objects at pin `17005714f151e5502c559932319a3f2f74ac2436`. Candidate `git diff --check` passes.

- Source SHA256: `c8f154fe5ce744e87812090a7fdfb889c9ad28660491d8b1c686bb0a51f27d79`.
- Tests SHA256: `2ec4aaf9ca09be1490cb7abb5e6cab37c055f24f7be0608591f1be983ce99a81`.
- Validation log SHA256: `1084d6f525afa976355a37a63e9e7282395633f7b488314bddb5d3c19d436e8d`.

## Proof and source assessment

`suffix` faithfully selects the local positive-amount withdrawal at StakingRouter.sol:741-744 and fixes its second argument to zero. On zero it performs no withdrawal. Earlier module/pause checks are expressly outside this suffix; the zero theorem does not claim the full TOPUP call can bypass them.

`Balances` is independent pointwise accounting: Lido debit, router credit including any existing router balance, and every other account unchanged. Its definition contains neither the executor nor an assumed post-world. Distinct source/recipient and funding premises are explicit. `positive_success` obtains the final world from the delivered concrete pipeline, uses its proved accounting balance frames and the CALL transfer relation, then derives those independent equations. No manual credit is inserted by the new consumer.

The last callback and committed event are derived from the concrete router receiver. `Live.call` credits value before dispatch; `Router.receiveDepositableEther` enforces immutable Lido identity and only emits its event. The final trace observation includes caller, target, amount, selector, success and empty return. Prefix traces/logs remain allowed. There is no callback-success, arbitrary-callee frame, balance conclusion or output equality supplied as an admission premise.

The admitted domain is explicit and useful: physical locator/consensus bindings and code presence; dispatcher address separation; non-bunker queue, active Lido, caller equal to looked-up router; positive uint256 amount; actual queue demand, buffer admission, consensus-frame computation and timestamp arithmetic; physical Lido funding, immutable identity and router code; Lido/router distinctness. These computation-success premises are numerical/source getter preconditions inherited from the delivered pipeline, not the desired withdrawal or balance outputs. The source seed guard is derived from modulo-128 bounds plus zero, not assumed. The zero seed tail theorem independently establishes no tail write/event/call.

## Validation assessment

The supplied targeted command is `lake build LidoSRv3.Audit.Source.TopupLiveWithdrawal LidoSRv3.Tests.TopupLiveWithdrawalMutants`. Its recorded exit is zero, 58 jobs; the warnings shown are replayed pre-existing Verity.Core linter warnings. Four theorem queries agree between source, validation log, axioms log and receipt: transfer uses `propext, Quot.sound`; zero no-op and zero seed use `propext`; positive success uses `propext, Classical.choice, Quot.sound`. No new sorry/custom axiom/native-decide shortcut appears.

All eleven regression declarations were read. They exercise a complete concrete withdrawal with every unhandled call rejecting, retained old router funds, a third-account frame, exact callback and event, unchanged seed count versus the nonzero-seed mutation, zero versus positive admission, actual ETH shortage and wrong immutable receiver identity. Omitted/doubled-credit cases reject the independent balance specification and are accurately labeled specification mutants. No Solidity execution or full repository build is claimed for this increment.

## Residual boundary

The uint256 amount is an input: provenance from gateway/module allocations and exact source sum is not established here. The outer router-to-Lido ABI CALL, registered `TopupTx.creditPull` simulation, source-byte beacon loop, full TOPUP rollback, beacon recipient balances/storage, deployed-code/address provenance and the `Live.World.balances` to `ContractState.selfBalance` representation link remain open. Natural-number world balances are not a proved uint256 projection for the later loop. These are documented future obligations, not conclusions inferred from this consumer. The bounded withdrawal result reduces the concrete callback-funding gap without claiming the full transaction conservation theorem.
