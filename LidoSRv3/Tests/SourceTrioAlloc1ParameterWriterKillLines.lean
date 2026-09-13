import LidoSRv3.Audit.Source.TrioAlloc1.ParameterWriter

/-!
Kill-lines pinning `TrioAlloc1.ParameterWriter` `configWord`
bit-layout and `helper_success_iff` / `helper_stored_share_bound`
identities.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1ParameterWriterKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.ParameterWriter

/-! ## `config_address` — address bits (0..160) unchanged. -/

theorem config_address_restated (original : Word) (input : Input) :
    field (configWord original input) 0 160 = field original 0 160 :=
  config_address original input

/-! ## `config_share` — share bits (192..208) equal input.share on
    valid inputs. -/

theorem config_share_restated
    (original : Word) (input : Input)
    (bound : input.share.val ≤ 10000) :
    field (configWord original input) 192 16 = input.share.val :=
  config_share original input bound

/-! ## `helper_success_iff` — success ↔ validate ok. -/

theorem helper_success_iff_restated
    (l : Layout) (s : Storage) (input : Input) :
    (executeHelper l s input).result = .ok () ↔ validate l s input = .ok () :=
  helper_success_iff l s input

/-! ## `helper_stored_share_bound` — stored share ≤ 10000 bp. -/

theorem helper_stored_share_bound_restated
    (l : Layout) (s : Storage) (input : Input)
    (run : (executeHelper l s input).result = .ok ()) :
    field ((executeHelper l s input).storage (moduleSlot l input.moduleId))
        192 16 ≤ 10000 :=
  helper_stored_share_bound l s input run

/-! ## `helper_revert_restores` — revert restores state + no events. -/

theorem helper_revert_restores_restated
    (l : Layout) (s : Storage) (input : Input) (reason : Failure)
    (run : (executeHelper l s input).result = .error reason) :
    (executeHelper l s input).storage = s ∧
      (executeHelper l s input).events = [] :=
  helper_revert_restores l s input reason run

end LidoSRv3.Tests.SourceTrioAlloc1ParameterWriterKillLines
