# P-ADDRESS-1.denote-admission

> Auditor note (2026-08-21). I treat
> `LidoSRv3/Audit/Verity/AddressAdmission.lean` as the authority. I use the
> registry and the existing report only to check how that theorem is described.
> This is a subordinate admission probe, not the owner P-ADDRESS-1 guarantee.

## A. Product note

I read this row as a narrow executable semantics check for one audit-authored
function. The function is named `claim()`, takes no arguments, requires the
global `paused` word to be zero, requires `balances[msg.sender]` to be nonzero,
and returns that balance. It does not write storage. No pinned Lido Solidity
function has been shown to have this body.

The useful part is that the caller is not an unconstrained parameter supplied
to a mathematical function. `run` evaluates the EDSL body with Verity's
`denoteFunction`; `withTransactionContext` installs the transaction sender in
contract state, and `.caller` reads it from there. `run_claim_success` reduces
that execution to the two storage reads that actually control success.

The checked theorem, `admission_address_equivariant`, ranges over two canonical
160-bit sender values, an arbitrary mapping-slot oracle, and an arbitrary world.
It swaps the two caller-indexed balance words, assumes neither word aliases the
pause slot, and proves that caller 1 succeeds before the swap exactly when
caller 2 succeeds after it. The concrete witnesses show both success and
failure, and the owner-gated mutant shows that adding a fixed privileged gate
can break the relation.

I would describe the product result this way: the official Verity denotation of
this audit probe is caller-relative on its admission bit, provided its balance
slots do not alias the pause slot. I would not describe it as evidence about a
deployed Lido claim path. It proves neither pinned-Solidity correspondence nor
successful post-state renaming, and it does not compare the returned amount.
Those omissions are not incidental. The modeled function is a read-only probe,
so it cannot exercise the address writes that make the owner guarantee
substantive.

## B. Proof audit

**B1. The theorem executes a real denotation, but the program under that
denotation is audit-authored.** I confirmed that `run_claim_success` unfolds
`denoteFunction`, parameter binding, statement execution, expression
evaluation, transaction context, and storage reads. This is stronger than an
opaque `fn` assumption and it makes the success bit computational.

The execution does not establish source fidelity. `claim` is constructed in
`AddressAdmission.lean`, `spec.functions` contains only that constructed body,
and the registry accurately says "no pinned Solidity correspondence." The name
`claim()` is therefore potentially misleading. It is not
`WithdrawalQueue.claimWithdrawalsTo`, and it is not one of the four
storage-writing entrypoints in the owner P-ADDRESS-1 theorem.

**B2. `PauseDisjoint` is load-bearing.** The proof uses both disjointness
hypotheses only to show that `swapBalances` leaves the pause read unchanged.
Dropping either premise makes the statement false for the arbitrary oracle that
the theorem quantifies over.

The existing report's first alias scenario assigns both `paused = 0` and
`balances[a1] = 7` to the same aliased word, which is not one world. A valid
counterexample is simpler. Let `balanceSlotOf a1` equal the pause slot, let
`balanceSlotOf a2` be a distinct slot `q`, and set the pause word to 7 and word
`q` to 0. Caller 1 is rejected because the contract is paused. The swap writes
0 to the pause word and 7 to `q`, after which caller 2 is admitted. Thus the
side condition is real, even though the report's particular valuation should
be corrected.

Nothing here proves that Solidity's concrete mapping hash is disjoint from the
scalar slot. That is acceptable for this row only if `PauseDisjoint` remains
visible as an assumption rather than being read as a discharged layout fact.

**B3. The 160-bit sender bounds narrow the public statement correctly, but the
proof does not use them.** The current theorem has `_ha1 : a1 <
Address.modulus` and `_ha2 : a2 < Address.modulus`. This closes the prior
surface problem in which raw natural senders differing by `2^160` could be
described as different Ethereum addresses even though `callerKey` masks both
to the same address. The arguments are intentionally unused because the
denotation masks every sender anyway. I read them as domain restrictions for
the public claim, not as load-bearing proof hypotheses.

The theorem does not require the two callers or their balance slots to be
distinct. That is mathematically sound for equivariance: equal callers and
colliding caller slots make the swap degenerate. It does mean the theorem is
not a storage-separation theorem and should not be cited as one.

**B4. The observation is admission only.** The conclusion compares
`DenoteResult.success` and nothing else. It does not compare the returned
balance, revert reason, logs, ETH, or final storage. In particular, a mutant
that preserved the two `require` statements but returned a caller-dependent
wrong amount would satisfy this theorem.

