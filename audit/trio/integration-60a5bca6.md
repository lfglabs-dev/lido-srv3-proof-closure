# Trio remote-head integration receipt

Integrator-owned receipt for the non-merge replay onto campaign main
`60a5bca6174b92c539bc4d361f2f7febb30c1fa7`.

## Source heads

| Lane | Delivered head | Declared parent | Imported ancestry |
|---|---|---|---|
| P-SSZ-1 / P-TOPUP-1 / P-TOPUP-2 | `598b40e1fb10cf94256c4b9b2a9c190dd9ec1f5d` | `c86598ef0f82771f659500579e719f1508a7626d` | `caad1ef5e297202636e6fe643afa88fe8a62d618..598b40e1fb10cf94256c4b9b2a9c190dd9ec1f5d` |
| P-DEPOSIT-1 | `a80a5b07ecd2b1c66c815b81b85e01c65a1a818c` | `9376ec5ddba13668ee41b853480b5337254b9e02` | `caad1ef5e297202636e6fe643afa88fe8a62d618..a80a5b07ecd2b1c66c815b81b85e01c65a1a818c` |
| P-CONSOLIDATION-ETH-1 | `8aa1f3e4b7c77bcfe0f48e204d476857fbbf18a3` | `b0ae1741cefb64f59775a475e674bcd7e718c2ef` | `caad1ef5e297202636e6fe643afa88fe8a62d618..8aa1f3e4b7c77bcfe0f48e204d476857fbbf18a3` |

The head-only patches were not sufficient snapshots: the named paths did not
exist on campaign main. Therefore the receipt records replay of each complete
lane chain from the permitted historical ancestor rather than claiming that
only the final head commit was integrated.

## Integration delta

The three linear chains were cherry-picked, in table order, without merge
commits. All lane-owned proof and documentation blobs at the integrated tip are
byte-for-byte identical to their respective delivered heads.

The sole conflict was the consolidation registration in `lakefile.lean`.
Campaign main already registered `audit.trio.MainGuaranteeChecks`; the
consolidation head registered `audit.trio.consolidation`.
The resolution retains both registrations. This is an additive integrator-owned
build registration and does not rewrite a lane proof.

P-ALLOC-1, P-ALLOC-2, and P-RESERVE-1 remain exactly as they were on campaign
main. No YAML file changed, and no global `Trust` or `AllGuarantees` declaration
was added.

## Mechanical verification

- Compare every lane-owned path's blob ID at the integrated tip with the
  corresponding delivered head using `git rev-parse <revision>:<path>`.
- Confirm no ALLOC/RESERVE delta with
  `git diff --quiet 60a5bca6 HEAD -- audit/trio/alloc1 audit/trio/alloc2 audit/trio/reserve1`.
- Confirm no YAML delta with
  `git diff --quiet 60a5bca6 HEAD -- '*.yml' '*.yaml'`.
- Confirm linear history with
  `test "$(git rev-list --min-parents=2 60a5bca6..HEAD)" = ""`.
