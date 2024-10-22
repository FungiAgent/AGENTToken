// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {AGENTToken} from "src/AGENTToken.sol";
import {AGENTTokenTestWrapper} from "./AGENTTokenTestWrapper.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {DeployAGENT} from "script/DeployAGENT.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract AGENTTokenTest is Test {
    AGENTTokenTestWrapper agentToken;
    address public owner;
    string public name = "AGENT Token";
    string public symbol = "AGENT";
    uint256 public maxSupply = 999999999;
    string public uri = "https://token-uri.com";
    uint256 public taxPercentage = 100;
    address public creator;
    address public dao;

    // Events to be used in the tests
    event AllowedMintUpdated(address indexed account, uint256 allowedAmount);
    event TaxableContractUpdated(address indexed contractAddress, bool taxable);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Setup function to prepare the environment for testing
    function setUp() public {
        owner = address(this);
        creator = address(0x1);
        dao = address(0x2);
        agentToken = new AGENTTokenTestWrapper(owner, name, symbol, maxSupply, uri, taxPercentage, creator, dao);
    }

    // Test the constructor sets correct initial parameters
    function testConstructorSetsCorrectInitialParameters() public view {
        assertEq(agentToken.owner(), owner);
        assertEq(agentToken.getMaxSupply(), maxSupply);
        assertEq(agentToken.getTaxPercentage(), taxPercentage);
        assertEq(agentToken.tokenURI(), uri);
        assertEq(agentToken.balanceOf(owner), 0);
        assertEq(agentToken.totalSupply(), 0);
    }

    // Test setTokenURI function with the owner address
    function testSetTokenURIWithOwner() public {
        string memory newURI = "https://new-token-uri.com";
        agentToken.setTokenURI(newURI);
        assertEq(agentToken.tokenURI(), newURI);
    }

    // Test setTokenURI function with a non-owner address
    function testSetTokenURIWithNonOwner() public {
        address nonOwner = address(0x1234);
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        agentToken.setTokenURI("https://another-token-uri.com");
    }

    // Test setAllowedMint function with the owner address
    function testSetAllowedMintWithOwner() public {
        address account = address(0x5678);
        uint256 allowedAmount = 1000;

        vm.expectEmit(true, true, true, true);
        emit AllowedMintUpdated(account, allowedAmount);
        agentToken.setAllowedMint(account, allowedAmount);

        assertEq(agentToken.getAllowedMint(account), allowedAmount);
    }

    // Test setAllowedMint function with a non-owner address
    function testSetAllowedMintWithNonOwner() public {
        address nonOwner = address(0x1234);
        address account = address(0x5678);
        uint256 allowedAmount = 1000;

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        agentToken.setAllowedMint(account, allowedAmount);
    }

    // Test setAllowedMint with an amount exceeding the maximum supply
    function testSetAllowedMintExceedingMaxSupply() public {
        address account = address(0x5678);
        uint256 allowedAmount = maxSupply + 1;

        vm.expectRevert("Amount exceeds max supply");
        agentToken.setAllowedMint(account, allowedAmount);
    }

    // Test setAllowedMint with an amount within the maximum supply
    function testSetAllowedMintWithinMaxSupply() public {
        address account = address(0x5678);
        uint256 allowedAmount = maxSupply;

        vm.expectEmit(true, true, true, true);
        emit AllowedMintUpdated(account, allowedAmount);
        agentToken.setAllowedMint(account, allowedAmount);

        assertEq(agentToken.getAllowedMint(account), allowedAmount);
    }

    // Test mint function for an allowed address
    function testMintForAllowedAddress() public {
        address allowedAddress = address(0x5678);
        uint256 allowedAmount = 1000;

        agentToken.setAllowedMint(allowedAddress, allowedAmount);
        vm.prank(allowedAddress);
        agentToken.mint();

        assertEq(agentToken.balanceOf(allowedAddress), allowedAmount);
        assertEq(agentToken.getAllowedMint(allowedAddress), 0);
        assertEq(agentToken.totalSupply(), allowedAmount);
    }

    // Test mint function for a non-allowed address
    function testMintForNonAllowedAddress() public {
        address nonAllowedAddress = address(0x9abc);

        vm.prank(nonAllowedAddress);
        vm.expectRevert("No allowed mint amount");
        agentToken.mint();
    }

    // Test updateTaxableContract function with the owner address
    function testUpdateTaxableContractWithOwner() public {
        address contractAddress = address(0x1111);

        vm.expectEmit(true, true, true, true);
        emit TaxableContractUpdated(contractAddress, true);
        agentToken.updateTaxableContract(contractAddress, true);
        assertTrue(agentToken.isContractTaxable(contractAddress));

        vm.expectEmit(true, true, true, true);
        emit TaxableContractUpdated(contractAddress, false);
        agentToken.updateTaxableContract(contractAddress, false);
        assertFalse(agentToken.isContractTaxable(contractAddress));
    }

    // Test updateTaxableContract function with the owner address and false value
    function testUpdateTaxableContractWithOwnerFalse() public {
        address contractAddress = address(0x1111);

        vm.expectEmit(true, true, true, true);
        emit TaxableContractUpdated(contractAddress, false);
        agentToken.updateTaxableContract(contractAddress, false);
        assertFalse(agentToken.isContractTaxable(contractAddress));
    }

    // Test updateTaxableContract function with a non-owner address
    function testUpdateTaxableContractWithNonOwner() public {
        address nonOwner = address(0x1234);
        address contractAddress = address(0x1111);

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        agentToken.updateTaxableContract(contractAddress, true);
    }

    // Test transfer function with tax enabled
    function testTransferWithTaxEnabled() public {
        address sender = address(0x1234);
        address recipient = address(0x7890);
        uint256 transferAmount = 1000;

        // Update recipient address as a taxable contract
        agentToken.updateTaxableContract(recipient, true);

        // Mint tokens to the sender
        agentToken.setAllowedMint(sender, transferAmount);
        vm.prank(sender);
        agentToken.mint();

        // Check initial balances
        assertEq(agentToken.balanceOf(sender), transferAmount);
        assertEq(agentToken.balanceOf(recipient), 0);
        assertEq(agentToken.balanceOf(creator), 0);
        assertEq(agentToken.balanceOf(dao), 0);

        // Transfer tokens
        uint256 taxAmount = (transferAmount * taxPercentage) / 10000; // 1% of 1000 = 10
        uint256 expectedTransferAmount = transferAmount - taxAmount;
        uint256 halfTax = taxAmount / 2;

        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient, expectedTransferAmount);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, creator, halfTax);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, dao, taxAmount - halfTax);

        vm.prank(sender);
        agentToken.transfer(recipient, transferAmount);

        // Check final balances
        assertEq(agentToken.balanceOf(sender), 0);
        assertEq(agentToken.balanceOf(recipient), expectedTransferAmount);
        assertEq(agentToken.balanceOf(creator), halfTax);
        assertEq(agentToken.balanceOf(dao), taxAmount - halfTax);
    }

    // Test transfer function with tax disabled
    function testTransferWithTaxDisabled() public {
        address sender = address(0x1234);
        address recipient = address(0x7890);
        uint256 transferAmount = 1000;

        // Mint tokens to the sender
        agentToken.setAllowedMint(sender, transferAmount);
        vm.prank(sender);
        agentToken.mint();

        // Check initial balances
        assertEq(agentToken.balanceOf(sender), transferAmount);
        assertEq(agentToken.balanceOf(recipient), 0);
        assertEq(agentToken.balanceOf(creator), 0);
        assertEq(agentToken.balanceOf(dao), 0);

        // Transfer tokens
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient, transferAmount);

        vm.prank(sender);
        agentToken.transfer(recipient, transferAmount);

        // Check final balances
        assertEq(agentToken.balanceOf(sender), 0);
        assertEq(agentToken.balanceOf(recipient), transferAmount);
        assertEq(agentToken.balanceOf(creator), 0);
        assertEq(agentToken.balanceOf(dao), 0);
    }

    // Test transferFrom function with tax enabled
    function testTransferFromWithTaxEnabled() public {
        address sender = address(0x1234);
        address recipient = address(0x7890);
        address spender = address(this);
        uint256 transferAmount = 1000;

        // Update recipient address as a taxable contract
        agentToken.updateTaxableContract(recipient, true);

        // Mint tokens to the sender
        agentToken.setAllowedMint(sender, transferAmount);
        vm.prank(sender);
        agentToken.mint();

        // Approve the spender to transfer tokens on behalf of the sender
        vm.prank(sender);
        agentToken.approve(spender, transferAmount);

        // Check initial balances and allowance
        assertEq(agentToken.balanceOf(sender), transferAmount);
        assertEq(agentToken.balanceOf(recipient), 0);
        assertEq(agentToken.balanceOf(creator), 0);
        assertEq(agentToken.balanceOf(dao), 0);
        assertEq(agentToken.allowance(sender, spender), transferAmount);

        // Transfer tokens
        uint256 taxAmount = (transferAmount * taxPercentage) / 10000; // 1% of 1000 = 10
        uint256 expectedTransferAmount = transferAmount - taxAmount;
        uint256 halfTax = taxAmount / 2;

        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient, expectedTransferAmount);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, creator, halfTax);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, dao, taxAmount - halfTax);

        agentToken.transferFrom(sender, recipient, transferAmount);

        // Check final balances and remaining allowance
        assertEq(agentToken.balanceOf(sender), 0);
        assertEq(agentToken.balanceOf(recipient), expectedTransferAmount);
        assertEq(agentToken.balanceOf(creator), halfTax);
        assertEq(agentToken.balanceOf(dao), taxAmount - halfTax);
        assertEq(agentToken.allowance(sender, spender), 0);
    }

    // Test transferFrom function with tax disabled
    function testTransferFromWithTaxDisabled() public {
        address sender = address(0x1234);
        address recipient = address(0x7890);
        address spender = address(this);
        uint256 transferAmount = 1000;

        // Mint tokens to the sender
        agentToken.setAllowedMint(sender, transferAmount);
        vm.prank(sender);
        agentToken.mint();

        // Approve the spender to transfer tokens on behalf of the sender
        vm.prank(sender);
        agentToken.approve(spender, transferAmount);

        // Check initial balances and allowance
        assertEq(agentToken.balanceOf(sender), transferAmount);
        assertEq(agentToken.balanceOf(recipient), 0);
        assertEq(agentToken.balanceOf(creator), 0);
        assertEq(agentToken.balanceOf(dao), 0);
        assertEq(agentToken.allowance(sender, spender), transferAmount);

        // Transfer tokens
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient, transferAmount);

        agentToken.transferFrom(sender, recipient, transferAmount);

        // Check final balances and remaining allowance
        assertEq(agentToken.balanceOf(sender), 0);
        assertEq(agentToken.balanceOf(recipient), transferAmount);
        assertEq(agentToken.balanceOf(creator), 0);
        assertEq(agentToken.balanceOf(dao), 0);
        assertEq(agentToken.allowance(sender, spender), 0);
    }

    // Test the ERC20 approve function
    function testApprove() public {
        address sender = address(0x1234);
        address spender = address(0x5678);
        uint256 allowedAmount = 1000;

        // Mint tokens to the sender
        agentToken.setAllowedMint(sender, allowedAmount);
        vm.prank(sender);
        agentToken.mint();

        // Approve the spender
        vm.prank(sender);
        agentToken.approve(spender, allowedAmount);

        assertEq(agentToken.allowance(sender, spender), allowedAmount);
    }

    // Test the ERC20 totalSupply function
    function testTotalSupply() public {
        address account1 = address(0x1234);
        address account2 = address(0x5678);
        uint256 amount1 = 1000;
        uint256 amount2 = 2000;

        // Mint tokens to account1
        agentToken.setAllowedMint(account1, amount1);
        vm.prank(account1);
        agentToken.mint();

        // Mint tokens to account2
        agentToken.setAllowedMint(account2, amount2);
        vm.prank(account2);
        agentToken.mint();

        assertEq(agentToken.totalSupply(), amount1 + amount2);
    }

    // Test setting the tax percentage to the minimum allowed value
    function testSetTaxPercentageToMinimum() public {
        uint256 minTaxPercentage = 10; // 0.1%

        agentToken.updateTaxPercentage(minTaxPercentage);
        assertEq(agentToken.getTaxPercentage(), minTaxPercentage);
    }

    // Test setting the tax percentage to the maximum allowed value
    function testSetTaxPercentageToMaximum() public {
        uint256 maxTaxPercentage = 300; // 3%

        agentToken.updateTaxPercentage(maxTaxPercentage);
        assertEq(agentToken.getTaxPercentage(), maxTaxPercentage);
    }

    // Test setting the tax percentage to an invalid value (below minimum)
    function testSetTaxPercentageBelowMinimum() public {
        uint256 invalidTaxPercentage = 5; // 0.05%

        vm.expectRevert("Tax percentage out of range");
        agentToken.updateTaxPercentage(invalidTaxPercentage);
    }

    // Test setting the tax percentage to an invalid value (above maximum)
    function testSetTaxPercentageAboveMaximum() public {
        uint256 invalidTaxPercentage = 500; // 5%

        vm.expectRevert("Tax percentage out of range");
        agentToken.updateTaxPercentage(invalidTaxPercentage);
    }

    // Test setting the tax recipient to the zero address
    function testSetTaxRecipientToZeroAddress() public {
        address zeroAddress = address(0);

        vm.expectRevert("Tax recipients cannot be zero address");
        agentToken.updateTaxRecipients(zeroAddress, zeroAddress);
    }

    // Test setting the tax recipient to a valid address
    function testSetTaxRecipientToValidAddress() public {
        address newCreator = address(0x1234);
        address newDao = address(0x5678);
        agentToken.updateTaxRecipients(newCreator, newDao);

        (address currentCreator, address currentDao) = agentToken.getTaxRecipients();
        assertEq(currentCreator, newCreator);
        assertEq(currentDao, newDao);
    }

    // Test tax calculation directly
    function testCalculateTax() public {
        address recipient = address(0x7890);
        uint256 amount = 1000;

        // Update recipient address as a taxable contract
        agentToken.updateTaxableContract(recipient, true);

        uint256 expectedTax = (amount * taxPercentage) / 10000;
        uint256 calculatedTax = agentToken.calculateTax(amount, recipient);

        assertEq(calculatedTax, expectedTax);
    }

    // Test transfer with tax update
    function testTransferWithTaxUpdate() public {
        address sender = address(0x1234);
        address recipient = address(0x7890);
        uint256 transferAmount = 1000;
        uint256 allowedMint = 2000;

        // Mint tokens to the sender
        agentToken.setAllowedMint(sender, allowedMint);
        vm.prank(sender);
        agentToken.mint();

        // Update recipient address as a taxable contract
        agentToken.updateTaxableContract(recipient, true);

        // Initial transfer with current tax
        uint256 initialTaxAmount = (transferAmount * taxPercentage) / 10000;
        uint256 initialExpectedTransferAmount = transferAmount - initialTaxAmount;
        uint256 initialHalfTax = initialTaxAmount / 2;

        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient, initialExpectedTransferAmount);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, creator, initialHalfTax);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, dao, initialTaxAmount - initialHalfTax);

        vm.prank(sender);
        agentToken.transfer(recipient, transferAmount);

        // Update tax percentage
        uint256 newTaxPercentage = 300; // 3%
        agentToken.updateTaxPercentage(newTaxPercentage);

        // Transfer again with updated tax
        uint256 newTaxAmount = (transferAmount * newTaxPercentage) / 10000;
        uint256 expectedTransferAmount = transferAmount - newTaxAmount;
        uint256 newHalfTax = newTaxAmount / 2;

        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient, expectedTransferAmount);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, creator, newHalfTax);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, dao, newTaxAmount - newHalfTax);

        vm.prank(sender);
        agentToken.transfer(recipient, transferAmount);

        // Assert that the recipient received the correct amount after tax
        assertEq(agentToken.balanceOf(recipient), initialExpectedTransferAmount + expectedTransferAmount);
        assertEq(agentToken.balanceOf(creator), initialHalfTax + newHalfTax);
        assertEq(agentToken.balanceOf(dao), (initialTaxAmount - initialHalfTax) + (newTaxAmount - newHalfTax));
    }

    // Test transfer with taxable contract status change
    function testTransferWithTaxableContractStatusChange() public {
        address sender = address(0x1234);
        address recipient = address(0x7890);
        uint256 transferAmount = 1000;
        uint256 allowedMint = 2000;

        // Mint tokens to the sender
        agentToken.setAllowedMint(sender, allowedMint);
        vm.prank(sender);
        agentToken.mint();

        // Update recipient address as a taxable contract
        agentToken.updateTaxableContract(recipient, true);

        // Initial transfer with tax enabled
        uint256 initialTaxAmount = (transferAmount * taxPercentage) / 10000;
        uint256 initialExpectedTransferAmount = transferAmount - initialTaxAmount;
        uint256 initialHalfTax = initialTaxAmount / 2;

        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient, initialExpectedTransferAmount);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, creator, initialHalfTax);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, dao, initialTaxAmount - initialHalfTax);

        vm.prank(sender);
        agentToken.transfer(recipient, transferAmount);

        // Update recipient address to not be taxable
        agentToken.updateTaxableContract(recipient, false);

        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient, transferAmount);

        vm.prank(sender);
        agentToken.transfer(recipient, transferAmount);

        // Assert that the recipient received the full transfer amount without tax
        assertEq(agentToken.balanceOf(recipient), initialExpectedTransferAmount + transferAmount);
        assertEq(agentToken.balanceOf(creator), initialHalfTax);
        assertEq(agentToken.balanceOf(dao), initialTaxAmount - initialHalfTax);
    }

    // Test minting with zero allowed amount
    function testMintWithZeroAllowedAmount() public {
        address account = address(0x5678);

        vm.expectRevert("No allowed mint amount");
        vm.prank(account);
        agentToken.mint();
    }

    // Test minting with exact max supply
    function testMintWithExactMaxSupply() public {
        address account = address(0x5678);

        agentToken.setAllowedMint(account, maxSupply);
        vm.prank(account);
        agentToken.mint();

        assertEq(agentToken.totalSupply(), maxSupply);
    }

    // Test setting token URI to an empty string
    function testSetTokenURIToEmptyString() public {
        agentToken.setTokenURI("");
        assertEq(agentToken.tokenURI(), "");
    }

    // Test setting token URI to a long string
    function testSetTokenURIToLongString() public {
        string memory longURI = "https://this-is-a-very-long-token-uri.com/with/a/lot/of/segments/and/parameters";
        agentToken.setTokenURI(longURI);
        assertEq(agentToken.tokenURI(), longURI);
    }

    // Test unauthorized access to setAllowedMint
    function testUnauthorizedSetAllowedMint() public {
        address nonOwner = address(0x1234);
        address account = address(0x5678);
        uint256 allowedAmount = 1000;

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        agentToken.setAllowedMint(account, allowedAmount);
    }

    // Test updating taxable contract status to the same value
    function testUpdateTaxableContractToSameValue() public {
        address contractAddress = address(0x1111);

        agentToken.updateTaxableContract(contractAddress, true);
        assertTrue(agentToken.isContractTaxable(contractAddress));

        // Update to the same value
        agentToken.updateTaxableContract(contractAddress, true);
        assertTrue(agentToken.isContractTaxable(contractAddress));
    }

    // Test marking multiple addresses as taxable and verifying tax application
    function testMultipleTaxableAddresses() public {
        address sender = address(0x1234);
        address recipient1 = address(0x7890);
        address recipient2 = address(0x5678);
        uint256 transferAmount = 1000;
        uint256 allowedMint = 2000;

        // Mint tokens to the sender
        agentToken.setAllowedMint(sender, allowedMint);
        vm.prank(sender);
        agentToken.mint();

        // Update multiple recipient addresses as taxable contracts
        agentToken.updateTaxableContract(recipient1, true);
        agentToken.updateTaxableContract(recipient2, true);

        // Transfer to recipient1 and check tax application
        uint256 taxAmount1 = (transferAmount * taxPercentage) / 10000;
        uint256 expectedTransferAmount1 = transferAmount - taxAmount1;
        uint256 halfTax1 = taxAmount1 / 2;

        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient1, expectedTransferAmount1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, creator, halfTax1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, dao, taxAmount1 - halfTax1);

        vm.prank(sender);
        agentToken.transfer(recipient1, transferAmount);

        // Check balances after transfer to recipient1
        assertEq(agentToken.balanceOf(recipient1), expectedTransferAmount1);
        assertEq(agentToken.balanceOf(creator), halfTax1);
        assertEq(agentToken.balanceOf(dao), taxAmount1 - halfTax1);

        // Transfer to recipient2 and check tax application
        uint256 taxAmount2 = (transferAmount * taxPercentage) / 10000;
        uint256 expectedTransferAmount2 = transferAmount - taxAmount2;
        uint256 halfTax2 = taxAmount2 / 2;

        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient2, expectedTransferAmount2);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, creator, halfTax2);
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, dao, taxAmount2 - halfTax2);

        vm.prank(sender);
        agentToken.transfer(recipient2, transferAmount);

        // Check balances after transfer to recipient2
        assertEq(agentToken.balanceOf(recipient2), expectedTransferAmount2);
        assertEq(agentToken.balanceOf(creator), halfTax1 + halfTax2);
        assertEq(agentToken.balanceOf(dao), (taxAmount1 - halfTax1) + (taxAmount2 - halfTax2));
    }
}
