pragma solidity 0.8.25;
import {StakingRouter} from "contracts/0.8.25/sr/StakingRouter.sol";
import {ModuleStateConfig,StakingModuleStatus} from "contracts/0.8.25/sr/SRTypes.sol";
// Calls actual inherited getter/auth/storage helpers. The later allocation and
// module/withdrawal/beacon deposit suffix is not executed by this fixture.
contract DsmHarness is StakingRouter {
 constructor(address locator) StakingRouter(address(1),address(2),locator,7,11) {}
 function admitted(uint256 id) external view returns(bytes32) {
  _checkAppAuth(_getDepositSecurityModule());
  (,ModuleStateConfig storage config)=_getModuleState(id);
  if(config.status!=StakingModuleStatus.Active) revert StakingModuleNotActive();
  return _getWithdrawalCredentialsWithType(config.withdrawalCredentialsType);
 }
 function resolved() external view returns(address) { return _getDepositSecurityModule(); }
}
contract RawLocator {
 bytes response;
 uint256 mode;
 address router;
 uint256 writes;
 function configure(bytes memory data,uint256 action,address caller) external {
  response=data;mode=action;router=caller;
 }
 fallback() external {
  require(msg.sig==bytes4(keccak256("depositSecurityModule()")),"selector");
  require(msg.sender==router,"router caller");
  bytes memory data=response;
  if(mode==1) { assembly {revert(add(data,32),mload(data))} }
  if(mode==2) { writes++; }
  assembly {return(add(data,32),mload(data))}
 }
 function written() external view returns(uint256) {return writes;}
}
