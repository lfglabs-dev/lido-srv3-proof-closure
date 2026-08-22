# Pack N3 — stETH mint / supply (P-ORACLE-SUPPLY-1)

One node, one PR. Design fork taken: **one parent with two conjuncts**
(`POracleSupply1.oracle_supply_mint_and_cap`), not the two-row fork.

## What the parent says

`LidoSRv3/Audit/Guarantees/POracleSupply1.lean`, theorem
`oracle_supply_mint_and_cap`, universal over `feeWei`, `shareRate`, and a
named cap `maxShareRate` with retained premise `shareRate ≤ maxShareRate`.
For the Spec frame `specOfMint i feeWei shareRate`:

1. **Mint conjunct.** `sharesMinted = mintedShares feeWei shareRate` and
   `shareRateDelta = shareRate`, where

       mintedShares feeWei shareRate := feeWei * shareRate / E27

   with `E27 = 10^27`, the existing Lido share-rate scale reused from
   `AddressClaimBatchTx.E27`. The mint is *computed*, not an argument.
   The mint equality is definitional for `specOfMint`; the bound below is
   the required non-definitional conjunct.
2. **Bound conjunct (sanity / Eugene aggregate).**
   `sharesMinted ≤ feeWei * maxShareRate / E27` under the cap premise.
   Proved by `minted_shares_le_cap`
   (`LidoSRv3/Audit/Spec/OracleMintCorrespondence.lean`), which is
   monotonicity of the conversion in the rate — not `rfl`.

Supplemental exact-ratio child `minted_shares_exact_ratio`: when
`shareRate = num * E27 / den` divides exactly and `den ∣ feeWei * num`,
`mintedShares feeWei shareRate = feeWei * num / den`. Both sides are
load-bearing (frame mint on the left, accounting ratio conversion on the
right). `num := totalShares, den := totalPooledEther` gives the
wei-to-shares reading; the transposed instantiation gives the
pooled-ether-rate orientation.

## Kill-lines

`LidoSRv3/Tests/PackN3OracleMintMutants.lean`. Parent-shaped negations;
every premise of the parent is retained in the negated statement.

- `sum_balances_mutant_killed`: mutant frame with
  `sharesMinted = sum balances` (the Pack E vector). On balances
  `[10, 20]` and `feeWei = shareRate = maxShareRate = 0` the mutant mints
  `30`, refuting the parent shape.
- `raw_fee_mutant_killed`: mutant mint `feeWei * shareRate` without
  `/ E27`. With all inputs `1` it mints `1` while
  `mintedShares 1 1 = 0`, refuting the mint conjunct;
  `raw_fee_mutant_breaches_cap` shows the same vector also breaches the
  bound conjunct.
- `cap_premise_is_load_bearing`: dropping the cap premise makes the bound
  conclusion false even for the honest frame (`shareRate = E27`,
  `maxShareRate = 0`).
- `honest_frame_passes_vector`: positive control through the universal
  parent.

## Citations, not widenings

- P-ACCOUNT-1 stays order-only. `account_parent_cited_order_only` cites
  `PAccount1.mint_after_read_discipline`; `PAccount1.lean` is not edited
  and ACCOUNT is not folded into supply.
- The existing Eugene child is cited as an operator-bond fact only
  (`eugene_child_cited_operator_bond`, wrapping
  `PAlloc1EugeneBound.checked_amount_le_bond`). It is not this parent.

## Non-goals

- The Pack E leftover `OracleFrame.sharesMinted = argument` (free
  `sharesToMintAsFees`) is not restated and is not the registered
  conclusion here.
- No new guarantee ID is minted into `Registry.lean`; root imports,
  Trust, receipt, YAML, and `AllGuarantees` are untouched.

## Build

    lake build LidoSRv3.Audit.Spec.OracleMintCorrespondence
    lake build LidoSRv3.Audit.Guarantees.POracleSupply1
    lake build LidoSRv3.Tests.PackN3OracleMintMutants

No `sorry`, `admit`, or `native_decide` anywhere in the pack.
