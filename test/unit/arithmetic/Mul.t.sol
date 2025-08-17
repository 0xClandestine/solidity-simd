// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import "test/utils/SIMDTest.t.sol";
import "src/SIMD.sol";

contract MulTest is SIMDTest {
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
                uint256 shift = laneIdx * size;

                // TODO: There has to be a more efficient way to do this.
                if (overflow) {
                    while (xi * yi <= max) {
                        xi = vm.randomUint(0, max);
                        yi = vm.randomUint(0, max);
                    }
                } else {
                    while (xi * yi > max) {
                        xi = vm.randomUint(0, max);
                        yi = vm.randomUint(0, max);
                    }
                }

                // Pack values
                x |= xi << shift;
                y |= yi << shift;
                z |= ((xi * yi) & max) << shift;
            }
        }
    }

    function testFuzz_mul_2x128(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(128, false);
        uint256 result = SIMD.mul(x, y, 128);
        assertEq(result, z);

        (x, y,) = generateInputs(128, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.mul(x, y, 128);
    }

    function testFuzz_mul_4x64(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(64, false);
        uint256 result = SIMD.mul(x, y, 64);
        assertEq(result, z);

        (x, y,) = generateInputs(64, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.mul(x, y, 64);
    }

    function testFuzz_mul_8x32(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(32, false);
        uint256 result = SIMD.mul(x, y, 32);
        assertEq(result, z);

        (x, y,) = generateInputs(32, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.mul(x, y, 32);
    }

    function testFuzz_mul_16x16(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(16, false);
        uint256 result = SIMD.mul(x, y, 16);
        assertEq(result, z);

        (x, y,) = generateInputs(16, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.mul(x, y, 16);
    }

    function testFuzz_mul_32x8(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(8, false);
        uint256 result = SIMD.mul(x, y, 8);
        assertEq(result, z);

        (x, y,) = generateInputs(8, true);
        vm.expectRevert(stdError.arithmeticError);
        SIMD.mul(x, y, 8);
    }
}
