# P-ALLOC-2 official loop-semantics provenance

The repository pins `lfglabs-dev/verity` at
`04729a9de9099e065dd09283e4f733a5fd4c2a16`. That revision exports
`Verity.Proofs.LoopSimulation`; the prior note claiming its absence applied
only to the historical `d2d4a18a4d7021adcd90d4b03e619affe506dd54` pin.

This provenance correction does not enlarge P-ALLOC-2's assurance claim. Its
current MODEL/SOURCE status and remaining proportional-amount correspondence
scope are recorded in `audit/guarantees.yaml`, `audit/source-map.yaml`, and
`audit/STATUS.md`. Any future SOURCE-to-official-semantics bridge must use the
pinned public loop API and remain subject to the existing proof and trust
surface checks; this document introduces no interpreter, `unsafeYul`, axiom,
or substitute proof surface.
