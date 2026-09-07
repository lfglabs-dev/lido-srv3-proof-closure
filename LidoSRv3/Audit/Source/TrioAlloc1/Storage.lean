import LidoSRv3.Audit.Source.TrioAlloc1.Interface

/-!
Physical word layout of SRStorage and SRTypes at core@17005714.
The hash implementation is an explicit parameter, not an injectivity axiom.
`routerSlot` must be related to the ERC-7201 expression by the deployment relation.
No count cap, address uniqueness, or share<=10000 assumption is imposed on reads.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1

def word (n : Nat) : Word := ⟨n % 2^256, Nat.mod_lt _ (by decide)⟩
def byte (n : Nat) : Byte := ⟨n % 256, Nat.mod_lt _ (by decide)⟩

def encodeWord (w : Word) : Bytes :=
  (List.range 32).map fun i => byte (w.val / 256^(31-i))

abbrev Storage := Word → Word

structure Layout where
  routerSlot : Word
  keccak : Bytes → Word

def countSlot (l : Layout) : Word := word (l.routerSlot.val + 1)
def idSlot (l : Layout) (i : Nat) : Word :=
  word ((l.keccak (encodeWord (countSlot l))).val + i)
def moduleSlot (l : Layout) (id : Word) : Word :=
  l.keccak (encodeWord id ++ encodeWord l.routerSlot)

def field (packed : Word) (offset width : Nat) : Nat :=
  packed.val / 2^offset % 2^width

structure StoredModule where
  identity : ModuleIdentity
  share : Fin (2^16)
  status : Fin (2^8)
  wcType : Fin (2^8)
  accountingExited : Fin (2^64)
  deriving DecidableEq, Repr

def readModule (l : Layout) (s : Storage) (i : Nat) : StoredModule :=
  let id := s (idSlot l i)
  let slot := moduleSlot l id
  let packed := s slot
  { identity := { moduleId := id
                  moduleAddress := ⟨field packed 0 160, Nat.mod_lt _ (by decide)⟩ }
    share := ⟨field packed 192 16, Nat.mod_lt _ (by decide)⟩
    status := ⟨field packed 224 8, Nat.mod_lt _ (by decide)⟩
    wcType := ⟨field packed 232 8, Nat.mod_lt _ (by decide)⟩
    accountingExited := ⟨field (s (word (slot.val + 2))) 64 64,
      Nat.mod_lt _ (by decide)⟩ }

def routerOrder (l : Layout) (s : Storage) : List ModuleIdentity :=
  (List.range (s (countSlot l)).val).map fun i => (readModule l s i).identity

theorem stored_share_width (l : Layout) (s : Storage) (i : Nat) :
    (readModule l s i).share.val < 2^16 := (readModule l s i).share.isLt

theorem stored_exited_width (l : Layout) (s : Storage) (i : Nat) :
    (readModule l s i).accountingExited.val < 2^64 :=
  (readModule l s i).accountingExited.isLt

end LidoSRv3.Audit.Source.TrioAlloc1
