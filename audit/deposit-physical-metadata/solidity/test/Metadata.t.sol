pragma solidity 0.8.25;
import "../src/MetadataHarness.sol";
interface Vm {
    struct Log { bytes32[] topics; bytes data; address emitter; }
    function warp(uint256) external;
    function roll(uint256) external;
    function store(address,bytes32,bytes32) external;
    function load(address,bytes32) external view returns(bytes32);
    function recordLogs() external;
    function getRecordedLogs() external returns(Log[] memory);
}
contract Callback is ILidoPrefix {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    bytes32 public key;
    bool public fail;
    uint256 public observed;
    uint256 public amount;
    uint256 public count;
    function setup(bytes32 k,bool f) external {key=k;fail=f;}
    function withdrawDepositableEther(uint256 a,uint256 n) external {
        observed=uint256(vm.load(msg.sender,key));amount=a;count=n;
        require(uint64(observed)==42 && uint64(observed>>64)==99,"metadata not visible");
        require(!fail,"callback failed");
    }
}
contract MetadataTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    bytes32 constant ROOT = 0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000;
    uint256 constant OLD = 9 + (10<<64) + (11<<128) + (12<<192);
    uint256 constant NEW = 42 + (99<<64) + (11<<128) + (12<<192);
    function fixture(bool fails) internal returns(MetadataHarness h,Callback c,bytes32 key) {
        c=new Callback();h=new MetadataHarness(address(c));
        unchecked {key=bytes32(uint256(keccak256(abi.encode(uint256(7),ROOT)))+1);}
        c.setup(key,fails);vm.store(address(h),key,bytes32(OLD));
        vm.warp((1<<64)+42);vm.roll((1<<64)+99);
    }
    function testZeroKeysStillWriteAndEmit() external {
        (MetadataHarness h,Callback c,bytes32 key)=fixture(false);vm.recordLogs();
        h.executeCoveredPrefix(7,0);
        require(uint256(vm.load(address(h),key))==NEW && c.count()==0);
        Vm.Log[] memory logs=vm.getRecordedLogs();require(logs.length==1);
        require(logs[0].emitter==address(h) && logs[0].topics.length==2);
        require(logs[0].topics[0]==keccak256("StakingRouterETHDeposited(uint256,uint256)"));
        require(logs[0].topics[1]==bytes32(uint256(7)) && keccak256(logs[0].data)==keccak256(abi.encode(uint256(0))));
    }
    function testCallbackSeesPackedWritesAndActualArguments() external {
        (MetadataHarness h,Callback c,)=fixture(false);h.executeCoveredPrefix(7,2);
        require(c.observed()==NEW && c.amount()==64 ether && c.count()==2);
    }
    function testCallbackFailureRestoresPhysicalWord() external {
        (MetadataHarness h,Callback c,bytes32 key)=fixture(true);
        (bool ok,bytes memory reason)=address(h).call(abi.encodeCall(h.executeCoveredPrefix,(7,2)));
        require(!ok && keccak256(reason)==keccak256(abi.encodeWithSignature("Error(string)","callback failed")));
        require(uint256(vm.load(address(h),key))==OLD && c.observed()==0 && c.amount()==0 && c.count()==0);
    }
}
