// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AGENTToken} from "src/AGENTToken.sol";

/**
 * @title AGENTTokenTestWrapper
 * @dev A wrapper contract for testing internal functions of AGENTToken.
 */
contract AGENTTokenTestWrapper is AGENTToken {
    constructor(
        address owner,
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory uri,
        uint256 taxPercentage,
        address creator,
        address dao
    ) AGENTToken(owner, name, symbol, maxSupply, uri, taxPercentage, creator, dao) {}

    /**
     * @dev Expose the internal _calculateTax function for testing.
     * @param amount The amount to calculate tax on.
     * @param to The recipient address.
     * @return The calculated tax amount.
     */
    function calculateTax(uint256 amount, address to) external view returns (uint256) {
        return _calculateTax(amount, to);
    }
}
