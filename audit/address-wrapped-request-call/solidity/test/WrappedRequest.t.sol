pragma solidity 0.8.9;
import "../src/WrappedRequestHarness.sol";
interface Vm { struct Log {bytes32[] topics;bytes data;address emitter;} function store(address,bytes32,bytes32) external; function recordLogs() external; function getRecordedLogs() external returns(Log[] memory); }
contract WrappedDouble {
    address public stETH; address public expectedFrom; WrappedRequestHarness public queue;
    uint256 public transfers;uint256 public unwraps;uint256 public boolWord;uint256 public boolSize=32;
    uint256 public received=100;uint256 public unwrapSize=32;uint256 public flags;uint256 public expected=7;
    constructor(address token) {stETH=token;}
    function setup(WrappedRequestHarness q) external {queue=q;expectedFrom=msg.sender;}
    function returnsConfig(uint256 b,uint256 bs,uint256 r,uint256 rs) external {boolWord=b;boolSize=bs;received=r;unwrapSize=rs;}
    function mode(uint256 f,uint256 a) external {flags=f;expected=a;}
    fallback() external {
        if(msg.sig==bytes4(0x23b872dd)) {
            (address from,address to,uint256 a)=abi.decode(msg.data[4:],(address,address,uint256));
            require(from==expectedFrom,"transfer sender");require(to==address(queue)&&a==expected,"transfer payload");
            if(flags&16!=0) revert("transfer failed");transfers++;
            if(flags&1!=0) queue.seed(3,10,20,111);
            uint256 b=boolWord;uint256 bn=boolSize;assembly {mstore(0,b) return(0,bn)}
        }
        require(msg.sig==bytes4(0xde0e9a3e)&&abi.decode(msg.data[4:],(uint256))==expected,"unwrap payload");
        require(transfers==1,"transfer before unwrap");
        if(flags&64!=0) require(queue.getLastRequestId()==3,"transfer world");
        if(flags&8!=0) revert("unwrap failed");unwraps++;
        if(flags&2!=0) queue.seed(7,30,40,222);
        uint256 r=received;uint256 n=unwrapSize;assembly {mstore(0,r) return(0,n)}
    }
}
contract QuoteDouble {
    WrappedDouble public wrapper;WrappedRequestHarness public queue;uint256 public shares=10;
    uint256 public calls;uint256 public flags;
    function setup(WrappedDouble w,WrappedRequestHarness q) external {wrapper=w;queue=q;}
    function configure(uint256 sh,uint256 f) external {shares=sh;flags=f;}
    fallback() external {
        require(msg.sig==bytes4(0x19208451),"unexpected stETH transfer");
        require(abi.decode(msg.data[4:],(uint256))==wrapper.received(),"decoded amount");
        require(wrapper.transfers()==1 && wrapper.unwraps()==1,"call order");
        if(flags&1!=0) require(queue.getLastRequestId()==7,"unwrap world");
        if(flags&2!=0) calls++;
        if(flags&4!=0) revert("quote failed");
        uint256 sh=shares;assembly {mstore(0,sh) return(0,32)}
    }
}
contract WrappedRequestTest {
    Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    function setup() internal returns(WrappedRequestHarness q,WrappedDouble w,QuoteDouble t) {
        t=new QuoteDouble();w=new WrappedDouble(address(t));q=new WrappedRequestHarness(IWstETH(address(w)));
        w.setup(q);t.setup(w,q);q.seed(0,0,0,9);
    }
    function fail(WrappedRequestHarness q,WrappedDouble w,bytes memory expectedError) internal {
        (bool ok,bytes memory data)=address(q).call(abi.encodeWithSelector(q.one.selector,w.expected(),address(0)));
        require(!ok && keccak256(data)==keccak256(expectedError),"failure order/data");
        require(w.transfers()==0&&w.unwraps()==0&&q.getLastRequestId()==0,"root rollback");
    }
    function testActualChainFalseBoolTrailingUnwrapAndEvents() public {
        (WrappedRequestHarness q,WrappedDouble w,QuoteDouble t)=setup();
        w.returnsConfig(0,64,123,64);w.mode(67,7);t.configure((uint256(1)<<128)+5,1);
        vm.recordLogs();require(q.one(7,address(0))==8);
        WithdrawalQueueBase.WithdrawalRequest memory r=q.metadata(8);
        require(r.cumulativeStETH==153&&r.cumulativeShares==45&&r.reportTimestamp==222&&r.owner==address(this));
        require(w.transfers()==1&&w.unwraps()==1);
        Vm.Log[] memory logs=vm.getRecordedLogs();require(logs.length==2);
        require(logs[0].topics[0]==keccak256("WithdrawalRequested(uint256,address,address,uint256,uint256)"));
        require(logs[1].topics[0]==keccak256("Transfer(address,address,uint256)"));
        require(logs[0].topics[1]==bytes32(uint256(8))&&logs[1].topics[3]==bytes32(uint256(8)));
        (uint256 amount,uint256 shares)=abi.decode(logs[0].data,(uint256,uint256));require(amount==123&&shares==5);
    }
    function testBoolDecoderBeforeUnwrap() public {
        (WrappedRequestHarness q,WrappedDouble w,)=setup();w.returnsConfig(2,32,0,0);w.mode(8,7);fail(q,w,"");
        w.returnsConfig(0,31,0,0);fail(q,w,"");
    }
    function testUnwrapDecoderBeforeBounds() public {
        (WrappedRequestHarness q,WrappedDouble w,)=setup();w.returnsConfig(0,32,0,31);fail(q,w,"");
    }
    function testAmountBoundsAfterUnwrapBeforeQuote() public {
        (WrappedRequestHarness q,WrappedDouble w,QuoteDouble t)=setup();w.mode(3,7);t.configure(10,4);
        w.returnsConfig(0,32,99,32);fail(q,w,abi.encodeWithSignature("RequestAmountTooSmall(uint256)",99));
        w.returnsConfig(0,32,1000e18+1,32);fail(q,w,abi.encodeWithSignature("RequestAmountTooLarge(uint256)",1000e18+1));
    }
    function testBubbledCallFailures() public {
        (WrappedRequestHarness q,WrappedDouble w,)=setup();w.mode(16,7);fail(q,w,abi.encodeWithSignature("Error(string)","transfer failed"));
        w.mode(8,7);fail(q,w,abi.encodeWithSignature("Error(string)","unwrap failed"));
    }
    function testStaticWriteFailureRestoresBothCalls() public {
        (WrappedRequestHarness q,WrappedDouble w,QuoteDouble t)=setup();w.mode(3,7);t.configure(10,2);fail(q,w,"");
    }
    function testLateOwnerSetFailureRestoresBothCalls() public {
        (WrappedRequestHarness q,WrappedDouble w,)=setup();
        bytes32 base=keccak256(abi.encode(address(this),keccak256("lido.WithdrawalQueue.requestsByOwner")));
        vm.store(address(q),keccak256(abi.encode(uint256(1),uint256(base)+1)),bytes32(uint256(3)));
        fail(q,w,abi.encodeWithSignature("Panic(uint256)",1));
    }
    function testCallerDoesNotInventZeroWrappedGuard() public {
        (WrappedRequestHarness q,WrappedDouble w,)=setup();w.mode(0,0);require(q.one(0,address(0))==1);
    }
    function testFuzzActualReturnedAmountAndShares(uint256 wrapped,uint96 received,uint256 shares,uint160 owner) public {
        (WrappedRequestHarness q,WrappedDouble w,QuoteDouble t)=setup();uint256 amount=100+uint256(received)%(1000e18-99);
        w.mode(0,wrapped);w.returnsConfig(1,32,amount,33);t.configure(shares,0);
        require(q.one(wrapped,address(owner))==1);WithdrawalQueueBase.WithdrawalRequest memory r=q.metadata(1);
        require(r.owner==(owner==0?address(this):address(owner))&&r.cumulativeStETH==amount&&r.cumulativeShares==uint128(shares));
    }
}
