import Lake
open Lake DSL

package trioDeposit where
  srcDir := "../../.."

require lidoProofClosure from "../../.."

@[default_target]
lean_lib TrioDeposit where
  globs := #[
    .submodules `audit.trio.deposit
  ]
