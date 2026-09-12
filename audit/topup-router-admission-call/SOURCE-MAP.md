# Pinned source correspondence

All Solidity source bodies are in `solidity/input.json`; all 28 cached identities are checked against accepted `audit/topup-module-nocode/compiler-source-identities.json`, with 19 core bodies checked directly against core17005714 and 8 external OpenZeppelin bodies checked against the accepted vendored source. The 29th fresh body is the new test. Fresh artifacts carry exact metadata for the consumed source closures. `StakingRouter.ir` and `BatchRouter.ir` are full fresh bodies extracted verbatim from their corresponding artifacts. Cached output and IR have separate names.

| Operation | Pinned Solidity | Fresh production IR | New consumed definition |
|---|---|---|---|
| Actual post-root seam | `TopUpGateway.sol:204–232`, original `TopupTimingHistory.execute` and `TopupBatchMemory.finish` | Entire prior gateway compiler dossier retained in base | `walk`, internally constructed `Ready`, `consume` |
| Immutable router locator, not gateway locator | `StakingRouter.sol:1169–1171`, `topUp:686` | `case0x3e7ae601`, lines677–702: immutable10329, `shl(225,0x3224316f)`, STATICCALL output32, min32 allocator, canonical address decoder | `authLookup`, `auth_origin`, `decodeRouter` reuse |
| Actual gateway authorization | `StakingRouter.sol:1177–1179` | `fun_checkAppAuth`, line4243: CALLER versus masked canonical returned address; `ea8e4eb5` | `run` gateway comparison |
| Typed arrays and pubkey width | `StakingRouter.sol:764–785` | Whole topUp branch lines704–771, empty then length short-circuit then per-pubkey guard | `validateInputs (moduleInput i ready)` from actual root output |
| Physical registration | `StakingRouter.sol:1099–1108`, `SRUtils._requireModuleIdExists`, `SRStorage.isModuleExists` | `fun_requireModuleIdExists:4130`, `fun_contains`, root+2 mapping | `physical`, reused membership preimage/physical load |
| Physical status and type2 | `StakingRouter.sol:691–694`; `ModuleStateConfig` actually stores enum status despite the separate legacy-struct uint8 comment | topUp lines781–817, bits 224/232, panic21 → active → type2 | `physical`, `Physical`, `physical_success` |
| Existing cap and allocation boundary | `StakingRouter.sol:696–706` | lines819–880: packed uint64 cap, getDepositableEther STATICCALL, SRLib DELEGATECALL, minimum/rounding | inherited `TopupBatchConsumer.target`; allocation views deliberately omitted |
| Zero-target canDeposit | `StakingRouter.sol:713–715`, `SRTypes.ILido.canDeposit` | lines882–936: immutable10326, selector `e78a5875`, STATICCALL, canonical boolean, `5609c247` | `canDeposit`, `decodeBool`, conditional `run` branch |
| Return allocation/head/scalars | Caller min32 blocks; inherited allocator correspondence | `finalize_allocation:3030`, `abi_decode_bool_fromMemory:3193`, runtime `abi_decode_address_fromMemory:4371` | inherited credentials decoder plus canonical address/bool guards; no assumed cursor fit |
| Module CALL and complete actual continuation | `StakingRouter.sol:718–758` | Remainder of entire topUp dispatch retained, module CALL0 → raw return decoder → actual withdrawal/beacon → event | `finish` uses original `TopupBatchMemory.finish`, `TopupTimingHistory.finish` once |
| Entire342 guarantee and original rollback | Existing `PTopupEntryAdmission` | Existing full pinned caller/consumer evidence in base | literal `PriorEffects`, `actual_router_admission_complete_prior`, `failure_restores` |

Exact new selectors/errors: `644862de`, `e78a5875`, `ea8e4eb5`, `c4d88632`, `fc235960`, `500585ad`, `d41d6282`, `4e487b71`+uint256(0x21), `645cc9f6`, `2e5c948c`, `5609c247`. The validator independently derives custom selectors with Keccak. Whole fresh topUp dispatch and all called scalar/auth/registry/allocator functions are retained, not snippets.

The structural root fixture uses the same deliberately partial constant-output SHA interpreter as the accepted tests; it is not cryptographic evidence. Runtime tests use the genuine full pinned router and constructor-only fixture initialization, not a replacement admission harness. They cover actual STATICCALL semantics while leaving the admitted deployment and allocation proof boundaries explicit.
