# SSZ complete declared siblings

Additive source packet on main346 `4207bb0578b0a6821cd1d78b1f3a4bb08f277905`, tree `f67fb673536a4c1be3908c4437b23a9c59cc0bed`. Pinned Solidity core: `17005714f151e5502c559932319a3f2f74ac2436`. No old executor or public file is modified.

`PSsz1.actual_compiled_cl_entry_complete_declared_branch` consumes exactly the same actual `SszCompiledClEntry.run` success and inherited `SszProofCommitted.ShaWidth` as SSZ330. Its conclusion preserves the entire old public branch consequence verbatim, on the same witnesses, before adding:

- `proofWords = declaredWords`, where the latter independently maps every index in `List.range branch.length` through the actual modular cursor and engine `rawWord` load;
- the declared list length equals the actual declared count, which equals the produced generalized index's log2 depth and lies between 3 and 247;
- element `count−2` of this very same complete list equals the slot/proposer pair checked before the root call;
- the independent Branch and typed validator-container tree over the complete list, against the first word of the same actual BEACON_ROOTS response.

The original header/tail/slot/proposer decodes, root request and actual timestamp, exact one-call journal, canonical reply width, produced configuration-dependent index, key slice and decoded fields, credentials, original consumed-list Branch and unchanged executionEnv all remain. There is no additional public fit, frame, count, canonicality, intermediate-success or root/index-equality premise. This is a consumed public strengthening, not an unused arithmetic helper.

## Cursor argument

The generic modular arithmetic and actual-list dichotomy were proved before the public consumer. The executed uint64 count bound implies `32*count < 2^256`. For every uint256 offset and count ≥ 2, the do-while cursor either stops after its first word or consumes every declared indexed word. If the first 32-byte increment is below the modular endpoint, every intervening declared increment is below that endpoint. This includes a wrap on the first increment; a later wrap instead causes immediate exit. Endpoint equality is a stopping case.

The same successful sourceWrapper appends beneath header index 11. Its produced index therefore has depth at least 3; the uint248 result gives depth at most 247. The existing actual Branch's depth equals consumed length. A one-word partial cursor result is thus impossible on whole 330 success, leaving exact equality with the entire declared indexed list. The old slot comparison is transported through the indexed-word lemma at `count−2`.

No domain restriction was introduced to make the dichotomy true. In particular offsets remain unaligned, noncanonical, potentially signed-tail-derived and modular. Counts 0/1 remain explicitly outside the whole-entry-success conclusion, with separate regression cases for the list interpreter. Maximal uint64 count arithmetic and generic dichotomy are checked without constructing an enormous list.

## Evidence and limits

Three normal modules build successfully through `LidoSRv3.Tests.SszDeclaredSiblingsRegression` (1234 dependency jobs). Current setup/options/plugins/traces and source/olean hashes are retained. The validator checks 1217 actual source providers against the selected base or 11 pinned packages and 33 ordinary environment scopes; every scope uses only the ordinary foundations (`propext`, `Classical.choice`, `Quot.sound`, or a subset). Three scopes are the inherited beforeRoot/rootCall/afterRoot phase theorems. Global Trust is not newly run or relabeled foundations-only. Existing All/Trust/lakefile wiring is unchanged.

Sixteen regression theorems cover normal and unaligned offsets, initial versus later wrap, exact endpoint equality, zero/one counts, maximal uint64 arithmetic/dichotomy and the retained 50-sibling vector. Tests compare symbolic engine loads by kernel equality rather than evaluating opaque byte-padding primitives. Exact archived header/count/penultimate bytes are kernel checked, and the penultimate byte array is independently recomputed with Python hashlib from little-endian slot/proposer words. The public theorem is specialized to the exact retained 2180-byte vector, original caller 99, timestamp 123, root response, config and machine context.

The specialization retains exactly the original whole-run success hypothesis. Its successful concrete execution remains the previously reviewed IO/FFI diagnostic, not a new kernel evaluation or a new axiom. Initial attempts to evaluate concrete engine `rawWord`/decoder results with kernel `decide` stopped at the existing opaque `ffi.ByteArray.zeroes`; these failed development attempts are retained. The final tests make no such claim and no FFI assumption is added.

Reuse is exact: all seven old current normal oleans match the accepted 330 integration hashes; the source/review/replay/diagnostic packet, seven full compiler inputs, complete 567-line inspected IR and six FFI source/header bodies with nested repository pins are checked. The archived four whole-entry FFI diagnostics and independent vector are reused. There is no new solc, Forge, SHA or FFI run. `validation/reuse-identities.json` records the exact objects; the old integration/source reviews remain in `audit/ssz-compiled-cl-entry/integration`.

This proves complete *indexed-word* authentication with the existing engine's actual modular/padded load function. It does not prove a canonical ABI serializer, contiguous in-bounds host slice, hash injectivity, a deployed context/locator identity, EIP-4788 history authenticity, gas/termination, general bytecode equivalence or a new failure-world result. All 330 SHA-width, foreign primitive, constructor/configuration, external-call and compiler/source boundaries remain. The current TOPUP typed row verifier is unchanged; replacing it with the standalone 330 harness would still require the separate in-place frame/calldata composition described by the assessment.

## Rechecking

Read `validation/validate.py` before execution. Its default compares recorded JSON and executes only the unchanged checker's isolated ordinary environment probe; `--write` records evidence. It neither rebuilds Lean nor recompiles/reexecutes Solidity/FFI. The probe imports only Lean syntactically and loads the candidate environment as data, so candidate syntax cannot intercept `Lean.collectAxioms`. New source/public/tests introduce no macros, elaborators, axiom/native-decision escape or unsafe implementation.

```sh
python3 audit/ssz-declared-siblings/validation/validate.py
python3 audit/ssz-declared-siblings/seal.py
```

`seal.py --write` records source/dossier hashes; default only compares. Final proof evidence is `validation/build.log`, normal identities, ordinary scopes and validator summary. Failed `development-*.log` files are preserved without being credited as final success. Root owns integration and independent review; this author is not an independent reviewer of this packet.
