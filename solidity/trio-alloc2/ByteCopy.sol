// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ByteCopy {
    function copyCalldata(bytes calldata input) external pure returns (bytes memory out) {
        out = new bytes(input.length);
        assembly { calldatacopy(add(out, 32), input.offset, input.length) }
    }
    function echo(bytes calldata input) external pure {
        assembly {
            calldatacopy(0, input.offset, input.length)
            return(0, input.length)
        }
    }
    function copyReturn(bytes calldata input) external view returns (bytes memory out) {
        (bool ok,) = address(this).staticcall(abi.encodeWithSelector(this.echo.selector, input));
        require(ok);
        uint256 size;
        assembly { size := returndatasize() }
        out = new bytes(size);
        assembly { returndatacopy(add(out, 32), 0, size) }
    }
}
