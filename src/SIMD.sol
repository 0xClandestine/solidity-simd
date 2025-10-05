// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/// @notice SWAR (SIMD Within A Register) library for packed integers.
/// @author clandestine.eth
library SIMD {
    uint256 internal constant MSB_128x2 =
        0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
    uint256 internal constant MSB_64x4 =
        0x8888888888888888888888888888888888888888888888888888888888888888;
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

    uint256 internal constant LSB_128x2 =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 internal constant LSB_64x4 =
        0x1111111111111111111111111111111111111111111111111111111111111111;
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

    /// @dev Parallel lane-wise multiplication of packed integers in (bits) time.
    function mul(uint256 x, uint256 y, uint256 bits) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let lsbs := div(not(0), sub(shl(bits, 1), 1))
            let msbs := shl(sub(bits, 1), lsbs)

            // TODO: Check for overflow.

            for { let i := bits } i { i := sub(i, 1) } {
                let bit := and(y, lsbs)
                z := add(z, and(x, sub(shl(bits, bit), bit)))
                x := shl(1, x)
                lsbs := shl(1, lsbs)
            }
        }
    }

    // TODO: Saturating arithmetic operations.

    // TODO: Add remaining arithmetic operations + multiplication check + bitwise operations.

    /// -----------------------------------------------------------------------
    /// Comparisons
    /// -----------------------------------------------------------------------

    /// @dev Parallel lane-wise greater than or equal (>=) comparison of packed integers.
    function gte(uint256 x, uint256 y, uint256 msbs, uint256 bits)
        internal
        pure
        returns (uint256 z)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // diff = (x | msbs) - (y & ~msbs)
            let diff := sub(or(x, msbs), and(y, not(msbs)))
            // z = (((x & ~y) | (~((x ^ y) & msbs) & diff)) & msbs) >> (bits - 1)
            z := shr(sub(bits, 1), and(or(and(x, not(y)), and(not(xor(x, y)), diff)), msbs))
        }
    }

    /// @dev Parallel lane-wise less than or equal (<=) comparison of packed integers.
    function lte(uint256 x, uint256 y, uint256 msbs, uint256 bits)
        internal
        pure
        returns (uint256)
    {
        return gte(y, x, msbs, bits);
    }

    /// @dev Parallel lane-wise less than (<) comparison of packed integers.
    function lt(uint256 x, uint256 y, uint256 msbs, uint256 bits) internal pure returns (uint256) {
        return lsbMask(msbs, bits) & ~gte(x, y, msbs, bits);
    }

    /// @dev Parallel lane-wise greater than (>) comparison of packed integers.
    function gt(uint256 x, uint256 y, uint256 msbs, uint256 bits) internal pure returns (uint256) {
        return lsbMask(msbs, bits) & ~lte(x, y, msbs, bits);
    }

    /// @dev Parallel lane-wise equality (==) comparison of packed integers.
    function eq(uint256 x, uint256 y, uint256 msbs, uint256 bits) internal pure returns (uint256) {
        return gte(x, y, msbs, bits) & gte(y, x, msbs, bits); // TODO: Optimize this.
    }

    /// @dev Parallel lane-wise inequality (!=) comparison of packed integers.
    function neq(uint256 x, uint256 y, uint256 msbs, uint256 bits)
        internal
        pure
        returns (uint256)
    {
        return lsbMask(msbs, bits) & ~eq(x, y, msbs, bits);
    }

    /// -----------------------------------------------------------------------
    /// Bitwise
    /// -----------------------------------------------------------------------

    /// @dev Parallel lane-wise right shift (>>) of packed integers.
    /// Right shifts each lane of `x` by `y` bits.
    function shr(uint256 x, uint256 y, uint256 lsbs, uint256 bits)
        internal
        pure
        returns (uint256 z)
    {
        /// @solidity memory-safe-assembly
        assembly {
            z := and(shr(y, x), mul(lsbs, shr(y, sub(shl(bits, 1), 1))))
        }
    }

    /// @dev Parallel lane-wise left shift (<<) of packed integers.
    /// Left shifts each lane of `x` by `y` bits.
    function shl(uint256 x, uint256 y, uint256 lsbs, uint256 bits)
        internal
        pure
        returns (uint256 z)
    {
        /// @solidity memory-safe-assembly
        assembly {
            z := and(shl(y, x), mul(lsbs, shl(y, sub(shl(sub(bits, y), 1), 1))))
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
            z := mul(x, div(not(0), sub(shl(y, 1), 1)))
        }
    }

    /// @dev Returns a mask with the most significant bit set in each lane.
    /// 0x80808080... for 8-bit lanes, 0x80008000... for 16-bit lanes, etc.
    function msbMask(uint256 bits) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := shl(sub(bits, 1), div(not(0), sub(shl(bits, 1), 1)))
        }
    }

    /// @dev Returns a mask with the least significant bit set in each lane.
    /// 0x01010101... for 8-bit lanes, 0x00010001... for 16-bit lanes, etc.
    function lsbMask(uint256 bits) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(not(0), sub(shl(bits, 1), 1))
        }
    }

    /// @dev Returns a mask with the most significant bit set in each lane.
    /// 0x80808080... for 8-bit lanes, 0x80008000... for 16-bit lanes, etc.
    function msbMask(uint256 lsbs, uint256 bits) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := shl(sub(bits, 1), lsbs)
        }
    }

    /// @dev Returns a mask with the least significant bit set in each lane.
    /// 0x01010101... for 8-bit lanes, 0x00010001... for 16-bit lanes, etc.
    function lsbMask(uint256 msbs, uint256 bits) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := shr(sub(bits, 1), msbs)
        }
    }

    /// @dev Returns the maximum value for a lane `bits`.
    /// 0xFF for 8-bit lanes, 0xFFFF for 16-bit lanes, etc.
    function laneMax(uint256 bits) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sub(shl(bits, 1), 1)
        }
    }

    /// @dev Returns the width of a lane given `lsbs`.
    /// Assumes lanes are evenly sized.
    function laneWidth(uint256 msbs) internal pure returns (uint256 z) {
        unchecked {
            z = msbs & (1 + ~msbs);
        }
    }
}
