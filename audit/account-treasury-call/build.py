#!/usr/bin/env python3
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[2]
subprocess.run(['lake','build','Tests.Verity.ReportFeeDistributionTest','LidoSRv3.Audit.Source.TrioReserve1.StaticCall'],cwd=ROOT,check=True)
for module,path in [
('TreasuryCall','audit/trio/account-address/TreasuryCall.lean'),
('ReportFeeTreasuryCall','audit/trio/account-address/ReportFeeTreasuryCall.lean'),
('LidoSRv3.Audit.Guarantees.PAccount1TreasuryCall','LidoSRv3/Audit/Guarantees/PAccount1TreasuryCall.lean'),
('Tests.Verity.ReportFeeTreasuryCallTest','audit/trio/account-address/Tests/Verity/ReportFeeTreasuryCallTest.lean')]:
 out=Path('.lake/build/lib/lean')/module.replace('.','/');(ROOT/out).parent.mkdir(parents=True,exist_ok=True)
 print('CHECK '+path,flush=True)
 subprocess.run(['lake','env','lean','-o',str(out)+'.olean','-i',str(out)+'.ilean',path],cwd=ROOT,check=True)
print('PASS: cached prerequisites and four new modules; no registration edits.',flush=True)
