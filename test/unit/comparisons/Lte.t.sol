// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import "test/utils/SIMDTest.t.sol";
import "src/SIMD.sol";

contract GteTest is SIMDTest {
    function generateInputs(uint256 size) internal view returns (uint256 x, uint256 y, uint256 z) {
        unchecked {
            uint256 max = SIMD.laneMax(size);
            uint256 numLanes = 256 / size;

            for (uint256 laneIdx = 0; laneIdx < numLanes; laneIdx++) {
                // Generate random values for x and y
                uint256 xi = vm.randomUint(0, max);
                uint256 yi = vm.randomUint(0, max);

                // Compute the comparison result
                uint256 zi = xi <= yi ? 1 : 0;

                // Pack values into the correct bit positions
                uint256 shift = laneIdx * size;
                x |= xi << shift;
                y |= yi << shift;
                z |= zi << shift;

                console.log("Lane %d:", laneIdx);
                console.log("  x[%d] = %d", laneIdx, xi);
                console.log("  y[%d] = %d", laneIdx, yi);
                console.log("  z[%d] = %d (x <= y: %s)", laneIdx, zi, xi <= yi);
            }
        }
    }

    function testFuzz_lte_2x128(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(128);
        uint256 msbs = SIMD.msbMask(128);
        uint256 result = SIMD.lte(x, y, msbs, 128);
        assertEq(result, z);

        uint256 inverseResult = SIMD.lte(y, x, msbs, 128);
        assertEq(result | inverseResult, SIMD.lsbMask(msbs, 128));
    }

    function testFuzz_lte_4x64(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(64);
        uint256 msbs = SIMD.msbMask(64);
        uint256 result = SIMD.lte(x, y, msbs, 64);
        assertEq(result, z);

        uint256 inverseResult = SIMD.lte(y, x, msbs, 64);
        assertEq(result | inverseResult, SIMD.lsbMask(msbs, 64));
    }

    function testFuzz_lte_8x32(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(32);
        uint256 msbs = SIMD.msbMask(32);
        uint256 result = SIMD.lte(x, y, msbs, 32);
        assertEq(result, z);

        uint256 inverseResult = SIMD.lte(y, x, msbs, 32);
        assertEq(result | inverseResult, SIMD.lsbMask(msbs, 32));
    }

    function testFuzz_lte_16x16(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(16);
        uint256 msbs = SIMD.msbMask(16);
        uint256 result = SIMD.lte(x, y, msbs, 16);
        assertEq(result, z);

        uint256 inverseResult = SIMD.lte(y, x, msbs, 16);
        assertEq(result | inverseResult, SIMD.lsbMask(msbs, 16));
    }

    function testFuzz_lte_32x8(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(8);
        uint256 msbs = SIMD.msbMask(8);
        uint256 result = SIMD.lte(x, y, msbs, 8);
        assertEq(result, z);

        uint256 inverseResult = SIMD.lte(y, x, msbs, 8);
        assertEq(result | inverseResult, SIMD.lsbMask(msbs, 8));
    }
}
