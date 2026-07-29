# Audit migration roadmap

M0 is metadata and audit-control tooling only. The active current plane remains
Lean 4.24 with Verity `538c4a9ce2baa25b56062bdc727eb0191ad9e67f`.
It does not migrate Lean, alter a
model or proof, establish Solidity/bytecode correspondence, or certify any
Lean 4.31 toolchain.

## Gates

1. **M0 — registry foundation (this change).** Pin inputs, define trust labels,
   validate the invariant DAG, generate review views, hash available artifacts,
   scan for proof escapes, and retain legacy models as `REGRESSION` evidence.
2. **M1 — owner-authorized toolchain migration.** After the owner merges M0,
   change the future root to depend exactly once on Verity
   `68f560e66c5de6123061ce5ed60261be162673d1`. EVMYulLean
   `f7e4ee0dc8f8d5265ce822a937ab5be771f182e9` must resolve transitively from
   that Verity pin, with duplicate package instances rejected. The audit-only
   target metadata is `DEV-431-READY`; target `PrintAxioms` is `FAIL`, so
   `AUDIT-CERT=false`.
3. **Later semantic lanes.** Use Verity only for applicable Solidity/model
   components. Use EVMYulLean Yul/EVM semantics and explicit interface
   composition for handwritten Yul/direct bytecode. Never fabricate a Verity
   projection.
4. **Closure lanes.** Source, runtime, EVM, E2E, and CRYPTO assurance remains
   open until its registry row has evidence. In particular, canonical
   production EIP-7251 consolidation provenance is a prerequisite. Opaque
   native SHA-256 FFI keeps CRYPTO closure a stretch objective.

The architecture mission download directory was not mounted during M0. The
request's verified pins and constraints were checked against repository and
remote sources; no unverified draft rows were imported. Instead of copying a
49-row draft, M0 uses a smaller control-oriented registry whose entries each
have a reproducible status and explicit trust boundary.
