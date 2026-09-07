# Pinned reserve execution probes (incomplete delivery)

Run from the repository root after initializing the pinned submodule:

```
npm ci --ignore-scripts --prefix solidity/trio-reserve1
node solidity/trio-reserve1/compile.cjs
node solidity/trio-reserve1/execute.cjs
```

Use Node 22.15 per `lido-core/.nvmrc` (the recorded validation uses 22.15.0).
Compiler settings match `lido-core/hardhat.config.ts`: Lido uses solc 0.4.24,
optimizer 200, Constantinople; queue base uses solc 0.8.9, optimizer 200,
Istanbul. The npm lock fixes the fixture tools and selected source dependencies.
This is not installation or execution of Lido's entire Yarn test suite.

The harness inherits the complete pinned Lido and WithdrawalQueueBase bodies.
Raw storage setters and internal-helper wrappers are fixture initialization
surfaces, not production admissions. `CallFixture` supports arbitrary return
bytes, arbitrary revert bytes and payable recipient rejection. No always-success
assumption is made about these boundaries. Locator, oracle and recipient fixture behavior is NOT yet related to their
production implementations. The actual inherited bunker getter reads its pinned
unstructured slot; its writer authorization is not modeled by fixture setup.

Execution runs on a fresh local Ganache chain; no public chain or credentials
are used. Unlimited contract size admits the fixture subclass; gas and deployment
size are excluded. The Solidity source hash inventory and compiler versions are
written to `audit/trio/reserve1/receipts/solidity-compilation.json`.

The execution receipt contains input case names, relevant physical slots,
Lido/router/queue balances, ordered CALL/STATICCALL/DELEGATECALL targets, values,
payloads and committed logs. The driver also runs the handwritten Lean executor with pinned Verity words
and physical storage on identical vectors, comparing exact return/revert bytes,
selected physical slots, balances, directly Lido-issued calls and ABI logs.
It runs two faulty executors as negative controls. Universal correspondence and
full production locator/oracle/router composition remain missing.
The trace contains attempted calls even when the transaction reverts; committed
logs and state are separately checked for rollback. Do not conflate trace with
contract storage or use these tests to claim the parent guarantee.