This is also why "post-state equivariance is out of scope" is more than a
registry caveat. `claim` performs no write, so adding a post-state equality for
this body would not test the owner's address-writer property. A meaningful
post-state child needs a storage-writing pinned entrypoint and a relation over
the addresses that entrypoint writes.

**B5. The direct-body runner is not ABI dispatch evidence.** `run` receives a
`FunctionSpec` and passes that body directly to `denoteFunction`. `txFrom`
always carries the `claim()` selector and empty arguments. This is why the same
runner can execute `ownerGated` even though `ownerGated` is absent from
`spec.functions`. The mutant is valid evidence that the denotation of a changed
body can distinguish the property, but it does not show that selector dispatch
would reach that body in a compiled contract.

**B6. The non-vacuity package is useful, with one labeling defect.** The three
positive and negative witnesses establish that the honest probe is not
constant: balance and pause each affect success. The owner-gated witness uses
canonical callers 1 and 2 and genuinely falsifies caller-swap admission for the
mutated body.

The mutant theorem omits the two address-range premises from the exact
`admission_address_equivariant` quantifier shape, although its concrete witness
satisfies them. More importantly, the comment above `ownerGateKillLine` calls
it a kill-line for the "registered P-ADDRESS-1 parent." It is not. It belongs
to this subordinate denote-admission row; the owner parent now has its own
source-model fixed-owner kill-line. The report and registry mostly make that
separation correctly, but the Lean comment should too.

**B7. The historical report header is stale.** The text preserved below says
this child assumes `A-SOURCE-SHAPED` and that the parent is OPEN / PARTIAL.
Current `guarantees.yaml` lists only `A-VERITY-SCAFFOLD` on this subordinate
row, marks its abstract plane OPEN and its Verity theorem CHECKED, and records
the owner P-ADDRESS-1 parent separately as CHECKED. I would not carry the old
header into current status reporting.

**Ranked recommendations.**

1. Keep this theorem subordinate and change the row's `next_gate`. Do not say
   to compose this audit-authored, admission-only body into the owner guarantee.
   Composition should require a pinned entrypoint and a successful post-state
   relation.
2. If protocol relevance is wanted, replace the probe with one of the owner's
   pinned permissionless writers and execute both its admission gates and its
   address writes. Keep this toy only as a denotation regression test.
3. Correct the impossible pause-alias valuation in the existing report and
   retain the valid counterexample above. Either derive slot disjointness for a
   concrete compiled layout or continue to expose `PauseDisjoint` as an
   assumption.
4. Rename the Lean kill-line comment to the subordinate row and, for exact
   shape discipline, include the two 160-bit premises in the mutant
   quantification.
5. Use a dispatching transaction theorem if selector-to-body binding is meant
   to be evidence. The current direct-body theorem should remain described as
   `denoteFunction` evidence.
6. Do not add a vacuous post-state theorem for this read-only body. Compare the
   returned value if the row is kept as admission evidence, and reserve
   post-state equivariance for a real writer.

## Second pass, same day: product note and machine-checked proof audit

> Second reviewer (2026-08-21). Written independently against
> `LidoSRv3/Audit/Verity/AddressAdmission.lean`,
> `LidoSRv3/Audit/Guarantees/PAddress1.lean`,
> `LidoSRv3/Tests/AddressSourceMutants.lean`, `LidoSRv3/Audit/Trust.lean`,
> `audit/guarantees.yaml`, `audit/source-map.yaml`, and the pinned verity
> dependency `a063bfc`. First person, no em dashes. Lean is the authority. I
> arrived after the note above, so I state where I confirm it, where I extend it,
> and where I disagree with it, rather than repeating it.
>
> I was asked to read a `FILES.md`. There is no file of that name anywhere in the
> tracked tree or in its git history, so I worked from the Lean and the YAML. The
> pinned Lido Solidity is also absent from this tree, so `WithdrawalQueue` line
> numbers below are carried from the round-1 text and not re-verified.
>
> Everything I mark "checked" was confirmed by building a throwaway probe,
> `LidoSRv3/Tests/AddressAdmissionAuditProbe.lean`, at the same pin. It is
> committed alongside this note and is explicitly not evidence: no facade imports
> it, `Trust.lean` does not print it, and `audit/guarantees.yaml` does not name
> it.

### A. Product note

