import LidoSRv3.Audit.Source.TopupCorrespondence

/-!
Kill-lines pinning `Source.TopupCorrespondence` `SourceTopupInput`
def-accessor identities that eliminated four free-Bool fields
under chantier 1 Piste A: `callerIsTopUpGateway`, `moduleExists`,
`wcTypeIsType2`, `lidoCanDeposit`.
-/

namespace LidoSRv3.Tests.SourceTopupInputAccessorsKillLines

open LidoSRv3.Audit.SolidityTopup

/-! ## `callerIsTopUpGateway` — def accessor over SRTopupCallerContext. -/

theorem callerIsTopUpGateway_is_def_accessor (inp : SourceTopupInput) :
    inp.callerIsTopUpGateway =
      LidoSRv3.Audit.Source.SRStorageSourceModel.isTopUpGatewayCall
        inp.srCtx := rfl

/-! ## `moduleExists` — def accessor. -/

theorem moduleExists_is_def_accessor (inp : SourceTopupInput) :
    inp.moduleExists =
      LidoSRv3.Audit.Source.SRStorageSourceModel.moduleExists
        inp.srCtx := rfl

/-! ## `wcTypeIsType2` — def accessor. -/

theorem wcTypeIsType2_is_def_accessor (inp : SourceTopupInput) :
    inp.wcTypeIsType2 =
      LidoSRv3.Audit.Source.SRStorageSourceModel.wcIsType2
        inp.srCtx := rfl

/-! ## `lidoCanDeposit` — def accessor over LidoStakingState. -/

theorem lidoCanDeposit_is_def_accessor (inp : SourceTopupInput) :
    inp.lidoCanDeposit =
      LidoSRv3.Audit.Source.LidoStakingStateStorage.canDepositFromStorage
        inp.lidoState := rfl

end LidoSRv3.Tests.SourceTopupInputAccessorsKillLines
