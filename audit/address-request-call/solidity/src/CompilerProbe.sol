pragma solidity 0.8.9;
import "./@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol";
interface TokenProbe { function transferFrom(address,address,uint256) external returns(bool); function getSharesByPooledEth(uint256) external view returns(uint256); }
// Compiler-only witness of the same unused-return call and library operations.
contract CompilerProbe {
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet internal ids;
    function calls(TokenProbe token,uint256 a) external returns(uint256) { token.transferFrom(msg.sender,address(this),a); return token.getSharesByPooledEth(a); }
    function insert(uint256 id) external { assert(ids.add(id)); }
}