This is the smallest row in the campaign and I would present it as such. It asks
whether a permissionless entrypoint can branch on who is calling, and it answers
that question for one entrypoint that the audit wrote itself.

The asset here is the interpreter, not the program. `run_claim_success` evaluates
the official `Compiler.CompilationModel.Denote.denoteFunction` down to the two
storage reads that decide admission, and the caller reaches those reads the way a
caller actually would: `withTransactionContext` installs
`DenoteTransaction.sender` into `ContractState.sender` and `Expr.caller` reads
that field. So the caller is an input to a real evaluator rather than an index on
an abstract function, and the three non-vacuity witnesses show each gate moving
the success bit on its own. That is worth more than the size of the program
suggests, because most of this campaign's address reasoning is over hand-written
`admitted` predicates.

Two things I want to record as positive, since audits tend to list only holes.
`audit/source-map.yaml` has no target for `P-ADDRESS-1.denote-admission` at all,
so unlike some rows here this one advertises no pinned coverage it does not have;
the four mapped spans (`WithdrawalQueueERC721.transferFrom`,
`WithdrawalQueue.requestWithdrawals`, `WithdrawalQueue.claimWithdrawalsTo`,
`WstETH.unwrap`) belong to the parent. And `Trust.lean` prints all six named
theorems of the module as depending on `propext` and `Quot.sound` only, so the
registered evidence for this row contains no `sorry` and no `native_decide`.

The claim I would sign: on an audit-authored two-gate permissionless read
evaluated by the official Verity denotation, whether the call succeeds is a
function of the pause word and of the caller's own balance entry and of nothing
else about the caller, provided the storage layout does not alias that entry onto
the pause word; and adding one privileged-role test to that entrypoint breaks the
property. I would not tell a reader that a deployed Lido entrypoint is
caller-blind, that a successful call renames its post-state, or that the *amount*
paid out is caller-independent. A reader will assume the third, and B4 below shows
it is false of the registered statement. It is also worth saying plainly that this
child and the parent share no definitions: `PAddress1.lean` does not import
`AddressAdmission`, so there is no facade route from one to the other.

### B. Proof audit

**B1. The two address-range binders are inert, and I read that differently from
the note above. Checked.** `admission_address_equivariant`
(`AddressAdmission.lean:220-229`) binds `_ha₁ : a₁ < Verity.Core.Address.modulus`
and `_ha₂`. The proof is three tactics and uses neither. I reproved the
conclusion with both deleted and the same script:

    theorem admission_equivariant_without_address_bounds (oracle) (a₁ a₂) (world)
        (h₁ : PauseDisjoint oracle a₁) (h₂ : PauseDisjoint oracle a₂) :
        (run oracle claim a₁ world).success =
          (run oracle claim a₂ (swapBalances oracle a₁ a₂ world)).success

The first pass reads these binders as intentional domain restrictions for the
public claim. I do not, for two reasons. First, this campaign has its own
load-bearing criterion and applied it to this row's parent in the opposite
direction: wave 4 dropped `_hWellFormed` and `_hNotSingleton` from
`universal_address_writer_equivariance` because unused binders read as
restrictions without being any, and wave 5 dropped `hScope` for the same reason.
Applying one rule to the parent and its inverse to the child is the part I would
not sign. Second, the resolution table below records round-1 issue 8, the `2^160`
aliasing finding, as closed under class `B`, "Lean premise or encoding repair that
keeps the existing proof", with the note "Facade now requires `a < 2^160`". A
premise the proof ignores is not an encoding repair; it changes who may
instantiate the theorem, not what the theorem says. And "facade" is the wrong
word: `audit/guarantees.yaml` registers
`LidoSRv3.Audit.Verity.AddressAdmission.admission_address_equivariant` directly,
so the bound sits on the registered theorem itself. If the row wants to disclose
the masking, the honest place is the summary, not a binder.

**B2. Senders differing by `2^160` are one account, which is why the statement
holds for them. Checked.** `callerKey` is `(wordToAddress (sender : Uint256)).val`
(`:139-140`) and `Address.ofNat` keeps 160 bits:

    theorem high_bit_callers_share_a_balance_slot :
        callerKey (1 + 2 ^ 160) = callerKey 1 ∧
          balanceSlotOf witnessOracle (1 + 2 ^ 160) = balanceSlotOf witnessOracle 1

For such a pair `swapBalances` writes each of two identical slots back to itself,
both runs read the same two words, and the bits agree. So round-1 issue 8's
counterexample is still live, and B1's inert premise is exactly what hides it.

