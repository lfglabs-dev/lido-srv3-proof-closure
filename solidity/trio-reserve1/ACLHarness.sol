pragma solidity 0.4.24;
import "@aragon/os/contracts/acl/ACL.sol";

// Fixture configuration only. All permission queries, parameter evaluation,
// logic short-circuiting and oracle calls are inherited unchanged.
contract ACLHarness is ACL {
    function fixtureGrant(address who, address app, bytes32 role, uint256[] params) external {
        _setPermission(who, app, role, params.length == 0 ? EMPTY_PARAM_HASH : _saveParams(params));
    }
    function fixtureRevoke(address who, address app, bytes32 role) external {
        _setPermission(who, app, role, bytes32(0));
    }
}

contract ACLWritingOracle {
    uint256 public written;
    function canPerform(address, address, bytes32, uint256[]) external returns (bool) {
        written = 1;
        return true;
    }
}
