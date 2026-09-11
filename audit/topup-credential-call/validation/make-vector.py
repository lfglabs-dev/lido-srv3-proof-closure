from pathlib import Path
import hashlib,json
O=Path(__file__).resolve().parent
sha=lambda b:hashlib.sha256(b).digest()
le=lambda n:n.to_bytes(32,'little')
be=lambda n:n.to_bytes(32,'big')
wc=be(2*2**248+12345)
leaves=[]
for key in [1,9,2]:
 nodes=[sha(bytes([key])+bytes(63)),wc,le(0),le(0),le(0),le(0),le(2**64-1),le(0)]
 while len(nodes)>1:nodes=[sha(nodes[j]+nodes[j+1]) for j in range(0,len(nodes),2)]
 leaves.append(nodes[0])
indices=[1430*2**40+i for i in range(3)];cur=dict(zip(indices,leaves));paths=[[] for _ in indices];idx=indices[:]
for depth in range(50):
 default=sha(bytes(64)) if depth==48 else bytes(32)
 for i in range(3):paths[i].append(cur.get(idx[i]^1,default));idx[i]//=2
 parents={}
 for i in cur:
  left=cur.get((i//2)*2,default);right=cur.get((i//2)*2+1,default)
  parents[i//2]=sha(left+right)
 cur=parents
assert list(cur)==[1]
root=cur[1]
for i in range(3):
 v=leaves[i];j=indices[i]
 for sib in paths[i]:v=sha(v+sib) if j%2==0 else sha(sib+v);j//=2
 assert v==root
 (O/f'proof-{i}.bin').write_bytes(b''.join(paths[i]))
(O/'root.bin').write_bytes(root)
(O/'vector.json').write_text(json.dumps({'credentials':wc.hex(),'leaves':[x.hex() for x in leaves],'root':root.hex(),'indices':indices,'depth':50,'scope':'Python hashlib independent three-leaf sparse branches, actual positive fixture witness bytes; no Lean hash function used.'},indent=2)+'\n')
print('PASS independent positive three-row tree',root.hex())
