import LidoSRv3.Audit.Source.TrioReserve1.ABI

/-! Physical StakingRouter credentials adapter at core@17005714.
SRStorage's ERC-7201 root is a checked source constant; module mapping Keccak
is explicit and opaque, applied to the actual two ABI words. No arbitrary
storage reader, runtime identity or hash correctness is assumed proved. -/
namespace LidoSRv3.Audit.Source.TopupRouterCredentials
open TrioReserve1 Live

abbrev Keccak := Bytes → Word

def routerRoot : Nat :=
  0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000

def moduleSlot (hash : Keccak) (moduleId : Word) : Nat :=
  (hash (encode 32 moduleId.val ++ encode 32 routerRoot)).val

/-- SRTypes.ModuleStateConfig: address20, four uint16, status uint8, type uint8. -/
def typeOf (config : Word) : Nat := config.val / 2^232 % 256

def raw (router : Address) (w : World) : Word :=
  w.core.readContractSlot router.val (routerRoot + 4)

def credentialType (hash : Keccak) (router : Address) (moduleId : Word) (w : World) : Nat :=
  typeOf (w.core.readContractSlot router.val (moduleSlot hash moduleId))

def octets (value : Word) : List Nat := (encode 32 value.val).map UInt8.toNat

theorem octets_length (value : Word) : (octets value).length = 32 := by
  simp [octets,ABI.encode_length]

theorem octets_bounded (value : Word) : ∀ b ∈ octets value, b < 256 := by
  intro b hb
  obtain ⟨v,_,rfl⟩ := List.mem_map.mp hb
  exact v.toNat_lt

theorem octets_encode_roundtrip (value : Word) : decode (encode 32 value.val) = value.val := by
  exact ABI.decode_encode_bounded 32 value.val value.isLt

theorem typeOf_bound (config : Word) : typeOf config < 256 := Nat.mod_lt _ (by decide)

/-- Independent packed-field selection: lower 232 bits and upper 16 bits
cannot affect the selected uint8. The input word's own range is unchanged. -/
theorem typeOf_packed (config : Word) (low typ high : Nat)
    (hl : low < 2^232) (ht : typ < 256)
    (hc : config.val = low + typ * 2^232 + high * 2^240) : typeOf config = typ := by
  unfold typeOf
  rw [hc]
  omega

/-- Source setType viewed as byte selection, retaining every lower octet. -/
def selectedBytes (hash : Keccak) (router : Address) (moduleId : Word) (w : World) : List Nat :=
  credentialType hash router moduleId w :: (octets (raw router w)).drop 1

theorem selected_length (hash : Keccak) (router : Address) (moduleId : Word) (w : World) :
    (selectedBytes hash router moduleId w).length = 32 := by
  simp [selectedBytes,octets_length]

end LidoSRv3.Audit.Source.TopupRouterCredentials
