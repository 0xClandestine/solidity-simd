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

    /// @dev Parallel lane-wise addition of packed integers.
    function add(uint256 x, uint256 y, uint256 msbs) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := add(x, y)
            // carry = ((x & y) | ((x | y) & ~z)) & msbs
            if and(or(and(x, y), and(or(x, y), not(z))), msbs) {
                mstore(0x00, 0x4e487b71) // Panic(uint256)
                mstore(0x20, 0x11) // arithmetic overflow
                revert(0x1c, 0x24)
            }
        }
    }

    /// @dev Parallel lane-wise subtraction of packed integers.
    function sub(uint256 x, uint256 y, uint256 msbs) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sub(x, y)
            // borrow = ((~x & y) | (~(x ^ y) & z)) & msbs
            if and(or(and(not(x), y), and(not(xor(x, y)), z)), msbs) {
                mstore(0x00, 0x4e487b71) // Panic(uint256)
                mstore(0x20, 0x11) // arithmetic underflow
                revert(0x1c, 0x24)
            }
        }
    }

    /// @dev Parallel lane-wise multiplication of packed integers.
    function mul(uint256 x, uint256 y, uint256 size) internal pure returns (uint256 z) {
        unchecked {
            uint256 lowerMask = mask(laneMax(size), size << 1);
            uint256 upperMask = ~lowerMask;
            /// @solidity memory-safe-assembly
            assembly {
                let double := div(0x100, mul(size, 2))
                let upper :=
                    div(mul(shr(size, and(x, upperMask)), shr(size, and(y, upperMask))), double)
                let lower := div(mul(and(x, lowerMask), and(y, lowerMask)), double)
                // carry = ((upper | lower) & upperMask)
                if and(or(upper, lower), upperMask) {
                    mstore(0x00, 0x4e487b71) // Panic(uint256)
                    mstore(0x20, 0x11) // arithmetic overflow
                    revert(0x1c, 0x24)
                }
                z := or(shl(size, upper), lower)
            }
        }
    }

    // TODO: Add remaining arithmetic operations + multiplication check.

    /// -----------------------------------------------------------------------
    /// Comparisons
    /// -----------------------------------------------------------------------

    /// @dev Parallel lane-wise greater than or equal (>=) comparison of packed integers.
    function gte(uint256 x, uint256 y, uint256 msbs, uint256 size)
        internal
        pure
        returns (uint256 z)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // diff = (x | msbs) - (y & ~msbs)
            let diff := sub(or(x, msbs), and(y, not(msbs)))
            // z = (((x & ~y) | (~((x ^ y) & msbs) & diff)) & msbs) >> (size - 1)
            z := shr(sub(size, 1), and(or(and(x, not(y)), and(not(xor(x, y)), diff)), msbs))
        }
    }

    /// @dev Parallel lane-wise less than or equal (<=) comparison of packed integers.
    function lte(uint256 x, uint256 y, uint256 msbs, uint256 size)
        internal
        pure
        returns (uint256)
    {
        return gte(y, x, msbs, size);
    }

    /// @dev Parallel lane-wise less than (<) comparison of packed integers.
    function lt(uint256 x, uint256 y, uint256 msbs, uint256 size) internal pure returns (uint256) {
        return lsbMask(msbs, size) & ~gte(x, y, msbs, size);
    }

    /// @dev Parallel lane-wise greater than (>) comparison of packed integers.
    function gt(uint256 x, uint256 y, uint256 msbs, uint256 size) internal pure returns (uint256) {
        return lsbMask(msbs, size) & ~lte(x, y, msbs, size);
    }

    /// @dev Parallel lane-wise equality (==) comparison of packed integers.
    function eq(uint256 x, uint256 y, uint256 msbs, uint256 size) internal pure returns (uint256) {
        // TODO: Optimize this.
        return gte(x, y, msbs, size) & gte(y, x, msbs, size);
    }

    /// @dev Parallel lane-wise inequality (!=) comparison of packed integers.
    function neq(uint256 x, uint256 y, uint256 msbs, uint256 size)
        internal
        pure
        returns (uint256)
    {
        return lsbMask(msbs, size) & ~eq(x, y, msbs, size);
    }

    /// -----------------------------------------------------------------------
    /// Bitwise
    /// -----------------------------------------------------------------------

    /// @dev Parallel lane-wise right shift (>>) of packed integers.
    /// Right shifts each lane of `x` by `y` bits.
    function shr(uint256 x, uint256 y, uint256 lsbs, uint256 size)
        internal
        pure
        returns (uint256 z)
    {
        uint256 max = laneMax(size);
        /// @solidity memory-safe-assembly
        assembly {
            z := and(shr(y, x), mul(lsbs, shr(y, max)))
        }
    }

    /// @dev Parallel lane-wise left shift (<<) of packed integers.
    /// Left shifts each lane of `x` by `y` bits.
    function shl(uint256 x, uint256 y, uint256 lsbs, uint256 size)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return (x << y) & (lsbs * (laneMax(size - y) << y));
        }
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
    function lsbMask(uint256 size) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(1, div(not(0), sub(exp(2, size), 1)))
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
