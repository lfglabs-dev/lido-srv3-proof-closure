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
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Step,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Spec,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.Loop,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.StepBounds,
    .one `LidoSRv3.Audit.Source.TrioAlloc2.LoopBounds,
    .one `LidoSRv3.Tests.TrioAlloc2.Step,
    .one `LidoSRv3.Tests.TrioAlloc2.Loop,
    .one `LidoSRv3.Tests.TrioAlloc2.Axioms
  ]
