from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[2]
subprocess.run(['lake','build','LidoSRv3.Audit.Guarantees.PAccount1TreasuryCall','Tests.Verity.ReportFeeTreasuryCallTest'],cwd=R,check=True)
for module,path in [('ReportFeePhysicalPause','audit/trio/account-address/ReportFeePhysicalPause.lean'),('LidoSRv3.Audit.Guarantees.PAccount1PhysicalPause','LidoSRv3/Audit/Guarantees/PAccount1PhysicalPause.lean'),('LidoSRv3.Tests.AccountPhysicalPause','LidoSRv3/Tests/AccountPhysicalPause.lean')]:
 assert (R/path).exists(),path
 out=R/'.lake/build/lib/lean'/module.replace('.','/');out.parent.mkdir(parents=True,exist_ok=True)
 print('CHECK '+path,flush=True)
 subprocess.run(['lake','env','lean','-o',str(out)+'.olean','-i',str(out)+'.ilean',path],cwd=R,check=True)

print("PASS: 39-job prerequisite closure and all three sequential ordinary modules; no registration edit",flush=True)
