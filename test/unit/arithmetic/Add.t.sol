// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import "test/utils/SIMDTest.t.sol";
import "src/SIMD.sol";

contract AddTest is SIMDTest {
    function generateInputs(uint256 size, bool overflow)
        internal
        view
        returns (uint256 x, uint256 y, uint256 z)
    {
        unchecked {
            uint256 max = SIMD.laneMax(size);
            uint256 numLanes = 256 / size;

            for (uint256 laneIdx = 0; laneIdx < numLanes; laneIdx++) {
                uint256 xi;
                uint256 yi;
                if (overflow) {
                    // To guarantee overflow, xi in [1, max], yi in [max - xi + 1, max]
                    xi = vm.randomUint(1, max);
                    uint256 minYi = max - xi + 1;
                    if (minYi > max) minYi = max; // Clamp in case xi=0
                    yi = vm.randomUint(minYi, max);
                } else {
                    // To guarantee no overflow, xi in [0, max], yi in [0, max - xi]
                    xi = vm.randomUint(0, max);
                    uint256 maxYi = max - xi;
                    yi = vm.randomUint(0, maxYi);
                }

                // Pack values into the correct bit positions
                uint256 shift = laneIdx * size;
                x |= xi << shift;
                y |= yi << shift;
                z |= (xi + yi) << shift;

                console.log("Lane %d:", laneIdx);
                console.log("  x[%d] = %d", laneIdx, xi);
                console.log("  y[%d] = %d", laneIdx, yi);
                console.log("  z[%d] = %d", laneIdx, xi + yi);
                if (overflow) {
                    require(xi + yi > max, "inputs must overflow");
                } else {
                    require(xi + yi <= max, "inputs must not overflow");
                }
            }
        }
    }

    function testFuzz_add_2x128(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(128, false);
        uint256 msbs = SIMD.msbMask(128);
        uint256 result = SIMD.add(x, y, msbs);
        assertEq(result, z);

        (x, y,) = generateInputs(128, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.add(x, y, msbs);
    }

    function testFuzz_add_4x64(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(64, false);
        uint256 msbs = SIMD.msbMask(64);
        uint256 result = SIMD.add(x, y, msbs);
        assertEq(result, z);

        (x, y,) = generateInputs(64, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.add(x, y, msbs);
    }

    function testFuzz_add_8x32(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(32, false);
        uint256 msbs = SIMD.msbMask(32);
        uint256 result = SIMD.add(x, y, msbs);
        assertEq(result, z);

        (x, y,) = generateInputs(32, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.add(x, y, msbs);
    }

    function testFuzz_add_16x16(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(16, false);
        uint256 msbs = SIMD.msbMask(16);
        uint256 result = SIMD.add(x, y, msbs);
        assertEq(result, z);

        (x, y,) = generateInputs(16, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.add(x, y, msbs);
    }

    function testFuzz_add_32x8(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(8, false);
        uint256 msbs = SIMD.msbMask(8);
        uint256 result = SIMD.add(x, y, msbs);
        assertEq(result, z);

        (x, y,) = generateInputs(8, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.add(x, y, msbs);
    }
}
