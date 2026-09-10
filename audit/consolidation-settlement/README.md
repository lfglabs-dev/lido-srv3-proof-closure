# Same-world consolidation settlement suffix

This candidate strengthens the separately published fee/refund helpers with an
executed fee → vault → refund suffix. It is an implementation candidate awaiting
independent exact-source review. It does not change the registered baseline,
AllGuarantees, Trust, any registry, existing models, or the publication site.

## Public result

`PConsolidationEth1.actual_settlement_success` consumes success of the actual
`GatewaySettlement.execute`, with **one shared External interpreter** for inbox
and refund calls. The internal composition is generalized over two interpreters;
the public facade instantiates both with the same function, including for aliases.
It extracts the `GatewaySettlement.Success` certificate, whose fields expose:

- payable-balance/zero/group guards and the successful checked count of the actual
  raw groups; the count is not a supplied total fee or allocation receipt;
- the actual typed gateway→vault fee STATICCALL and the nested vault→inbox
  empty-calldata STATICCALL, including exact32-byte fee data and static depths;
- checked count×fee multiplication, the exact word value, successful `_checkFee`
  equation and `totalFee.val + refund.val = msgValue.val`, with no modular loss;
- the actual `GatewayCall.execute` success, using that total and those raw groups;
- `refundFee` success on **that vault-returned world**, its actual request shape,
  zero-refund no-call result, final returned world and concatenated traces;
- the gateway modifier's final balance assertion after the refund callback.

The two call outcomes are conclusions of inversion, not supplied stage-success
premises. No BalanceFrame, LogFrame, Untraced, funding or recipient-net-credit
premise is present. An arbitrary refund callback may change the world; the source
balance assertion must still succeed. The caller's balance result is not a proof
of aggregate recipient credit under arbitrary callbacks.

`actual_settlement_failure_restores` restores the entire incoming suffix world on
any failure, including failure of the refund after prior successful vault effects.
This uses the declared model root rollback rule. Attempt traces remain audit
observations, including reverted attempts; they are not committed EVM logs.

## Source extent and deliberate boundary

Pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

- ConsolidationGateway.sol:118–122 modifier;189–199 pure checked count;
  211–222 fee getter, checked multiplication, `_checkFee`, pair preparation,
  high-level vault CALL, refund;285–307 fee/refund helpers;348–366 producer.
- WithdrawalVault.sol:81–85 modifier,199–208 entry,222–224 fee getter;
  WithdrawalVaultEIP7685.sol:58–72/79–101/113–126 nested fee read and request loop.

The input world is already payable-credited. This executor replays the pure count
from the same groups and omits role/pause/DSM/locator/witness/quota admission and
updates between the count and quote. It does not assert that the entire gateway
prefix reaches this world or that its source initialization invariants hold. The
modifier snapshot is taken at this scoped model entry. Full transaction payable
credit/debit rollback is not inferred from the suffix snapshot theorem.

The configured code-present vault getter is executed as a dedicated read-only
interpreter; it has no writable-world reply whose effects could be discarded.
The outer getter call returns its encoded word and retains the nested fee trace.
`fee-callsite.yul` from solc0.8.25 confirms that the typed return-valued call has
**no extcodesize precheck**: an EOA returns empty data, then uint256 ABI decoding
fails. `quote` records the successful empty STATICCALL followed by caller decode
failure. It does not incorrectly reuse the older typed0.8.9 primitive.

The pre-existing actual vault CALL performs its own fee STATICCALL again on its
credited world. The model does not assume the two quotes are equal: the second
read can make the vault reject. Producer lists are consumed by the existing ABI
model; arbitrary unbounded-array round-trip, physical allocation extents and lazy
malformed-element failure order remain unproved. Low-level code-less calls retain
the existing missing precompile-dispatch boundary. Error/LOG ABI correspondence
is only the source extent actually modeled: inherited refund errors remain
semantic Fault.reason values, and inherited request logs remain semantic fields.
Deployment, full prefix, gas and consensus/EIP7251 processing are not claimed.

## Validation

`lean-status.json` and `targeted-build-final.log` retain the actual targeted build
command, exit status and output. Existing dependency caches were reused; source
identities and package pins are retained in `source-inputs.json`. The public
success theorem uses propext/Quot.sound; failure uses propext. All11 new regression
theorems are kernel-decided and use propext only. No native_decide exception or
new axiom was added. The global Trust/AllGuarantees/registry are intentionally
unchanged and no new global check is claimed.

The11 kernel regressions cover callback observation of prior vault storage/value,
refund failure restoring it, exact nested quote/vault/refund order, zero refund,
EOA sender fallback, fee changing between quote and vault read, product overflow,
short fee data, checked-count overflow, an accepted callback violating the final
gateway assertion, and typed no-code-vault decode failure.

`solidity-status.json` and `solidity-validation-final.log` retain9 successful
Forge fragment tests. The EIP7685 base is copied byte-for-byte from the pin;
source vault modifier/entry/getter and gateway count/suffix/helpers/modifier are
copied into minimal harnesses, using solc0.8.9 and0.8.25 respectively. The witness
struct is reduced to its pubkey field, and role/pause/DSM/locator/witness/quota
admission is omitted. These are scoped execution checks, not full-gateway or
proxy/deployment execution. The failed outer Solidity harness transaction rolls
back payable entry credit too; the Lean theorem restores its already-credited
suffix input snapshot. Their common checked effects are storage/value rollback
of the vault and refund work, not equality of differently located snapshots.

The final-assertion Solidity regression uses a freshly created selfdestructing
helper to force refund ETH back to the gateway. Compiler deprecation and missing
receive-function warnings are confined to test doubles. The EIP7685 fallback
must remain a fallback to expose both fee-query and raw-request behavior.

No independent review is claimed by this writer dossier. The exact candidate
must be reviewed before root imports/registers the new public consumers.
