// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Taxable} from "./Taxable.sol";

/**
 * @title AGENTToken
 * @dev A taxable ERC20 token with a fixed supply, designed for use within the Fungi Agent ecosystem.
 * The token includes features such as minting allowances, tax on transfers, and ownership control.
 */
contract AGENTToken is ERC20, Ownable, ERC20Permit, Taxable {
    // Private state variables
    string private _tokenURI; // URI for token metadata
    uint256 private _maxSupply; // Maximum supply of the token
    mapping(address => uint256) private _allowedMint; // Mapping to track allowed mint amounts per address

    // Event declarations
    event AllowedMintUpdated(address indexed account, uint256 amount);

    /**
     * @dev Constructor to initialize the token with specified parameters.
     * @param owner The address of the contract owner.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param maxSupply The maximum supply of the token.
     * @param uri The URI for the token metadata.
     * @param taxPercentage The initial tax percentage for transfers.
     * @param creator The address that receives half of the tax.
     * @param dao The address that receives the other half of the tax.
     */
    constructor(
        address owner,
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory uri,
        uint256 taxPercentage,
        address creator,
        address dao
    ) ERC20(name, symbol) ERC20Permit(name) Taxable(taxPercentage, creator, dao) Ownable(owner) {
        _tokenURI = uri;
        _maxSupply = maxSupply;
    }

    /* Public functions */

    /**
     * @dev Allows the owner to set a new token URI.
     * @param newuri The new URI to be set.
     */
    function setTokenURI(string memory newuri) public onlyOwner {
        _tokenURI = newuri;
    }

    /**
     * @dev Overrides the ERC20 transfer function to include tax deduction.
     * @param to The recipient address.
     * @param amount The amount to transfer.
     * @return A boolean indicating success.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address sender = _msgSender();
        uint256 taxAmount = _calculateTax(amount, to);
        uint256 transferAmount = amount - taxAmount;

        _transfer(sender, to, transferAmount);

        // Split the tax amount between creator and dao
        (address creator, address dao) = _getTaxRecipients();
        uint256 halfTax = taxAmount / 2;
        _transfer(sender, creator, halfTax);
        _transfer(sender, dao, taxAmount - halfTax); // Handle odd tax amounts

        return true;
    }

    /**
     * @dev Overrides the ERC20 transferFrom function to include tax deduction.
     * @param from The address to transfer from.
     * @param to The recipient address.
     * @param amount The amount to transfer.
     * @return A boolean indicating success.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        uint256 taxAmount = _calculateTax(amount, to);
        uint256 transferAmount = amount - taxAmount;

        _spendAllowance(from, spender, amount);
        _transfer(from, to, transferAmount);

        // Split the tax amount between creator and dao
        (address creator, address dao) = _getTaxRecipients();
        uint256 halfTax = taxAmount / 2;
        _transfer(from, creator, halfTax);
        _transfer(from, dao, taxAmount - halfTax); // Handle odd tax amounts

        return true;
    }

    /* External functions */

    /**
     * @dev Allows the owner to set the allowed mint amount for a specific address.
     * @param account The address to set the mint allowance for.
     * @param amount The amount of tokens allowed to mint.
     */
    function setAllowedMint(address account, uint256 amount) external onlyOwner {
        require(amount <= _maxSupply - totalSupply(), "Amount exceeds max supply");
        _allowedMint[account] = amount;
        emit AllowedMintUpdated(account, amount);
    }

    /**
     * @dev Updates the tax status of a contract address.
     * @param contractAddress The address of the contract.
     * @param isTaxable Boolean indicating if the contract is taxable.
     */
    function updateTaxableContract(address contractAddress, bool isTaxable) external onlyOwner {
        _taxableContracts[contractAddress] = isTaxable;
        emit TaxableContractUpdated(contractAddress, isTaxable);
    }

    /**
     * @dev Allows an address to mint tokens up to their allowed amount.
     */
    function mint() external {
        uint256 allowedAmount = _allowedMint[msg.sender];
        require(allowedAmount > 0, "No allowed mint amount");
        _allowedMint[msg.sender] = 0;
        _mint(msg.sender, allowedAmount);
    }

    /**
     * @dev Updates the tax percentage for transfers.
     * @param newTaxPercentage The new tax percentage to be set.
     */
    function updateTaxPercentage(uint256 newTaxPercentage) external onlyOwner {
        require(newTaxPercentage >= MIN_TAX && newTaxPercentage <= MAX_TAX, "Tax percentage out of range");
        _taxPercentage = newTaxPercentage;
        emit TaxUpdated(newTaxPercentage);
    }

    /**
     * @dev Updates the tax recipients' addresses.
     * @param newCreator The new address for the creator.
     * @param newDao The new address for the DAO.
     */
    function updateTaxRecipients(address newCreator, address newDao) external onlyOwner {
        require(newCreator != address(0) && newDao != address(0), "Tax recipients cannot be zero address");
        _creator = newCreator;
        _dao = newDao;
        emit TaxRecipientsUpdated(newCreator, newDao);
    }

    /* View functions */

    /**
     * @dev Returns the allowed mint amount for a specific address.
     * @param account The address to query.
     * @return The allowed mint amount.
     */
    function getAllowedMint(address account) public view returns (uint256) {
        return _allowedMint[account];
    }

    /**
     * @dev Returns the token URI.
     * @return The token URI.
     */
    function tokenURI() public view returns (string memory) {
        return _tokenURI;
    }

    /**
     * @dev Returns the current tax percentage.
     * @return The tax percentage.
     */
    function getTaxPercentage() public view returns (uint256) {
        return _taxPercentage;
    }

    /**
     * @dev Returns the maximum supply of the token.
     * @return The maximum supply.
     */
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Returns the current tax recipients' addresses.
     * @return The creator and DAO addresses.
     */
    function getTaxRecipients() public view returns (address, address) {
        return (_creator, _dao);
    }

    /**
     * @dev Checks if a contract address is taxable.
     * @param contractAddress The address to check.
     * @return Boolean indicating if the contract is taxable.
     */
    function isContractTaxable(address contractAddress) public view returns (bool) {
        return _isContractTaxable(contractAddress);
    }
}