**B3. `PauseDisjoint` is necessary, and the first pass is right that round 1's
counterexample was inconsistent. Checked.** Round-1 issue 2 sets the aliased word
to `0` as `paused` and to `7` as `balances[a₁]`, which is not one world. The first
pass's replacement valuation is correct, and I turned it into a machine-checked
refutation so the side condition's necessity is a theorem rather than a scenario:

    theorem pause_disjoint_is_load_bearing :
        ¬ ∀ oracle a₁ a₂ world, a₁ < Address.modulus → a₂ < Address.modulus →
            (run oracle claim a₁ world).success =
              (run oracle claim a₂ (swapBalances oracle a₁ a₂ world)).success

The witness is `aliasOracle`, which sends caller `1`'s balance entry to the pause
slot and caller `2`'s to slot `102`, over a world whose pause word is `7`. Caller
`1` is rejected because the alias makes the contract paused; the swap clears the
pause word and moves `7` into caller `2`'s entry, so caller `2` is admitted. Both
halves are `decide`-checked. I would put this theorem in the module: a named
witness that the premise cannot be dropped is stronger evidence for a side
condition than prose, and it costs nine lines.

**B4. A caller-discriminating payout satisfies the registered claim. Checked.**
The first pass observes that a mutant preserving the two `require`s but returning
a caller-dependent amount would pass. I built that mutant and derived the
registered theorem's exact shape for it. `payCaller` is `claim` with the return
expression changed from the caller's balance to `.caller` itself:

    theorem payCaller_admission_equivariant (oracle) (a₁ a₂) (world)
        (_ha₁ …) (_ha₂ …) (h₁ h₂ : PauseDisjoint …) :
        (run oracle payCaller a₁ world).success =
          (run oracle payCaller a₂ (swapBalances oracle a₁ a₂ world)).success

    theorem payCaller_return_value_discriminates :
        (run witnessOracle payCaller 1 witnessWorld).returnValue = some 1 ∧
          (run witnessOracle payCaller 2
            (swapBalances witnessOracle 1 2 witnessWorld)).returnValue = some 2

So an entrypoint whose payout is literally the caller's identity is CHECKED on
this row. `DenoteResult` (`Verity/Core/Model/Denote.lean:1356-1361`) carries
`success`, `returnValue`, `finalStorage` and `events`, and the registered theorem
equates the first. The repair is one projection wide, and I can report its cost
exactly: writing `run_payCaller_success` required no new machinery, the
`run_claim_success` script went through unchanged on the mutated body. That makes
"compare the returned value" the cheapest real strengthening available to this
row, and it also hands the row a second kill-line for free.

**B5. The kill-line in the registered premise shape. Checked.** I agree with the
first pass that `ownerGateKillLine` (`:332-336`) omits the registered theorem's
two address-range premises, and that refuting a `∀` with fewer hypotheses is not
the same as negating the registered predicate shape. Here is the version with the
premises retained; the cost is two `decide`s, since the witness callers are `1`
and `2`:

    theorem owner_gate_kill_line_with_parent_premises :
        ¬ ∀ oracle a₁ a₂ world, a₁ < Address.modulus → a₂ < Address.modulus →
            PauseDisjoint oracle a₁ → PauseDisjoint oracle a₂ →
            (run oracle ownerGated a₁ world).success =
              (run oracle ownerGated a₂ (swapBalances oracle a₁ a₂ world)).success

Note the interaction with B1. If the binders come off the theorem, this becomes
the existing statement and there is nothing to do; if they stay, the refutation
has to carry them. Either resolution is fine and the current pair is the one
combination that is not.

**B6. The module's stated reason for avoiding external calls is stale at this
tree's own pin.** The header (`:22-28`) says the module deliberately avoids
`Contracts.Common.externalCallBind` because "at Verity pin `04729a9` that
combinator is `pure ()` (`Contracts/Common.lean:582`)", so a call-dependent
admission would be vacuous. This tree pins verity at `a063bfc`
(`lake-manifest.json`). At that revision `externalCallBind` is
`Contracts/Common.lean:642-653` and is not `pure ()`: it appends an entry to
`ContractState.calls`, succeeds when `externalCallStubSuccess name` holds, and
reverts otherwise. `externalCallStubSuccess` is `name != "fail"` (`:580-581`) and
the returned word is `externalCallStubWord` (`:572-575`). Line `582` at this pin
sits inside that helper.

