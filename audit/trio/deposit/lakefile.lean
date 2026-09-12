import Lake
open Lake DSL

package trioDeposit where
  srcDir := "../../.."

require lidoProofClosure from "../../.."

/-- Explicit roots only. `.submodules `audit.trio.deposit`` would walk
`audit/trio/deposit/.lake/packages/**` after an isolated `lake` run and
compile dependency sources as if they belonged to this slice. -/
@[default_target]
lean_lib TrioDeposit where
  globs := #[
    .one `audit.trio.deposit.Deposit,
    .one `audit.trio.deposit.RouterDeposit,
    .one `audit.trio.deposit.WithdrawDepositableEther,
    .one `audit.trio.deposit.LiveBeacon,
    .one `audit.trio.deposit.Tests.Verity.Deposit,
    .one `audit.trio.deposit.Tests.Verity.RouterDeposit,
    .one `audit.trio.deposit.Tests.Verity.WithdrawDepositableEther,
    .one `audit.trio.deposit.Tests.Verity.LiveBeacon
  ]
