"""Independent hashlib/ABI construction, not a Lean proof or an oracle premise."""
from pathlib import Path
import hashlib,json
out=Path(__file__).resolve().parent
word=lambda n:n.to_bytes(32,'big')
chunk=lambda n:n.to_bytes(8,'little')+bytes(24)
pair=lambda a,b:hashlib.sha256(a+b).digest()
key=bytes(range(1,49));creds=word(0x123456)
fields=[32000000000,1,11,22,33,44]
leaves=[hashlib.sha256(key+bytes(16)).digest(),creds]+[chunk(n) for n in fields]
level=leaves
while len(level)>1:level=[pair(level[i],level[i+1]) for i in range(0,len(level),2)]
leaf=level[0];index=1430*2**40+1234;depth=index.bit_length()-1
proof=[bytes(32) for _ in range(depth)];proof[-2]=pair(chunk(100),chunk(7))
root=leaf;i=index
for sibling in proof:
 root=pair(root,sibling) if i%2==0 else pair(sibling,root);i//=2
assert i==1
head=[123,100,7,192,1234,int.from_bytes(creds,'big')]
witness=[256,256+32+32*depth,fields[0],fields[2],fields[3],fields[4],fields[5],fields[1]]
data=bytes.fromhex('2e77b4ba')+b''.join(map(word,head+witness))+word(depth)+b''.join(proof)+word(48)+key+bytes(16)
(out/'valid-calldata.bin').write_bytes(data);(out/'valid-root.bin').write_bytes(root)
(out/'vector.json').write_text(json.dumps(dict(timestamp=123,slot=100,proposer=7,index=1234,typed_index=index,proof_length=depth,leaf=leaf.hex(),root=root.hex(),calldata_sha256=hashlib.sha256(data).hexdigest(),calldata_bytes=len(data),proof_start=484,key_start=196+witness[1]+32,method='Python hashlib SHA256 and explicit ABI words; no Lean digest reused'),indent=2)+'\n')