I am not asking for the scope decision to be reversed. I am pointing out that the
reason has changed and that the new reason is the more interesting one: at this
pin a call-dependent admission would be sensitive to a compile-time callee name
rather than to anything in the world, so the entrypoint would still have no
modeled callee. A reader who checks the citation today finds a different function.

**B7. Two bookkeeping items beyond the ones the first pass lists.** Its B7
correctly flags the stale header. Two more of the same kind. The Modeling section
below still says "`A-SOURCE-SHAPED` is listed but there is no source plane", and
round-1 issue 4 is an issue about an assumption this row no longer carries, since
`audit/guarantees.yaml` lists `A-VERITY-SCAFFOLD` alone. And round-1 issue 1's
closing sentence, "Parent remains OPEN", is stale in the same way as the header:
the parent is CHECKED on both planes since wave 5. Issue 1's substance, that no
`claim()` of this shape exists on the pinned contracts, is untouched by the
correction.

### Ranked recommendations (second pass)

I keep the first pass's list and reorder around what I checked. Where we agree I
say so rather than restating.

1. Compare the return value, and register the `payCaller` mutant as a second
   kill-line (B4). This is the only change here that closes a gap a reader will
   actually assume closed, and the reduction script already exists.
2. Resolve B1 and B5 together: drop `_ha₁`/`_ha₂` and leave the kill-line as it
   is, or keep them and add the two `decide`s to the kill-line. Reclassify
   round-1 issue 8's close: the `2^160` identification is a scope sentence for the
   row summary, not a class-`B` premise repair, and it is not on a facade.
3. Add `pause_disjoint_is_load_bearing` to the module (B3) and correct round-1
   issue 2's valuation. A named refutation is the right form for a side condition
   the row leans on.
4. Agreed with the first pass on `next_gate`: this body cannot compose into the
   parent's post-state conjunct, because it writes nothing, so any post-state
   statement about it is trivially true. I would add the frame theorem over
   `DenoteResult.finalStorage` that turns "writes no storage" from a comment into
   a fact, and then say composition needs a different program.
5. Refresh the `externalCallBind` citation to `a063bfc` and restate the reason
   (B6).
6. Finish the bookkeeping sweep in B7 alongside the first pass's B7, and keep the
   positive findings visible: no source-map target, and `propext`/`Quot.sound`
   only in `Trust.lean`.

## Existing report and issue history

Theorem: `AddressAdmission.admission_address_equivariant`.
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.
Parent `P-ADDRESS-1` is OPEN / PARTIAL and has no file here.

## Intent

Permissionless Lido entrypoints (e.g. a user claiming or transferring their own position) should not branch on *who* the `msg.sender` is, except through that sender’s own data. Swapping two ordinary users and their address-indexed state should preserve admit/reject. That is the anti-discrimination half of P-ADDRESS-1 (the other half, post-state equivariance, is not this child). Singleton-actor functions (`withdrawWithdrawals`, `addConsolidationRequests`, …) are intentionally excluded.

## Modeling

- The entrypoint is **audit-authored** `claim()` (`AddressAdmission.lean:82–89`): `require(paused == 0); require(balances[msg.sender] > 0); return balances[msg.sender]`. It is **not** extracted from pinned Lido Solidity. YAML fidelity: “no pinned Solidity correspondence.”
- Evaluated by official `Compiler.CompilationModel.Denote.denoteFunction`, which installs `DenoteTransaction.sender` into `ContractState.sender`. That is the load-bearing modeling choice: the caller is a real denotation input, not an extra parameter on an abstract `fn`.
- No external CALLs (at the Verity pin, `externalCallBind` was `pure ()` and would have made call-dependent admission vacuous).
- `PauseDisjoint oracle a`: the mapping-slot oracle does not send `balances[a]` to the pause slot. Stated explicitly.
- `A-SOURCE-SHAPED` is listed but there is no source plane. `A-VERITY-SCAFFOLD`.
- Post-state equivariance is out of scope (`claim` writes nothing).

## Proof

**`run_claim_success`.** Unfold `denoteFunction` / `execStmt` / `evalExpr` down to the two storage reads; case split on `paused = 0` and `balances[a] > 0`. Result: `success = admitted`.

**`admission_address_equivariant`.** Rewrite both sides with `run_claim_success`. `swapBalances` exchanges the two balance slots. `swap_reads_paused` (uses `PauseDisjoint` twice) says the pause word is unchanged; `swap_reads_balance` says `balances[a₂]` after the swap is `balances[a₁]` before. The two `admitted` bits are therefore equal.

