// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import "forge-std/Test.sol";
import { SIMD } from "src/SIMD.sol";

abstract contract SIMDTest is Test {
    /// -----------------------------------------------------------------------
    /// RNG
    /// -----------------------------------------------------------------------

    modifier setSeed(uint256 rng) {
        _setSeed(rng);
        _;
    }

    function _setSeed(uint256 rng) internal {
        vm.setSeed(rng);
    }

    /// -----------------------------------------------------------------------
    /// Assertions
    /// -----------------------------------------------------------------------

    /// @dev Console logs inputs, and formats reverts in hex.
    function assertEq(uint256 a, uint256 b) internal pure override {
        console.log("left: %x right: %x", a, b);
        assertEq(bytes32(a), bytes32(b));
    }

    /// @dev Console logs inputs, and formats reverts in hex.
    function assertEq(uint256 a, uint256 b, string memory err) internal pure override {
        console.log("left: %x right: %x", a, b);
        assertEq(bytes32(a), bytes32(b), err);
    }
}
