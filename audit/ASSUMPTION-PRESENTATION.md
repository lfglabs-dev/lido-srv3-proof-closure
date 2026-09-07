# How assumptions are shown

The website uses two common explanations: model behaviour, and correspondence
between the reviewed source and deployment. Their text and individual parts live
in `assumption-presentation.json`. The website copies this file from its pinned
proof checkout and checks that both copies match.

These are presentation groups, not new assumptions or proofs. The IDs, scope,
acceptance and risk records in `assumptions.yaml`, and each guarantee's IDs in
`guarantees.yaml`, remain authoritative and unchanged.

For each guarantee, include only the parts whose IDs occur in its assumption
list. Join those parts in catalog order. Omit empty groups. Keep other assumptions
separate, including hashing, arithmetic bounds and deployment constants. Do not
use the text of a complete group for a partial match.

Show the explanation once, with the applicable assumption IDs spaced underneath.
Do not repeat the individual explanations in an expandable block. The catalog
retains the separate parts for traceability. In particular, ALLOC-2 keeps its handwritten
min-first limitation, and SSZ keeps its Yul/interface limitation without acquiring
a Verity-runtime or Solidity-transcription premise it does not declare.

Neither grouping nor a successful deployment check closes a model correspondence
gap. The checks described by the deployment group do not certify the compiler.