**Non-vacuity (same module, not the YAML theorem).** Concrete `witnessOracle` / `witnessWorld`: caller 1 with balance 7 is admitted; caller 2 with 0 is rejected; pause rejects caller 1. `ownerGated_not_admission_equivariant` is a negated `∀`: the same entrypoint plus `require(caller == owner)` is *not* equivariant on that witness (owner 1 admitted, swapped caller 2 rejected). Proof: plug the witness into the claimed `∀` and `Bool.noConfusion`.

## Issues

## Resolution

**Restated Lean/English.** Parent `universal_address_writer_equivariance` names nonzero callers. This child remains audit-authored `claim()`, not WQ.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1, 3–7, 9–16 | A | Audit-authored `claim()`; parent stays OPEN; no WQ claim implemented. `A-SOURCE-SHAPED` removed from this child. |
| 2 | keep | `PauseDisjoint` remains required. |
| 8 | B | Facade now requires `a < 2^160`. |


1. **This is not a Lido function; the parent source-map is a different surface.**
   No `claim()` of this shape exists on the pinned contracts. `audit/source-map.yaml` for parent `P-ADDRESS-1` maps `WithdrawalQueueERC721.transferFrom`, `requestWithdrawals`, `claimWithdrawalsTo`, and `WstETH.unwrap` — none of which this child runs.

   *Scenario.* `claimWithdrawalsTo(owner, recipient)` pays `recipient`, not `msg.sender`. Two swapped callers with swapped NFT ownership can still send ETH to an un-renamed recipient (property B failure, and possibly property A if recipient-zero / pause differs). The CHECKED child cannot see that function. Parent remains OPEN.

2. **`PauseDisjoint` is a real side condition — dropping it breaks the property.**
   *Counterexample.* `oracle.mappingSlot balancesSlot (callerKey a₁) = pausedSlot` (alias). World: `paused = 0`, `balances[a₁] = 7`, `balances[a₂] = 0`. `admitted a₁ = true`. `swapBalances` writes `balances[a₂]=0` into the pause slot. `admitted a₂` on the swapped world sees `paused ≠ 0` and is `false`. Equivariance fails. The theorem excludes this by hypothesis. A Solidity compiler that hashed `keccak(abi.encode(addr, balancesSlot))` onto slot 4 for some `addr` would be exactly this oracle. The project does not prove the deployed keccak never collides with the pause slot (and this `claim` is not deployed).

3. **Admission only, and `claim` has no successful state change.**
   P-ADDRESS-1 as specified in `PAddress1.address_nondiscrimination` is admission ∧ post-state equivariance. `claim` writes nothing — it does not even clear `balances[caller]`, so it is a gated read, not a claim.

   *Scenario.* A real `WithdrawalQueue.requestWithdrawals` admits two swapped users and then stores `msg.sender` as owner of the NFT request. Property A can hold while property B fails (the stored owner is not the renamed address). This child cannot see that write. YAML `fidelity.missing: parent guarantee composition` is accurate; CHECKED is still a stronger word than “toy admission lemma.”

4. **`A-SOURCE-SHAPED` is listed and unused.**
   There is nothing source-shaped. The assumption’s risk (“inputs are not extracted from independently verified pinned Solidity spans”) is exactly the situation, and it is not discharged.

   *Scenario.* Reproduce the child by looking for a pinned span named `claim`. There is none. The assumption is the finding; CHECKED does not remove it.

5. **`denoteFunction` is not `denoteTransaction`; no ETH, no logs, no top-level revert wrapper.**
   The child evaluates a single function body. Parent-mapped `requestWithdrawals` / `claimWithdrawalsTo` move stETH/ETH and emit events. Official `denoteTransaction` restore-on-revert is unused.

   *Scenario.* `claimWithdrawalsTo` succeeds on admission then fails on the ETH send. Property A (admit/reject) is true for both callers; the ETH send is the interesting part and is not in `claim`. The CHECKED theorem never sees a value-bearing frame.

