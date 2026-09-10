#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[2]; OUT=Path(__file__).resolve().parent
sha=lambda b:hashlib.sha256(b).hexdigest()
base='2c2c72a91cd68a43de0777912772d12cc48a285d'
pin='17005714f151e5502c559932319a3f2f74ac2436'
old=json.loads((ROOT/'audit/topup-module-nocode/receipt.json').read_text())
kept={}
for p,h in old['sha256'].items():
 data=(ROOT/p).read_bytes(); assert sha(data)==h,p
 assert subprocess.check_output(['git','show',base+':'+p],cwd=ROOT)==data,p
 kept[p]=h
inputs=json.loads((ROOT/'audit/topup-module-nocode/compiler-source-identities.json').read_text())
for p,h in inputs['source_sha256'].items():
 path=Path(p) if p.startswith('/') else ROOT/p
 assert sha(path.read_bytes())==h,p
 if '/lido-core/' in p:
  core,rel=p.split('/lido-core/',1);core=Path(core)/'lido-core'
  assert subprocess.check_output(['git','show',pin+':'+rel],cwd=core)==path.read_bytes(),p
ir=(ROOT/'audit/topup-module-nocode/router-ir.txt').read_bytes()
assert sha(ir)==inputs['ir_sha256']
text=ir.decode()
assert 'finalize_allocation(mload(0x80), _67)' in text
assert 'abi_decode_array_uint256_dyn_fromMemory(mload(0x80), add(mload(0x80), _67))' in text
for fragment in ['if slt(sub(dataEnd, headStart), 32)',
 'if iszero(slt(add(offset, 0x1f), end))',
 'size := add(shl(5, length), 0x20)',
 'let _3 := array_allocation_size_array_uint256_dyn(_1)',
 'finalize_allocation(memPtr, _3)',
 'let srcEnd := add(add(offset, shl(5, _1)), 0x20)']:
 assert fragment in text,fragment
result={'source_pin':pin,'reused_artifacts':kept,'compiler_input_sha256':inputs['source_sha256'],
 'ir_sha256':sha(ir),'new_solidity_tests':0,'scope':'Exact retained compiler/source identities; fresh kernel scalar branches, not new full Solidity runtime or memory-copy equivalence.'}
(OUT/'source-ir-identities.json').write_text(json.dumps(result,indent=2)+'\n')
print(f'PASS {len(kept)} unchanged retained artifacts; {len(inputs["source_sha256"])} compiler input identities; exact pinned core and relevant full-IR functions.')
