# ACCOUNT post-report fee casts do not truncate

Additive candidate over `86ee843a2c755bc044b6eed47fe332a4138d4d6e`. All existing executable definitions, theorem statements, package/global build wiring and historical validation artifacts remain byte-identical. The only new Lean files are ReportFeeCastInvariant, Tests/Verity/ReportFeeCastInvariantTest and PAccount1ActualFeeCasts.

## Actual consuming guarantee

`LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_casts` consumes successful execution of the existing `ReportFeeMint.handleOracleReportFromCommittedFeeProducts`. Its sole proposition premise is that committed execution. Its conclusion retains the complete existing `ReportFeeMint.Success` and adds `ExactCasts` for every registered ID on the actual final/post-report router.

For that router, let `a` be the module's actual allocation read, `t` the actual router total read, `p = 10^20`, and `c` its actual decoded packed module configuration. The new result proves:

- `a ≤ t`, derived internally from the actual successful report;
- `share = a*p/t ≤ p`;
- both `share*c.moduleFee/10000` and `share*c.treasuryFee/10000` are strictly below `2^96`;
- both fields of the actual `computeModuleFee a t c` equal those pre-cast values, so the uint96 casts do not truncate.

The first allocation bound is a named consuming lemma, used internally to prove the public cast guarantee. It is not an extra public assumption. `ExactCasts` exposes the share bound, both strict pre-cast bounds and both exact returned fields. Its inputs are the same post-report router and configuration reads used by the reward getter. This closes the specific post-report uint96 exactness obligation, not all ACCOUNT storage/deployment or settlement obligations.

## Derivation with aliases and duplicates

`rows_allocation_bound` inducts over the actual `writeReportRows` execution. If a later row targets the same accounting slot, its induction result bounds the final value. If no later row does so, the existing frame lemma preserves the head write, whose uint64 value is at most the checked running total and hence the final total. This permits repeated IDs and different IDs with equal accounting slots.

The actual report then writes the final total into the router accounting slot. If that slot aliases the queried module slot, both reads equal the same final total; otherwise the module bound survives. Thus `report_allocation_le_total` needs no Layout.Separated, Nodup, keccak-injectivity, independently supplied allocation bound or no-wrap premise. It proves an inequality, not the earlier per-row exact-value claim.

Decoded fee fields are always uint16. From share≤10^20, each pre-cast fee is bounded even by the deliberately loose `10^20 * 2^16`, already less than2^96 before dividing by10000. No external basis-point cap, configuration-reachability or global fee bound premise is needed.

## Pinned source correspondence

All Solidity sources are core `17005714f151e5502c559932319a3f2f74ac2436`; four full pinned source files are hashed and compared with their Git bodies in the receipt checker.

- SRLib.sol873–892: validation admits the reported order and amounts; each row writes the module low64 value then checked uint64 accumulation; the final router write stores the accumulated total.
- SRUtils.sol62–69: module/router low64 balances convert through the same gwei multiplier.
- SRTypes.sol118–135: moduleFee and treasuryFee occupy uint16 fields of packed ModuleStateConfig.
- StakingRouter.sol819–839: actual router total determines whether the getter processes any modules; individual zero-allocation rows are skipped. Lines843–854 read the actual packed configuration and call the unchanged computeModuleFee; lines885–893 compute the share and the two uint96 casts.

The zero-total mathematical helper uses Nat division by zero (=0). The actual source getter processes no modules when its total is zero, and skips individual zero-allocation modules. The theorem does not claim Solidity executed `_computeModuleFee` with denominator zero. Its universal bound also covers unexecuted registered rows as a helper property; wherever the actual getter invokes computeModuleFee, these are exactly its arguments.

Aliases and duplicate fixtures are witnesses in the admitted storage-layout model, not claims that distinct deployed keccak keys collide or that a deployed registry contains duplicates. The existing layout/registry/typed boundaries remain. In particular no physical keccak derivation, full ABI/role admission, locator resolution, interposed report operations or later fee distribution/reward callback is added. The earlier report/read correspondence still needs its original separation/distinctness conditions. This increment only removes the cast-exactness concern on the actual post-report domain.

## Validation

Three direct normal-kernel Lean checks passed against the isolated local root cache:

```
lake env lean audit/trio/account-address/ReportFeeCastInvariant.lean -o .lake/build/lib/lean/ReportFeeCastInvariant.olean
lake env lean LidoSRv3/Audit/Guarantees/PAccount1ActualFeeCasts.lean -o .lake/build/lib/lean/LidoSRv3/Audit/Guarantees/PAccount1ActualFeeCasts.olean
lake env lean audit/trio/account-address/Tests/Verity/ReportFeeCastInvariantTest.lean -o .lake/build/lib/lean/Tests/Verity/ReportFeeCastInvariantTest.olean
```

Six `decide +kernel` regressions cover module/module slot collision, module/router slot collision, duplicate IDs, maximum source-admitted10^18-gwei rows with full uint16 fee fields, zero report with skipped getter, and positive actual report/getter/fee/mint execution. A seventh theorem instantiates the public consumer on the positive fixture. Maximum admitted row is10^18, not uint64Max. No native/FFI reduction or new Solidity runtime test is used.

`validate.py` compares the three new sources plus the inherited PAccount1 setup import closure:24 source identities,11 exact dependency pins. Inherited local bodies must match86ee; package bodies must match their pinned Git revision. It independently queries the built environment for13 theorem axiom closures; all are subsets of propext, Classical.choice and Quot.sound. Toolchain Std/Lean remain covered by lean-toolchain. This is a scoped source/axiom check, not a new full All/Trust build.

`check_receipt.py --core PATH` verifies the artifact hashes, the24 source hashes, the package pins and four exact pinned Solidity bodies. Baseline302's1685-job All/Trust/29 result remains historical inherited evidence; this candidate does not claim to have repeated or superseded it. Independent candidate source review and root integration remain separate gates.

## Root-owned integration proposal

No global file is edited here. Add `ReportFeeCastInvariant` and `Tests.Verity.ReportFeeCastInvariantTest` to existing AccountAddressChecks roots. Add the direct `LidoSRv3.Audit.Guarantees.PAccount1ActualFeeCasts` import to AllGuarantees. Import the new regression module in Trust and query at least the public consuming theorem, report_allocation_le_total and collision/positive regressions under the existing allowance policy. Do not introduce another accountAddress package/provider. Root should perform the combined facade/Trust build and independent exact integration review after this source freeze.
