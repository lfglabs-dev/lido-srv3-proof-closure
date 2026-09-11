#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,subprocess
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
modules={
 'AccountingCall':'audit/trio/account-address/AccountingCall.lean',
 'ReportFeeAccountingCall':'audit/trio/account-address/ReportFeeAccountingCall.lean',
 'LidoSRv3.Audit.Guarantees.PAccount1AccountingCall':'LidoSRv3/Audit/Guarantees/PAccount1AccountingCall.lean',
 'LidoSRv3.Tests.AccountAccountingCall':'LidoSRv3/Tests/AccountAccountingCall.lean'}
subprocess.run(['lake','build','LidoSRv3.Audit.Guarantees.PAccount1PhysicalPause','LidoSRv3.Tests.AccountPhysicalPause','LidoSRv3.Audit.Source.TrioReserve1.ABI'],cwd=R,check=True)
records={}
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for module,path in modules.items():
 out=R/'.lake/build/lib/lean'/module.replace('.','/');out.parent.mkdir(parents=True,exist_ok=True)
 print('CHECK '+path,flush=True)
 subprocess.run(['lake','env','lean','-o',str(out)+'.olean','-i',str(out)+'.ilean',path],cwd=R,check=True)
 records[module]={'source':path,'source_sha256':sha(R/path),'olean_sha256':sha(Path(str(out)+'.olean')),'ilean_sha256':sha(Path(str(out)+'.ilean'))}
(O/'normal-build-identities.json').write_text(json.dumps(records,indent=2)+'\n')
print('PASS: registered prerequisite closure and four sequential ordinary helper/source/public/test compilations; no registration edit',flush=True)