6. **The CHECKED theorem is not an instance of `admission_nondiscriminatory`.**
   Facade `PAddress1.admission_nondiscriminatory` is `∀ a₁ a₂ inp, ordinary_preconditions a₁ inp → globally_active cfg → succeeded ↔ succeeded` (`PAddress1.lean:108–114`). `ordinary_preconditions` includes `amount > 0`, deadline, `balances caller ≥ amount`, allowance, `externalCallEnvironment`. The child `admission_address_equivariant` is `∀ oracle a₁ a₂ world, PauseDisjoint → success bits equal`. No `Input`, no deadline, no allowance.

   *Scenario.* Instantiating the facade property at `fn := claim` does not typecheck (`claim` is not `Address → Input → Outcome State`). The CHECKED child is a different statement about a different program. YAML still files it under P-ADDRESS-1.

7. **Mapping-slot oracle is arbitrary (under PauseDisjoint).**
   `admission_address_equivariant` holds for every oracle that does not alias pause — including oracles that alias `balances[a₁]` with `balances[a₂]`.

   *Scenario.* `mappingSlot balancesSlot (callerKey 1) = mappingSlot balancesSlot (callerKey 2) = 200`. `swapBalances` is a no-op. Both callers see the same word: they are admitted together. That is “equivariant” and also not “each user has their own balance.” Colliding oracles are in-model and make the two users the same account. The witness oracle `key + 100` just happens not to collide.

8. **`callerKey` is `wordToAddress`, so senders that differ by `2^160` are the same user.**
   `AddressAdmission.lean:138–139`: `callerKey sender = (wordToAddress (sender : Uint256)).val`. `Address.ofNat` keeps only 160 bits.

   *Counterexample.* `a₁ = 1`, `a₂ = 1 + 2^160`. After masking they share slot `balanceSlotOf oracle 1`. `swapBalances` is a no-op. Both runs see the same pause word and the same balance word, so the success bits match. Equivariance holds because the two “users” are one account. The CHECKED `∀ a₁ a₂` is not a statement about distinct Ethereum addresses; high-bit senders are silently identified.

9. **Only the success bit is compared; the return value is not.**
   `claim` returns `balances[caller]` (`AddressAdmission.lean:89`). `admission_address_equivariant` equates `(run …).success` only.

   *Scenario.* Mutate the return to `balances[caller] + (caller % 2)` and keep the two `require`s. Admission bits still match after the swap; the claimed amount does not. Property A as specified for P-ADDRESS-1 is admit/reject, but a permissionless `claim` that paid the wrong amount would be exactly the discrimination the parent wants to catch, and this child cannot see it.

10. **The only Lido-shaped sibling is not this theorem, and it rejects approved operators.**
    Facade `PAddress1.bounded_transfer_model_source_tx` runs `AddressTransferTx.transfer` (`transferFrom` selector `0x23b872dd`) — a different program. That slice requires `caller == from` (`AddressTransferTx.lean:38`, `sourceTransfer` same test). Live `_transfer` (`WithdrawalQueueERC721.sol:241–245`) also admits `isApprovedForAll` and `_getTokenApprovals()[id]`.

    *Scenario.* Owner 1 has approved operator 9 on request 7. Operator calls `transferFrom(1, 3, 7)`. Live transfer succeeds. Lean `sourceTransfer 9 1 3 {owner := 1, approved := 9}` is `none` (`caller != from`). The CHECKED child never runs this program; the parent’s “bounded transfer” witness is the owner-only branch. An approved-operator handoff — the common ERC-721 case the mapped span names — is out of both CHECKED statements.

11. **`claim` does not read `ownerSlot`; `PauseDisjoint` is the only aliasing side condition.**
    `ownerSlot = 5` is used only by the `ownerGated` mutant. `admission_address_equivariant` does not assume `balanceSlotOf ≠ ownerSlot`. The witness happens to put owner at 5 and balances at 101/102.

    *Counterexample.* Oracle with `mappingSlot balancesSlot (callerKey 1) = 5` (owner slot) and still `PauseDisjoint` (5 ≠ 4). World: `owner = 1`, `balances[1]` aliases that word so “balance” is 1, `paused = 0`, `balances[2] = 0` at some other slot. `admitted 1` is true (`0 < 1`). `swapBalances` writes `balances[2]=0` into slot 5, wiping the owner word. Admission bits can still match (pause unchanged, swapped balance now at 2’s slot). A real `claim` that also consulted owner — or any later write of owner — would see the alias. The CHECKED theorem does not require owner-disjointness because `claim` never reads owner; the slot is dead weight in `spec.fields`.

