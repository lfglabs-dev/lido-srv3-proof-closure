# Producer confirmation of the v0 interface agreement

On 2026-09-07 the producer read the consumer's written acceptance at
`b279d572b694a9e106fdf61337323fbe5f6d3d33`, file
`audit/trio/alloc2/interface-acceptance.md`, blob
`b8c5422b535bc218fbd10d8730cdd41c49c6cb27`:
https://github.com/lfglabs-dev/lido-srv3-proof-closure/blob/b279d572b694a9e106fdf61337323fbe5f6d3d33/audit/trio/alloc2/interface-acceptance.md

The producer explicitly agrees to every v0 meaning in its boundary table:
complete enumeration without filtering, exact capacities including values below
allocation, WC01-equivalent array/demand units, Fin/list representations, bounds
derived from execution rather than assumed, disjoint nonwrapping word-memory
regions, and exact failure distinctions with separate attempted-call instrumentation.
The caller's original allocation values must survive until checked delta conversion.
Compiler memory/ABI realization and the consumer's outer checked conversions are
separate proof obligations; neither side's agreement establishes those proofs.

`Interface.lean` remains byte-identical to the accepted checkpoint
`2a4e9d2a91d257353470677c6101fd91293cf4e4`. The matching written agreement was
sent to ALLOC-2 through the orchestrator for recording. No incompatible change
is proposed or authorized by this document. Independent certification remains open.
