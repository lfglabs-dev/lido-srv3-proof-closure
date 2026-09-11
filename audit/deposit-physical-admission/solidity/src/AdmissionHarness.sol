pragma solidity 0.8.25;
import {StakingRouter} from "contracts/0.8.25/sr/StakingRouter.sol";
import {SRStorage} from "contracts/0.8.25/sr/SRStorage.sol";
import {ModuleState,ModuleStateConfig,StakingModuleStatus,RouterState} from "contracts/0.8.25/sr/SRTypes.sol";
contract AdmissionHarness is StakingRouter {
    RouterState private layoutProbe;
    constructor() StakingRouter(address(1),address(2),address(3),7,11) {}
    // Admission fragment only: DSM locator resolution precedes this boundary.
    // All storage accessors/auth helper are inherited unchanged from the real router.
    function admitted(uint256 id,address dsm) external view returns(bytes32) {
        _checkAppAuth(dsm);
        (,ModuleStateConfig storage config)=_getModuleState(id);
        if(config.status != StakingModuleStatus.Active) revert StakingModuleNotActive();
        return _getWithdrawalCredentialsWithType(config.withdrawalCredentialsType);
    }
    function root() external pure returns(bytes32 s) {
        RouterState storage r=SRStorage.getRouterState();assembly {s:=r.slot}
    }
}