12. **`txFrom` always uses the `claim()` selector and empty args, including for `ownerGated`.**
    `run` (`AddressAdmission.lean:114–116`) calls `denoteFunction oracle spec fn (txFrom sender) world`. `txFrom` (`:109–110`) hard-codes `functionSelector := 0x4e71d92d` and `args := []`. `spec.functions = [claim]` does not list `ownerGated`. The official denotation is handed the `FunctionSpec` object directly, so the selector never dispatches.

    *Scenario.* A denoteFunction that routed by selector would run `claim` even when `fn := ownerGated`, and the negative mutant `ownerGated_not_admission_equivariant` would not type as a different program. The CHECKED theorem depends on passing the body AST, not on the selector the YAML “permissionless entrypoint” would actually have. There is no Lido `claim()` to have that selector (issue 1).

13. **The transfer sibling’s three planes use three address algebras.**
    Extends issue 10. `sourceTransfer` / `modelTransfer` compare unbounded `Nat` (`to = 0`, `to = from`). `AddressTransferTx` params are `.address` (160-bit mask). Live `_to` / `_from` / `owner` are `address`.

    *Counterexample.* `caller = from = owner = 1`, `to = 2^160`. SOURCE commits `{owner := 2^160}`. TX binds `to` as `0` and reverts `TransferToZeroAddress`. Live `address(2^160) == address(0)` also reverts. Inverse: `from = 1+2^160`, `owner = 1`, `caller = 1`, `to = 3`. SOURCE rejects; TX/live mask `from` to `1` and commit. `source_refines_model` is `rfl` of two unmasked Nats. The parent’s `bounded_transfer_model_source_tx` only glues TX on the numeral `(1,1,3)`. Not the CHECKED `claim` theorem, but it is the only Lido-shaped sibling under the same ID.

14. **Transfer sibling has no `InvalidRequestId` / `RequestAlreadyClaimed`; `requestId` is pinned at 7.**
    Live `_transfer` (`WithdrawalQueueERC721.sol:233–236`) reverts if `_requestId == 0 || > getLastRequestId()` or `request.claimed`. Lean `sourceTransfer` has no id range or claimed bit. `AddressTransferTx.tx` hard-codes `args := [from, to, 7]` and only seeds mapping key 7.

    *Scenario.* Last id is 6, or request 7 is claimed. Live `transferFrom(1,3,7)` reverts. Lean `observe (run 1 1 3 1 9) = (true, 3, 0)` still holds. The CHECKED child never runs this program; the parent “bounded transfer” witness is a transfer of a token that need not exist.

15. **A third source model (`AddressCorrespondence`) treats existence/claimed/approval as input bits.**
    `AddressCorrespondence.admitted` for `.transferFrom` (`:81–85`) includes `callerIsApprovedForAll` / `callerIsTokenApproved` and `requestExists` / `requestClaimed` as **Input flags**, not queue storage. It is closer to the live operator branch than `sourceTransfer` (issue 10) and is not the CHECKED theorem.

    *Scenario.* Owner 1 set `setApprovalForAll(9, true)` on existing unclaimed id 7. Live `transferFrom(1,3,7)` from 9 succeeds. `sourceTransfer 9 1 3` is `none`. `AddressCorrespondence.admitted` is `true` if the three booleans are set, even if the NFT does not exist. Same mapped span, two CHECKED-adjacent interpreters plus the toy `claim()`, none of which is `_getQueue()[_requestId]`. The CHECKED child is still `admission_address_equivariant` on `claim()`.

16. **Transfer-sibling oracle aliases `owners[107]` with `approvals[7]`; live owner is packed.**
    `AddressTransferTx.oracle.mappingSlot := fun base key => base * 100 + key` (`:49–51`). `ownersSlot = 11`, `approvalsSlot = 12`. Slot of `owners[107]` is `11*100+107 = 1207`; slot of `approvals[7]` is `12*100+7 = 1207`. Hidden because `requestId` is frozen at 7 (issue 14). Live `WithdrawalRequest` (`WithdrawalQueueBase.sol:47–59`) packs `owner` with `timestamp` (`uint40`), `claimed`, and `reportTimestamp` in one slot after two `uint128`s.

    *Counterexample.* A world that also held request 107: writing `owners[107] = 3` clobbers `approvals[7]`. Live a wide owner SSTORE zeros `claimed` / timestamps in the packed word. Lean cannot represent that clobber, and the toy oracle aliases two different mappings. The parent’s “bounded transfer” witness (`run 1 1 3 1 9`) never sees either hole. The CHECKED `claim` theorem uses a different oracle (`key + 100`) with the same class of collision (issue 7).
