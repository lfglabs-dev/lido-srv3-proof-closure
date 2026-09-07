import Lake
open Lake DSL

/- Candidate composition against a pinned producer snapshot. Not the root build. -/
package trioAlloc2Composition where
  srcDir := "../../../.."

@[default_target]
lean_lib TrioAlloc2Composition where
  globs := #[
    .submodules `LidoSRv3.Audit.Source.TrioAlloc1,
    .submodules `LidoSRv3.Audit.Source.TrioAlloc2,
    .one `audit.trio.alloc2.composition.Composition,
    .one `audit.trio.alloc2.composition.LibraryABI,
    .one `audit.trio.alloc2.composition.LibraryABIVectors,
    .one `audit.trio.alloc2.composition.Parent,
    .one `audit.trio.alloc2.composition.ParentVectors
  ]
