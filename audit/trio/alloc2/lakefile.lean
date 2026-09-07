import Lake
open Lake DSL

/- Isolated Init-only slice verification. This is not the repository production,
test or trust target and must never be reported as any of those gates. -/
package trioAlloc2Slice where
  srcDir := "../../.."

@[default_target]
lean_lib TrioAlloc2Slice where
  globs := #[
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Word,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.MemoryPrefix,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Arithmetic,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Step,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.ScanBounds,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.ScanCorrespondence,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Selection,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Totality,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.LoopTotality,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Errors,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.ChoiceCorrespondence,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.StepCorrespondence,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.SpecProgress,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.LoopCorrespondence,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Spec,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Loop,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.StepBounds,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.RowBounds,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.ParentArraySafety,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.ParentValues,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.LoopBounds,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Conservation,
    .one `LidoSRv3.Tests.TrioAlloc2.Step,
    .one `LidoSRv3.Tests.TrioAlloc2.Loop,
    .one `LidoSRv3.Tests.TrioAlloc2.Sequential,
    .one `LidoSRv3.Tests.TrioAlloc2.DifferentialVectors,
    .one `LidoSRv3.Tests.TrioAlloc2.Axioms
  ]
