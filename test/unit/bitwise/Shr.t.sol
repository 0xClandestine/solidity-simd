// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import "test/utils/SIMDTest.t.sol";
import "src/SIMD.sol";

contract ShrLanesTest is SIMDTest {
    function generateInputs(uint256 size, uint256 shifts)
        internal
        view
        returns (uint256 x, uint256 expected)
    {
        unchecked {
            uint256 max = SIMD.laneMax(size);
            uint256 numLanes = 256 / size;

            for (uint256 laneIdx = 0; laneIdx < numLanes; laneIdx++) {
                // Generate random values for each lane
                uint256 xi = vm.randomUint(0, max);

                // Pack values into the correct bit positions
                uint256 shift = laneIdx * size;
                x |= xi << shift;

                // Calculate expected result (logical right shift)
                uint256 expectedLane = xi >> shifts;
                expected |= expectedLane << shift;

                console.log("Lane %d:", laneIdx);
                console.log("  x[%d] = %x", laneIdx, xi);
                console.log("  shifted[%d] = %x", laneIdx, expectedLane);
            }
        }
    }

    function test_shr_2x128(uint256 rng) public setSeed(rng) {
        uint256 shifts = vm.randomUint(0, 128);
        (uint256 x, uint256 expected) = generateInputs(128, shifts);
        uint256 result = SIMD.shr(x, shifts, SIMD.LSB_2x128, 128);
        assertEq(result, expected, "shr result incorrect");
    }

    function test_shr_4x64(uint256 rng) public setSeed(rng) {
        uint256 shifts = vm.randomUint(0, 64);
        (uint256 x, uint256 expected) = generateInputs(64, shifts);
        uint256 result = SIMD.shr(x, shifts, SIMD.LSB_4x64, 64);
        assertEq(result, expected, "shr result incorrect");
    }

    function test_shr_8x32(uint256 rng) public setSeed(rng) {
        uint256 shifts = vm.randomUint(0, 32);
        (uint256 x, uint256 expected) = generateInputs(32, shifts);
        uint256 result = SIMD.shr(x, shifts, SIMD.LSB_8x32, 32);
        assertEq(result, expected, "shr result incorrect");
    }

    function test_shr_16x16(uint256 rng) public setSeed(rng) {
        uint256 shifts = vm.randomUint(0, 16);
        (uint256 x, uint256 expected) = generateInputs(16, shifts);
        uint256 result = SIMD.shr(x, shifts, SIMD.LSB_16x16, 16);
        assertEq(result, expected, "shr result incorrect");
    }

    function test_shr_32x8(uint256 rng) public setSeed(rng) {
        uint256 shifts = vm.randomUint(0, 8);
        (uint256 x, uint256 expected) = generateInputs(8, shifts);
        uint256 result = SIMD.shr(x, shifts, SIMD.LSB_32x8, 8);
        assertEq(result, expected, "shr result incorrect");
    }
}
