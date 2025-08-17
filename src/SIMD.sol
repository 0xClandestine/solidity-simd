// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/// @author clandestine.eth
library SIMD {
    uint256 internal constant MSB_32x8 =
        0x8080808080808080808080808080808080808080808080808080808080808080;
    uint256 internal constant MSB_16x16 =
        0x8000800080008000800080008000800080008000800080008000800080008000;
    uint256 internal constant MSB_8x32 =
        0x8000000080000000800000008000000080000000800000008000000080000000;
    uint256 internal constant MSB_4x64 =
        0x8000000000000000800000000000000080000000000000008000000000000000;
    uint256 internal constant MSB_2x128 =
        0x8000000000000000000000000000000080000000000000000000000000000000;

    uint256 internal constant LSB_32x8 =
        0x0101010101010101010101010101010101010101010101010101010101010101;
    uint256 internal constant LSB_16x16 =
        0x0001000100010001000100010001000100010001000100010001000100010001;
    uint256 internal constant LSB_8x32 =
        0x0000000100000001000000010000000100000001000000010000000100000001;
    uint256 internal constant LSB_4x64 =
        0x0000000000000001000000000000000100000000000000010000000000000001;
    uint256 internal constant LSB_2x128 =
        0x0000000000000000000000000000000100000000000000000000000000000001;

    /// -----------------------------------------------------------------------
    /// Arithmetic
    /// -----------------------------------------------------------------------

    /// @notice Parallel lane-wise addition of packed integers.
    function add(uint256 left, uint256 right, uint256 msbs) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := add(left, right)
            // carry = ((left & right) | ((left | right) & ~r)) & msbs
            if and(or(and(left, right), and(or(left, right), not(r))), msbs) {
                mstore(0x00, 0x4e487b71) // Panic(uint256)
                mstore(0x20, 0x11) // arithmetic overflow
                revert(0x1c, 0x24)
            }
        }
    }

    /// @notice Parallel lane-wise subtraction of packed integers.
    function sub(uint256 left, uint256 right, uint256 msbs) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := sub(left, right)
            // borrow = ((~left & right) | (~(left ^ right) & r)) & msbs
            if and(or(and(not(left), right), and(not(xor(left, right)), r)), msbs) {
                mstore(0x00, 0x4e487b71) // Panic(uint256)
                mstore(0x20, 0x11) // arithmetic underflow
                revert(0x1c, 0x24)
            }
        }
    }

    /// @notice Parallel lane-wise multiplication of packed integers.
    function mul(uint256 left, uint256 right, uint256 size) internal pure returns (uint256 r) {
        unchecked {
            uint256 lowerMask = mask(laneMax(size), size << 1);
            uint256 upperMask = ~lowerMask;
            /// @solidity memory-safe-assembly
            assembly {
                let double := div(0x100, mul(size, 2))
                let upper :=
                    div(mul(shr(size, and(left, upperMask)), shr(size, and(right, upperMask))), double)
                let lower := div(mul(and(left, lowerMask), and(right, lowerMask)), double)
                // carry = ((upper | lower) & upperMask)
                if and(or(upper, lower), upperMask) {
                    mstore(0x00, 0x4e487b71) // Panic(uint256)
                    mstore(0x20, 0x11) // arithmetic overflow
                    revert(0x1c, 0x24)
                }
                r := or(shl(size, upper), lower)
            }
        }
    }

    function div(uint256 left, uint256 right, uint256 size) internal pure returns (uint256 r) { }

    // TODO: Add remaining arithmetic operations + multiplication check.

    /// -----------------------------------------------------------------------
    /// Comparisons
    /// -----------------------------------------------------------------------

    /// @notice Parallel lane-wise greater than or equal (>=) comparison for packed integers.
    function gte(uint256 a, uint256 b, uint256 msbs, uint256 size)
        internal
        pure
        returns (uint256 r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // diff = (a | msbs) - (b & ~msbs)
            let diff := sub(or(a, msbs), and(b, not(msbs)))
            // r = (((a & ~b) | (~((a ^ b) & msbs) & diff)) & msbs) >> (size - 1)
            r := shr(sub(size, 1), and(or(and(a, not(b)), and(not(xor(a, b)), diff)), msbs))
        }
    }

    /// @notice Parallel lane-wise less than or equal (<=) comparison for packed integers.
    function lte(uint256 a, uint256 b, uint256 msbs, uint256 size)
        internal
        pure
        returns (uint256)
    {
        return gte(b, a, msbs, size);
    }

    /// @notice Parallel lane-wise less than (<) comparison for packed integers.
    function lt(uint256 a, uint256 b, uint256 msbs, uint256 size) internal pure returns (uint256) {
        return lsbMask(msbs, size) & ~gte(a, b, msbs, size);
    }

    /// @notice Parallel lane-wise greater than (>) comparison for packed integers.
    function gt(uint256 a, uint256 b, uint256 msbs, uint256 size) internal pure returns (uint256) {
        return lsbMask(msbs, size) & ~lte(a, b, msbs, size);
    }

    /// @notice Parallel lane-wise equality (==) comparison for packed integers.
    function eq(uint256 a, uint256 b, uint256 msbs, uint256 size) internal pure returns (uint256) {
        return gte(a, b, msbs, size) & gte(b, a, msbs, size);
    }

    /// @notice Parallel lane-wise inequality (!=) comparison for packed integers.
    function neq(uint256 a, uint256 b, uint256 msbs, uint256 size)
        internal
        pure
        returns (uint256)
    {
        return lsbMask(msbs, size) & ~eq(a, b, msbs, size);
    }

    /// -----------------------------------------------------------------------
    /// Helpers
    /// -----------------------------------------------------------------------

    /// @dev Returns a mask where `x` is repeated every `y` bits.
    /// 0xABABABAB... for mask(0xAB, 8) 0xABCDABCD... for mask(0xABCD, 16) etc.
    function mask(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // @solidity memory-safe-assembly
        assembly {
            z := mul(x, div(not(0), sub(exp(2, y), 1)))
        }
    }

    /// @dev Returns a mask with the most significant bit set in each lane.
    /// 0x80808080... for 8-bit lanes, 0x80008000... for 16-bit lanes, etc.
    function msbMask(uint256 size) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(shl(sub(size, 1), 1), div(not(0), sub(exp(2, size), 1)))
        }
    }

    /// @dev Returns a mask with the least significant bit set in each lane.
    /// 0x01010101... for 8-bit lanes, 0x00010001... for 16-bit lanes, etc.
    function lsbMask(uint256 msbs, uint256 size) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := shr(sub(size, 1), msbs)
        }
    }

    /// @dev Returns the maximum value for a lane `size`.
    /// 0xFF for 8-bit lanes, 0xFFFF for 16-bit lanes, etc.
    function laneMax(uint256 size) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sub(shl(size, 1), 1)
        }
    }
}
