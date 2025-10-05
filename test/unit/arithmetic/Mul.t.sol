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
            string memory one;
            string memory two;
            string memory three;
            for (uint256 i = 0; i != 256; i += size) {
                uint256 xBits = vm.randomUint(1, size - 1);
                uint256 yBits = size - xBits;
                uint256 xi = vm.randomUint({ bits: i == 0 ? 0 : xBits });
                uint256 yi = vm.randomUint({ bits: i == 0 ? 0 : yBits });
                one = string.concat(one, " ", vm.toString(xi));
                two = string.concat(two, " ", vm.toString(yi));
                three = string.concat(three, " ", vm.toString(xi * yi));
                x |= xi << i;
                y |= yi << i;
                z |= (xi * yi) << i;
            }
            console.log("x: %s", one);
            console.log("y: %s", two);
            console.log("expected z: %s", three);
        }
    }

    function testFuzz_mul_2x128(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(128, false);
        uint256 result = SIMD.mul(x, y, 128);
        assertEq(result, z);
        // (x, y,) = generateInputs(128, true);
        // vm.expectRevert(stdError.arithmeticError);
        // SIMD.mul(x, y, 128);
    }

    function testFuzz_mul_4x64(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(64, false);
        uint256 result = SIMD.mul(x, y, 64);
        assertEq(result, z);

        // (x, y,) = generateInputs(64, true);
        // vm.expectRevert(stdError.arithmeticError);
        // SIMD.mul(x, y, 64);
    }

    function testFuzz_mul_8x32(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(32, false);
        uint256 result = SIMD.mul(x, y, 32);
        assertEq(result, z);

        // (x, y,) = generateInputs(32, true);
        // vm.expectRevert(stdError.arithmeticError);
        // SIMD.mul(x, y, 32);
    }

    function testFuzz_mul_16x16(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(16, false);
        uint256 result = SIMD.mul(x, y, 16);
        assertEq(result, z);

        // (x, y,) = generateInputs(16, true);
        // vm.expectRevert(stdError.arithmeticError);
        // SIMD.mul(x, y, 16);
    }

    function testFuzz_mul_32x8(uint256 rng) public setSeed(rng) {
        (uint256 x, uint256 y, uint256 z) = generateInputs(8, false);
        uint256 result = SIMD.mul(x, y, 8);

        string memory one;
        bytes memory asBytes = abi.encodePacked(x);
        for (uint256 i; i != 32; i++) {
            one = string.concat(one, " ", vm.toString(uint8(asBytes[i])));
        }
        console.log("actual z: %s", one);
        assertEq(result, z);

        // (x, y,) = generateInputs(8, true);
        // vm.expectRevert(stdError.arithmeticError);
        // SIMD.mul(x, y, 8);
    }
}
