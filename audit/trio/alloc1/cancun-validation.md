# Cancun execution boundary

RESERVE1 PR244 was inspected read-only at
`345c1f3cc034edcb99138a08d266e77d5f2910cb`. Its Hardhat 2.26.3 in-process Cancun
network supplied the backend pattern. ALLOC-1 enforces
`allowUnlimitedContractSize: false`; no RPC endpoint or network credentials are
configured. The existing Ganache/Shanghai mode and earlier receipts are retained.
Set `ALLOC1_EVM=cancun` to select this backend.

The pinned Lido `hardhat.config.ts` specifies solc 0.8.25, via-IR, optimizer 200,
Cancun for this router. The new runs use those settings and unchanged Solidity
submodule `17005714f151e5502c559932319a3f2f74ac2436`. Proxy construction still uses
its separate pinned solc 0.8.9 Istanbul compilation (optimizer200, no via-IR),
executed by the Cancun EVM. Earlier London proxy evidence is retained separately.
Compiler receipts save the full import-resolved standard JSON input and output,
source hashes, exact compiler version, settings and creation/runtime objects.
Compiler-object hashes are hashes of hexadecimal UTF-8 text, including unresolved
link placeholders where present. Deployment receipts separately save actual
creation transactions and linked/immutable-populated runtime code, with hashes of
the decoded bytes and an explicit EIP-170 size assertion.

`validate-cancun.py` runs twelve paired capacity/source vectors, root RETURN-memory
snapshots, nested callback rejection, all existing public writer tests, fresh
proxy lifecycle execution, and both parent-shaped mutants. A mutant passes its
check only if execution produced a result/call mismatch, not merely exit 1.
A separate comparison uses the preserved independently executed Verity876649b
vectors: it is an old-model-output comparison, not fresh current-head remote
Verity validation. All full-build evidence at8269ac remains STALE_SUCCESS.

Reproduce with fresh output and private dependencies:

```sh
npm ci --prefix solidity/trio-alloc1 --no-audit --no-fund
python3 audit/trio/alloc1/validate-cancun.py \
  --output /fresh/cancun \
  --dependencies solidity/trio-alloc1 \
  --proxy-dependencies /path/to/pinned-proxy-tools \
  --source-vectors /path/to/fresh-light/vectors.json \
  --verity-vectors audit/trio/alloc1/receipts/verity-vectors-876649b.json
```

The proxy tools remain solc0.8.9 and OZ4.4.1 as documented in `reproduce.md`.
Dependency locks, complete source inputs and output digests accompany the receipts.
These are tests and implementation evidence for independent review. They do not
establish universal compiler-memory refinement, all-writer/migration reachability,
consumer transaction composition, gas correctness, or deployed-system equivalence.

`ProxyGenesis.initialization_invariants` now connects the initialization lemmas to
the constructor's implementation-slot storage prefix. It derives both invariants
without assuming initializer/callback success. Its finite separation conditions
remain explicit. The code-existence guard, delegatecall dispatch, final proxy admin
transition and whole lifecycle relation are still open.

## Executed receipts

`receipts/cancun-suite.json` records seven completed steps: capacity, callback,
writer and London-proxy compatibility runs exit0; target-only and call-order
mutants exit1 on recorded behavioral mismatches; the preserved-Verity comparison
exits0. `receipts/cancun-suite.tar.xz` contains the complete compiler inputs,
outputs, actual deployed code, transactions, per-case observations and command
logs. Every member is hashed in the suite receipt. Durable job
`1c4cbd90-04b4-4709-b7ec-8aa7e1dfb6e9` exited0.

The final Istanbul-proxy run has a separate receipt/archive; it replaces the
London proxy case for compiler-configuration fidelity only. The other six suite
steps and their executable sources are unchanged. Initial exploratory Cancun
runs and all historical Shanghai receipts remain preserved.

`receipts/cancun-proxy-istanbul.json` records exit0 for the corrected production
compiler configuration. Its adjacent `.tar.xz` holds both compiler closures and
all deployment/lifecycle evidence. Durable job
`9f37466c-a88c-4569-8a98-ab9fe4724940` completed the run.

The original gzip archives are preserved at db4a6fd. Their losslessly recompressed
xz versions contain byte-identical uncompressed tar streams; hashes and sizes are
in `receipts/cancun-lossless-recompression.json`. This saves 1,102,307 bytes while
retaining every compiler input/output, deployment and execution observation, so
the complete-source request fits the receiver's 16 MiB source limit. The receiver
rejected the earlier larger snapshot before compilation; no source was omitted.
