// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @dev The emitted return decoder's increasing mload/mstore loop, isolated
/// for exact byte comparisons. Full SRLib dispatcher/guard refinement is separate.
contract DecoderCopy {
    function copy(bytes calldata input, uint256 offset, uint256 count)
        external pure returns (bytes memory original, bytes memory copied)
    {
        require(offset + 32 * count <= input.length);
        original = input;
        copied = new bytes(32 * count);
        assembly {
            let src := add(add(original, 32), offset)
            let srcEnd := add(src, mul(count, 32))
            let dst := add(copied, 32)
            for { } lt(src, srcEnd) { src := add(src, 32) } {
                mstore(dst, mload(src))
                dst := add(dst, 32)
            }
        }
    }
}
