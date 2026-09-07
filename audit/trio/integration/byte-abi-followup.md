# Additive byte-copy integration

The late ALLOC-2 input is `e312a7472c32be8536c2284975eaee64d29251f5`.
Its four new ByteABI modules and component evidence are retained. The existing
Step citation already matches the integrated source. Existing primary guarantee,
R1 metadata, historical component identity records and generated UX index remain
the integrated versions; incoming draft metadata does not replace them.

Independent source review found no defect in this additive scope. The modules
prove copied-byte equality, canonical ABI decoding, producer-derived results and
disjoint-array preservation. Explicit range, layout and allocation premises remain;
this is not general malformed-return handling or linked deployed execution.
The Solidity ByteCopy evidence uses a synthetic explicit-opcode harness.

The standalone component receipt compiled relocated dependency bodies. Its source
review does not substitute for root-package elaboration. `RunByteABI.lean` builds
and executes the registered target against the real root dependencies. Its exact
terminal receipt is required before merging this addition. Full `RunValidation`
at `0345a6146cd5cd10b55d318c48c2a4c578ae3bc8` remains a separate prerequisite;
do not describe the newer source as having run those full gates.
