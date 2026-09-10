import ReportFeeCastInvariant

/-! The checked fee split actually consumed by the existing mint executor.
No fee transfer or `_distributeFee` call is asserted. -/
namespace AccountAddress.ReportFeeCheckedSplit
open ReportWriteFee ReportFeeMint ReportFeeCastInvariant

/-- The exact same fee result minted by the covered report continuation.
The positive map includes zero-fee rows as zero, matching the guarded source
loop; the zero-mint branch skips the whole distribution. -/
def Split (d : Distribution) (fee : FeeResult) : Prop :=
  fee.moduleSharesToMint.sum + fee.treasurySharesToMint = fee.sharesToMintAsFees ∧
  ((fee.sharesToMintAsFees = 0 ∧ fee.moduleSharesToMint = [] ∧
    fee.moduleFeeRecipients = [] ∧ fee.moduleIds = []) ∨
   (0 < fee.sharesToMintAsFees ∧ 0 < d.totalFee ∧
    fee.moduleSharesToMint = d.stakingModuleFees.map (fun f => fee.sharesToMintAsFees * f / d.totalFee) ∧
    fee.moduleSharesToMint.length = d.stakingModuleFees.length ∧
    fee.moduleFeeRecipients = d.recipients ∧ fee.moduleIds = d.stakingModuleIds))

theorem checked_products_split (r : ReportWei) (d : Distribution) (fee : FeeResult)
    (h : checkedFeeProductsFromCommittedGetter r d = some fee) : Split d fee := by
  obtain ⟨shares,hs⟩ := checkedFeeProducts_split_origin r d fee h
  obtain ⟨heq,hsum,hbranch⟩ := checkedFeeResultOf_split d shares fee hs
  rw [← heq] at hsum hbranch
  refine ⟨hsum,?_⟩
  rcases hbranch with hz | ⟨hpos,ht,hparts,hr,hi⟩
  · exact Or.inl hz
  · exact Or.inr ⟨hpos,ht,hparts,by rw [hparts,List.length_map],hr,hi⟩

/-- Joint actual report/getter/mint result, exact post-report fee casts and
checked allocation conservation. The distribution is the one read from the
same post-report router and consumed by the same checked fee calculation. -/
def Success (x : Input) (before post : World) (fee : FeeResult)
    (events : List StETHMintShares.Event) : Prop :=
  ReportFeeMint.Success x before post fee events ∧
  (∀ id ∈ x.registeredModuleIds, ExactCasts x.layout post.router id) ∧
  fee.moduleFeeRecipients.length = fee.moduleIds.length ∧
  fee.moduleIds.length = fee.moduleSharesToMint.length ∧
  ∃ distribution,
    getStakingRewardsDistribution x.layout x.registeredModuleIds post.router = .ok distribution ∧
    checkedFeeProductsFromCommittedGetter x.report distribution = some fee ∧ Split distribution fee

theorem committed_checked_split (x : Input) (before post : World) (fee : FeeResult)
    (events : List StETHMintShares.Event)
    (h : handleOracleReportFromCommittedFeeProducts x before = .committed post fee events) :
    Success x before post fee events := by
  obtain ⟨hs,hcasts⟩ := composition_exact_casts x before post fee events h
  obtain ⟨router,d,_,hd,hf,heq,_⟩ := hs
  have split := checked_products_split x.report d fee hf
  have shape := getter_ok_spec x.layout x.registeredModuleIds router d hd
  have lengths : fee.moduleFeeRecipients.length = fee.moduleIds.length ∧
      fee.moduleIds.length = fee.moduleSharesToMint.length := by
    rcases split.2 with ⟨_,hp,hr,hi⟩ | ⟨_,_,_,hl,hr,hi⟩
    · simp [hp,hr,hi]
    · rw [hr,hi,hl]
      exact ⟨shape.1,shape.2.1⟩
  refine ⟨ReportFeeMint.committed_success x before post fee events h,hcasts,
    lengths.1,lengths.2,d,?_,hf,split⟩
  rw [heq]
  exact hd

#print axioms checked_products_split
#print axioms committed_checked_split
end AccountAddress.ReportFeeCheckedSplit
