pragma solidity 0.8.25;

interface ILidoPrefix {
    function withdrawDepositableEther(uint256 amount, uint256 count) external;
}

// Narrow source probe: SRTypes.ModuleStateDeposits, SRLib's two assignments,
// and StakingRouter's update/zero-return/withdraw order at core17005714.
// Allocation, module calls, beacon calls and the full entry are not reproduced.
contract MetadataHarness {
    struct ModuleStateDeposits {
        uint64 lastDepositAt;
        uint64 lastDepositBlock;
        uint64 maxDepositsPerBlock;
        uint64 minDepositBlockDistance;
    }
    bytes32 constant ROUTER_ROOT = 0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000;
    ILidoPrefix immutable LIDO;
    event StakingRouterETHDeposited(uint256 indexed stakingModuleId, uint256 depositsValue);
    constructor(address lido) { LIDO = ILidoPrefix(lido); }
    function deposits(uint256 id) internal pure returns (ModuleStateDeposits storage d) {
        uint256 key;
        unchecked { key = uint256(keccak256(abi.encode(id, ROUTER_ROOT))) + 1; }
        assembly { d.slot := key }
    }
    function _updateModuleLastDepositState(uint256 stakingModuleId, uint256 depositsValue) internal {
        ModuleStateDeposits storage stateDeposits = deposits(stakingModuleId);
        stateDeposits.lastDepositAt = uint64(block.timestamp);
        stateDeposits.lastDepositBlock = uint64(block.number);
        emit StakingRouterETHDeposited(stakingModuleId, depositsValue);
    }
    function executeCoveredPrefix(uint256 id, uint256 actualDepositsCount) external {
        uint256 depositsValue = actualDepositsCount * 32 ether;
        _updateModuleLastDepositState(id, depositsValue);
        if (actualDepositsCount == 0) return;
        LIDO.withdrawDepositableEther(depositsValue, actualDepositsCount);
    }
}
