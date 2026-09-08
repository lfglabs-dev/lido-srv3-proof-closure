# Account/address independent source slice

This isolated Lake package is an audit implementation for P-ACCOUNT-1 and
P-ADDRESS-1 against `lidofinance/core` commit
`17005714f151e5502c559932319a3f2f74ac2436`.  It does not import the existing
registered guarantee models.  The source spans are the P-ACCOUNT-1 and
P-ADDRESS-1 entries in `audit/source-map.yaml` at repository commit
`caad1ef5e297202636e6fe643afa88fe8a62d618`.

`PAccount1.lean` models the ordered router validation errors, checked uint64
accumulation, and the packed accounting writes. `PAddress1.lean` models the
ordered guards and errors of `transferFrom`, `requestWithdrawals`,
`claimWithdrawalsTo`, and `unwrap`, including the packed withdrawal-request
owner/claimed fields. `Tests/Verity` contains concrete success, rejection,
rollback, packing, and mutant witnesses.

This is source-level Lean evidence. It is not a compiler, EVM, bytecode, or
deployment correspondence claim.
