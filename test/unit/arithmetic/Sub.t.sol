// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import "test/utils/SIMDTest.t.sol";
import "src/SIMD.sol";

contract SubTest is SIMDTest {
    function generateInputs(uint256 size, bool underflow)
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
                if (underflow) {
                    // To guarantee underflow, xi < yi
                    yi = vm.randomUint(1, max); // yi in [1, max]
                    xi = vm.randomUint(0, yi - 1); // xi in [0, yi-1], ensures xi < yi
                } else {
                    // To guarantee no underflow, xi >= yi
                    xi = vm.randomUint(0, max); // xi in [0, max]
                    yi = vm.randomUint(0, xi); // yi in [0, xi], ensures xi >= yi
                }

                // Pack values into the correct bit positions
                uint256 shift = laneIdx * size;
                x |= xi << shift;
                y |= yi << shift;
                z |= (xi - yi) << shift;

                console.log("Lane %d:", laneIdx);
                console.log("  x[%d] = %d", laneIdx, xi);
                console.log("  y[%d] = %d", laneIdx, yi);
                console.log("  z[%d] = %d", laneIdx, xi - yi);
                if (underflow) {
                    require(xi < yi, "inputs must underflow");
                } else {
                    require(xi >= yi, "inputs must not underflow");
                }
            }
        }
    }

    function testFuzz_sub_2x128(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(128, false);
        uint256 msbs = SIMD.MSB_2x128;
        uint256 result = SIMD.sub(x, y, msbs);
        assertEq(result, z);

        (x, y,) = generateInputs(128, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.sub(x, y, msbs);
    }

    function testFuzz_sub_4x64(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(64, false);
        uint256 msbs = SIMD.MSB_4x64;
        uint256 result = SIMD.sub(x, y, msbs);
        assertEq(result, z);

        (x, y,) = generateInputs(64, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.sub(x, y, msbs);
    }

    function testFuzz_sub_8x32(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(32, false);
        uint256 msbs = SIMD.MSB_8x32;
        uint256 result = SIMD.sub(x, y, msbs);
        assertEq(result, z);

        (x, y,) = generateInputs(32, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.sub(x, y, msbs);
    }

    function testFuzz_sub_16x16(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(16, false);
        uint256 msbs = SIMD.MSB_16x16;
        uint256 result = SIMD.sub(x, y, msbs);
        assertEq(result, z);

        (x, y,) = generateInputs(16, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.sub(x, y, msbs);
    }

    function testFuzz_sub_32x8(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(8, false);
        uint256 msbs = SIMD.MSB_32x8;
        uint256 result = SIMD.sub(x, y, msbs);
        assertEq(result, z);

        (x, y,) = generateInputs(8, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.sub(x, y, msbs);
    }
}
