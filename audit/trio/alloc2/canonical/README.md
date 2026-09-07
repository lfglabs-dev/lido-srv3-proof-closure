# Canonical ALLOC-2 source-domain amendment

The registered parent retains its three existing conjuncts and adds the
well-founded proportional executor's exact success domain, independent
`Spec.Distributes` result, and short-capacity panic. The +1 model is separate.

The registry, source map, report generator's immutable input basis, and generated
UX2/report files change together. The input basis is commit
`f0adf9ebcbb762a303c6c6466d45c4fa290393c7`; this is an input amendment, not an
external review approval or a canonical status upgrade.

Reproduce the source build:

```
python3 audit/trio/alloc2/canonical/prepare.py
cd ../temp/alloc2-canonical
REMOTE_BUILD_NODE_ID=babylon remote-lean-build lake build LidoSRv3 LidoSRv3Test LidoSRv3Audit
```

`source-identity.json` records all 258 canonical Lean/config inputs. The
materializer uses immutable base `924891ed58bbd9f424f298dae57b8982a82aad24`.
`submission.json` records the remote client's source manifest and job validation
identity, without credentials. `check_receipt.py RECEIPT` requires a successful
remote result matching that submission, verifies every current canonical input,
and reconstructs the amended source manifest relative to the base. An earlier
narrower parent draft passed job `af2b50db`; it does not validate the final exact
success/error signature.

`regressions.json` records ten passing metadata/static checks against source
hashes, including UX2 generation consistency, registry mutation regressions,
public claim surfaces, theorem inventory, Python quality, import DAG, and proof
escape checks. This is not the full native UX2/trust gate. The remote protocol
currently rejects `make prove test`; local Lean execution remains prohibited.
No local-execution override was used to turn that limitation into a pass.

Final job `c54d0852-387a-444c-a304-4d133d48f79c` passed all 1529 targets.
Source admission passed against the final canonical files:

```
python3 audit/trio/alloc2/canonical/check_receipt.py audit/trio/alloc2/receipt-c54d0852-387a-444c-a304-4d133d48f79c.json
```

This verifies the named production/test/trust-import build. It does not replace
`make prove test`, the full native UX2 suite, or the trust checker probes.
