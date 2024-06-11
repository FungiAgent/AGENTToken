// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * @title Taxable
 * @author Dreski3
 * @dev A contract that allows for the implementation of a tax on transfers to specific contracts.
 */

abstract contract Taxable {
    uint256 internal _taxPercentage; // Tax percentage in basis points (e.g., 1% = 100 basis points)
    uint256 internal constant MAX_TAX = 300; // Max tax is 3% (300 basis points)
    uint256 internal constant MIN_TAX = 10; // Min tax is 0.1% (10 basis points)
    address internal _taxRecipient;
    bool internal _taxEnabled;
    mapping(address => bool) internal _taxableContracts;

    event TaxUpdated(uint256 newTaxPercentage);
    event TaxRecipientUpdated(address newTaxRecipient);
    event TaxStatusUpdated(bool isEnabled);
    event TaxableContractUpdated(address indexed contractAddress, bool isTaxable);

    constructor(uint256 taxPercentage, address taxRecipient) {
        require(taxPercentage >= MIN_TAX && taxPercentage <= MAX_TAX, "Tax percentage out of range");
        require(taxRecipient != address(0), "Tax recipient cannot be zero address");

        _taxPercentage = taxPercentage;
        _taxRecipient = taxRecipient;
        _taxEnabled = true; // Tax is enabled by default
    }

    function isContractTaxable(address contractAddress) public view returns (bool) {
        return _taxableContracts[contractAddress];
    }

    function _calculateTax(uint256 amount, address to) internal view returns (uint256) {
        if (_taxEnabled && _taxableContracts[to]) {
            return (amount * _taxPercentage) / 10000;
        }
        return 0;
    }

    function _flipTaxStatus() internal {
        _taxEnabled = !_taxEnabled;
        emit TaxStatusUpdated(_taxEnabled);
    }

    function _getTaxRecipient() internal view returns (address) {
        return _taxRecipient;
    }
}
