# Independent SSZ endian review

Date: 2026-09-09. Reviewer authored TOPUP files, not this SSZ candidate.
Review mode: read-only project inspection; no full or heavy build.
Commit: `5d4522ba594ab66531927ab07b8ab06499ca2077`
Base: `26bbe6ea969aa403002b75296b2175620bc4bf25`.

Verdict: **CLEAN** for this exact committed candidate and its narrow scope.
No blocking findings. This does not accept full SSZ-1 closure.

## Reviewed files

- `LidoSRv3/Audit/Source/SszLittleEndianCorrespondence.lean`
  SHA256 `354768f3a855422699513646e7ec7b06809f7be545fba623ad9659c331e4fdb8`.
- `LidoSRv3/Tests/SszLittleEndianMutants.lean`
  SHA256 `07f0747b127122bf33674fa6e8311d166da19a75898e3cfccca234d0af422cc3`.
- `solidity/test/SszLittleEndian.t.sol`
  SHA256 `70c14a73a76b3b23d39431ea4ed415c2ebfccc325a0dca4823e392b92b41a31f`.
- Complete writer receipt, report, differential checker/output, final source
  and test logs, Axioms.lean and axiom output under
  `/tmp/lido-ssz-endian-20260909/`.
- `/tmp/lido-ssz-solidity-20260909.log`.
- Pinned SSZ.sol helper bodies and their header/validator call sites, and
  BeaconTypes.sol field widths.

## Independent verification

All five writer receipt hashes match current files. SSZ.sol is byte-identical
to `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`; its SHA256 is
`91ef497b972bbee0fe89043034e6bd62fa0c1059f22874d4826bc6164a22009b`.
Read the complete five-stage transcription and independently checked its
literal masks, directions, shifts and fixed word widths against Solidity.

Reran the differential checker. Its output exactly matches the recorded JSON:
2308 vectors, all eight parsed masks/directions/shifts match Lean, and seven
mutations are detected. The checker is a finite source-expression cross-check,
not Solidity execution or a proof. It is correctly labeled as such.

Independently imported the writer's final compiled module and reran its four
axiom queries with the project Lake environment, exit 0. Output is preserved in
`/tmp/lido-ssz-independent-axioms.log`. Integer equivalence, uint64 chunk and
injectivity depend only on `propext`, `Classical.choice`, `Quot.sound`; boolean
chunk uses `propext`, `Quot.sound`. No native checker or custom axiom remains.
The current source uses interval_cases on bit positions with the input word
universally quantified, and contains no sorry/admission/bv_decide/native_decide.

Inspected the actual Solidity harness and execution log: solc 0.8.25 compiles
the imported pinned library; 4 tests pass, including 1024 fuzz cases for each
integer/uint64 test, both booleans, and all 256 one-hot input bits. The reference
constructs the bytes32 value octet by octet, independently of the source masks.
The uint64 padding assertion tests the low 192 output bits. This is finite
compiler/EVM testing, not universal compiler correspondence.

No source theorem rebuild was repeated: the writer's completed source/test
commands and matching hashes were inspected. Axiom import and Python checks
were independently executed. The project working files were not edited.

## Semantic assessment

The specification is independent of the five swap stages: it concatenates
input octets in ascending significance order. Its bytes32 convention puts the
first serialized octet in the high byte, matching the explicit byte-vector
witness and Solidity reference. The uint64 specialization widens with zero
bits and specifies 24 zero padding bytes; bool specifies one byte followed by
31 zeros. Injectivity concerns serialization only, not hashing.

The theorem scope is useful and correctly bounded. It proves all input bits,
not merely the finite regression vectors. The model uses the actual 256-bit
integer overload, avoiding the earlier uint64 truncation issue, while the
uint64 specialization matches header and validator field types. Tests expose
wrong-end booleans, input truncation and missing permutation stages.

No end-to-end SSZ, Merkle-path, field-selection, ABI/memory, SHA-256/precompile,
compiler/EVM or deployment-provenance claim follows. Source transcription
remains a source-review boundary, mitigated here by exact comparison and the
imported Solidity tests. The prior structural uniqueness premise is not
silently corrected or accepted by this result. All these limits are explicit
in the writer report and source header.

No blocking findings at the reviewed hashes.

## Exact committed-candidate audit

After integration, verified HEAD is exactly
`5d4522ba594ab66531927ab07b8ab06499ca2077` and reviewed the full 12-file diff
from `26bbe6ea969aa403002b75296b2175620bc4bf25`. Source, tests and harness
match the hashes reviewed above. Recomputed **all 16 receipt hashes against
committed git objects** (Solidity via its pinned submodule git object); all
match. Included logs, project config, manifest, report, Axioms.lean and script
are therefore tied to this exact candidate.

The committed differential script differs from the original only by locating
the repository relative to itself. Independently ran this portable version;
its JSON exactly matches the committed receipt (2308 vectors/seven mutations).
The Solidity command, compiler version, run counts and log scope are explicit
in the final receipt. Empty source/test logs are accompanied by recorded
successful exit statuses, not presented as standalone evidence.

Checked the change of integration base from writer HEAD `90111990` to
`26bbe6ea`: ten independent ADDRESS/DEPOSIT audit files changed, none imported
by this SSZ slice. The Lean toolchain, manifest and lakefile used by the slice
are hash-verified. No shared foundation, registered parent, metadata index,
site claim or source pin is changed by the SSZ commit.

Untracked TOPUP CallHistory work belongs to this reviewer's separate task and
is not part of the reviewed SSZ commit. No project files were written by this
review. The complete candidate is CLEAN for integration after the stated
proportionate checks; full SSZ-1 and deployment guarantees remain open.
