// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {StakingRouter} from "contracts/0.8.25/sr/StakingRouter.sol";
import {SRStorage} from "contracts/0.8.25/sr/SRStorage.sol";
import {StakingModuleStatus} from "contracts/0.8.25/sr/SRTypes.sol";
import {EnumerableSet} from "@openzeppelin/contracts-v5.2/utils/structs/EnumerableSet.sol";

interface BatchVm { function store(address,bytes32,bytes32) external; }
contract BatchLido {
    uint256 public depositable = 64 ether;
    bool public enabled = true;
    function getDepositableEther() external view returns(uint256) { return depositable; }
    function canDeposit() external view returns(bool) { return enabled; }
    function configure(uint256 amount,bool active) external { depositable=amount;enabled=active; }
}
contract BatchModule {
    uint256 public allocation;
    uint256 public calls;
    bytes public received;
    function configure(uint256 amount) external { allocation=amount; }
    function getStakingModuleSummary() external pure returns(uint256,uint256,uint256) { return (0,1,0); }
    function getTotalModuleStake() external pure returns(uint256) { return 32 ether; }
    function allocateDeposits(uint256,bytes[] calldata,uint256[] calldata,uint256[] calldata,uint256[] calldata)
        external returns(uint256[] memory result)
    {
        calls++;received=msg.data;
        result=new uint256[](1); result[0]=allocation;
    }
}
// Only fixture initialization is supplied. topUp, allocation, cap read, guards,
// actual module CALL, ABI decoder and final event are unmodified pinned code.
contract BatchRouter is StakingRouter {
    using EnumerableSet for EnumerableSet.UintSet;
    constructor(address lido,address locator,address module)
        StakingRouter(address(0x1234),lido,locator,32 ether,2048 ether)
    {
        SRStorage.getRouterState().moduleIds.add(7);
        SRStorage.getRouterState().lastModuleId=7;
        SRStorage.getRouterState().maxTopUpPerBlockGwei=20_000_000_000;
        SRStorage.getModuleState(7).config.moduleAddress=module;
        SRStorage.getModuleState(7).config.stakeShareLimit=10000;
        SRStorage.getModuleState(7).config.status=StakingModuleStatus.Active;
        SRStorage.getModuleState(7).config.withdrawalCredentialsType=2;
    }
}
contract TopupBatchConsumerTest {
    BatchVm constant vm=BatchVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    bytes32 constant ROOT=0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000;
    BatchLido lido;
    BatchModule module;
    BatchRouter router;
    function topUpGateway() external view returns(address) { return address(this); }
    function setUp() public {
        lido=new BatchLido();module=new BatchModule();
        router=new BatchRouter(address(lido),address(this),address(module));
    }
    function args() internal pure returns(uint256[] memory keys,uint256[] memory operators,bytes[] memory pubkeys,uint256[] memory limits) {
        keys=new uint256[](1);keys[0]=42;
        operators=new uint256[](1);operators[0]=3;
        pubkeys=new bytes[](1);pubkeys[0]=new bytes(48);
        limits=new uint256[](1);limits[0]=32 ether;
    }
    function invoke() internal returns(bool,bytes memory) {
        (uint256[] memory keys,uint256[] memory operators,bytes[] memory pubkeys,uint256[] memory limits)=args();
        return address(router).call(abi.encodeCall(router.topUp,(7,keys,operators,pubkeys,limits)));
    }
    function test_actualRouterConsumesCapAndArguments() public {
        (bool ok,)=invoke(); require(ok,"zero reply failed");
        (uint256[] memory keys,uint256[] memory operators,bytes[] memory pubkeys,uint256[] memory limits)=args();
        require(module.calls()==1,"module was not called");
        require(keccak256(module.received())==keccak256(abi.encodeCall(module.allocateDeposits,
            (20 ether,pubkeys,keys,operators,limits))),"actual target or argument mismatch");
    }
    function test_aboveCapRollsBackActualModuleWrites() public {
        module.configure(21 ether);
        (bool ok,bytes memory reason)=invoke();
        require(!ok && keccak256(reason)==keccak256(abi.encodeWithSignature("ModuleReturnExceedTarget()")),"cap rejection");
        require(module.calls()==0 && module.received().length==0,"callee writes survived revert");
    }
    function test_limitAndAlignmentGuardsPrecedeCap() public {
        module.configure(33 ether);
        (bool ok,bytes memory reason)=invoke();
        require(!ok && keccak256(reason)==keccak256(abi.encodeWithSignature("AllocationExceedsLimit()")),"limit order");
        module.configure(21 ether+1);
        (ok,reason)=invoke();
        require(!ok && keccak256(reason)==keccak256(abi.encodeWithSignature("AmountNotAlignedToGwei()")),"alignment order");
        require(module.calls()==0,"failed module writes survived");
    }
    function test_zeroTargetPauseGuardBeforeModule() public {
        lido.configure(0,false);
        (bool ok,bytes memory reason)=invoke();
        require(!ok && keccak256(reason)==keccak256(abi.encodeWithSignature("LidoDepositsPaused()")),"zero target pause");
        require(module.calls()==0,"paused module entered");
        lido.configure(0,true);(ok,)=invoke();
        require(ok && module.calls()==1,"enabled zero target skipped module");
    }
    function testFuzz_actualPackedCapRead(uint24 lastId,uint64 cap,uint168 high) public {
        vm.store(address(router),bytes32(uint256(ROOT)+5),bytes32(uint256(lastId)|(uint256(cap)<<24)|(uint256(high)<<88)));
        require(router.getMaxTopUpPerBlockGwei()==cap,"packed cap width/offset");
    }
}
