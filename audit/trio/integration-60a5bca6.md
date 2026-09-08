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

## Validation outcome

`lake build` was submitted by durable job
`8e7c8f71-8a67-40f2-a90d-b2e9f61feed0` at integrated commit
`bfdc845f`. The remote builder rejected the request before compilation with
HTTP 422: 257 GiB was available, but the requested 12 GiB plus the 250 GiB
emergency floor required 262 GiB. This is an infrastructure rejection, not a
passing build receipt.

The durable task later reported completion without captured output. A direct
retry at receipt commit `b22cd075` reproduced the same pre-compilation failure:
`lake build` exited 1 after the remote endpoint returned HTTP 422 with 257 GiB
available against the same 262 GiB capacity requirement. Consequently there
is still no successful compilation receipt to claim.

The metadata gate completed successfully with
`python3 scripts/audit_metadata.py check` and reported 11 canonical guarantees
plus 19 subordinate evidence rows.
