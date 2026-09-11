from pathlib import Path
import json,hashlib
from Crypto.Hash import keccak
r=Path(__file__).resolve().parents[3];d=r/'audit/topup-entry-admission/solidity'
x=json.loads((d/'receipt.json').read_text());inp=json.loads((r/'audit/topup-credential-call/solidity/input.json').read_text())['sources'];new='audit/topup-entry-admission/solidity/TopupEntryAdmission.t.sol';inp[new]={'content':(r/new).read_text()};assert len(inp)==23
assert x['source_sha256']=={n:hashlib.sha256(v['content'].encode()).hexdigest() for n,v in sorted(inp.items())}
assert hashlib.sha256((d/'forge.log').read_bytes()).hexdigest()==x['log_sha256'];log=(d/'forge.log').read_text();assert '8 passed; 0 failed' in log and 'runs: 1024' in log
for name,info in x['artifacts'].items():
 p=d/(name+'.json');assert hashlib.sha256(p.read_bytes()).hexdigest()==info['sha256'];a=json.loads(p.read_text());m=json.loads(a['rawMetadata']);assert m['sources']==info['metadata_sources'] and m['settings']==info['settings'] and m['compiler']['version']=='0.8.25+commit.b61c2a91'
 assert m['settings']['optimizer']=={'enabled':True,'runs':200} and m['settings']['viaIR'] and m['settings']['evmVersion']=='cancun'
 for n,h in m['sources'].items():assert h['keccak256']=='0x'+keccak.new(digest_bits=256,data=inp[n]['content'].encode()).hexdigest()
print('PASS 23 exact runtime inputs, 2 actual artifacts/metadata, 8 cases including 1024 fuzz; no compiler or Forge rerun')

import subprocess
for name in ['root.bin','proof-0.bin','proof-1.bin','proof-2.bin','vector.json','make-vector.py']:
 rel='audit/topup-credential-call/validation/'+name
 assert (r/rel).read_bytes()==subprocess.check_output(['git','-C',str(r),'show','53871e66833bd45190eb83dffc15439ceafa9c42:'+rel]),rel
assert 'PASS 4 native execution groups:' in (r/'audit/topup-entry-admission/validation/native.log').read_text()
print('PASS retained independent SHA tree/proofs exact base; native success log present; no FFI rerun')
