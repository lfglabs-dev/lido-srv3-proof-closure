# Integrated producer/consumer composition

The composition declarations now live in
`LidoSRv3/Audit/Source/TrioAlloc2/Composition.lean`, inside the production source
glob. The former staged `Composition.lean` is a compatibility import.

The integration branch combines ALLOC-1 `8269ac576cf119975a7e9954459cd4aa04d5cd82`,
ALLOC-2 `460cc599d9fd350af51db27e4e8d175561f99773` and RESERVE-1
`7173594e7518cc636fff9099f864fa61b021a7cf` on main
`bcfbb5f027a5c370594891c1a455fde137709941`. This is local integration, not delivery
or a merge into GitHub main.

The three composition theorems derive consumer array-length premises, successful
allocation with conservation and demand bounds, and the independent proportional
distribution relation from actual producer success. They pass the same demand and
actual output arrays to the consumer. No consumer-success assumption is added.

The boundary remains decoded arrays. Compiler memory allocation, byte-memory/ABI
execution, parent conversion, source refinement, callbacks and rollback remain
required. The separate +1 algorithm is unchanged.

Bounded reproduction from the repository root (Lean 4.31.0 via elan):

```sh
python3 audit/trio/integration/check-init-composition.py --output /tmp/trio-composition-check
```

The output directory must not exist. The check elaborates the transitive Init-only
closure, imposes a 30-second limit per module and records source hashes, compiler,
commands and exit codes. The initial integration check passed all 23 modules;
its receipt is in `audit/trio/integration/composition-init-receipt.json`. This is
not a production/test/trust build, make-prove/test result, or certification.

`prepare.py`, `source-identity.json` and earlier remote receipts retain the
historical candidate setup against producer `5f1683eaf753ff73aec6f1e787cb7f68bedcf056`.
They do not validate the integrated producer. Use the root build for complete
validation; the bounded command above only checks this decoded composition.
