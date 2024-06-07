// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Taxable} from "./Taxable.sol";

/*
 * @title Agent Token
 * @author Dreski3
 * Minting: Airdrop
 * @dev A taxable token with a fixed supply to serve as a utility withing the Fungi Agent ecosystem.
 */

contract AGENTToken is ERC20, Ownable, ERC20Permit, Taxable {
    string private _tokenURI;
    uint256 private _maxSupply;
    mapping(address => uint256) private _allowedMint;

    event AllowedMintUpdated(address indexed account, uint256 amount);

    constructor(address owner, uint256 maxSupply, string memory uri, uint256 taxPercentage, address taxRecipient)
        ERC20("AGENT Token", "AGENT")
        ERC20Permit("AGENT Token")
        Taxable(taxPercentage, taxRecipient)
    {
        _transferOwnership(owner);
        _tokenURI = uri;
        _maxSupply = maxSupply;
    }

    /* Public functions */

    function setTokenURI(string memory newuri) public onlyOwner {
        _tokenURI = newuri;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address sender = _msgSender();
        uint256 taxAmount = _calculateTax(amount, to);
        uint256 transferAmount = amount - taxAmount;

        _transfer(sender, to, transferAmount);
        _transfer(sender, _getTaxRecipient(), taxAmount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        uint256 taxAmount = _calculateTax(amount, to);
        uint256 transferAmount = amount - taxAmount;

        _spendAllowance(from, spender, amount);
        _transfer(from, to, transferAmount);
        _transfer(from, _getTaxRecipient(), taxAmount);

        return true;
    }

    /* External functions */

    function setAllowedMint(address account, uint256 amount) external onlyOwner {
        require(amount <= _maxSupply - totalSupply(), "Amount exceeds max supply");
        _allowedMint[account] = amount;
        emit AllowedMintUpdated(account, amount);
    }

    function updateTaxableContract(address contractAddress, bool isTaxable) external onlyOwner {
        _taxableContracts[contractAddress] = isTaxable;
        emit TaxableContractUpdated(contractAddress, isTaxable);
    }

    function mint() external {
        uint256 allowedAmount = _allowedMint[msg.sender];
        require(allowedAmount > 0, "No allowed mint amount");
        _allowedMint[msg.sender] = 0;
        _mint(msg.sender, allowedAmount);
    }

    /* View functions */
    function getAllowedMint(address account) public view returns (uint256) {
        return _allowedMint[account];
    }

    function tokenURI() public view returns (string memory) {
        return _tokenURI;
    }

    function getTaxPercentage() public view returns (uint256) {
        return _taxPercentage;
    }
}
