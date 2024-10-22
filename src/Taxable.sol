// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * @title Taxable
 * @dev A contract that allows taxing on transfers to specific contracts.
 */

abstract contract Taxable {
    uint256 internal _taxPercentage; // Tax percentage in basis points (e.g., 1% = 100 basis points)
    uint256 internal constant MAX_TAX = 300; // Max tax is 3% (300 basis points)
    uint256 internal constant MIN_TAX = 10; // Min tax is 0.1% (10 basis points)
    address internal _creator;
    address internal _dao;
    mapping(address => bool) internal _taxableContracts;

    event TaxUpdated(uint256 newTaxPercentage);
    event TaxRecipientsUpdated(address newCreator, address newDao);
    event TaxableContractUpdated(address indexed contractAddress, bool isTaxable);

    constructor(uint256 taxPercentage, address creator, address dao) {
        require(taxPercentage >= MIN_TAX && taxPercentage <= MAX_TAX, "Tax percentage out of range");
        require(creator != address(0) && dao != address(0), "Tax recipients cannot be zero address");

        _taxPercentage = taxPercentage;
        _creator = creator;
        _dao = dao;
    }

    /* Internal functions */

    /* View functions */

    function _isContractTaxable(address contractAddress) internal view returns (bool) {
        return _taxableContracts[contractAddress];
    }

    function _calculateTax(uint256 amount, address to) internal view returns (uint256) {
        if (_taxableContracts[to]) {
            return (amount * _taxPercentage) / 10000;
        }
        return 0;
    }

    function _getTaxRecipients() internal view returns (address, address) {
        return (_creator, _dao);
    }
}
