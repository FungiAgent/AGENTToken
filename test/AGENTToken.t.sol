// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {AGENTToken} from "src/AGENTToken.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {DeployAGENT} from "script/DeployAGENT.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract AGENTTokenTest is Test {
    DeployAGENT deployAgent;
    AGENTToken agentToken;
    address public owner;
    uint256 public maxSupply = 999999999;
    string public uri = "https://token-uri.com";
    uint256 public taxPercentage = 100;
    address public taxRecipient;

    function setUp() public {
        owner = address(this);
        taxRecipient = address(this);
        agentToken = new AGENTToken(owner, maxSupply, uri, taxPercentage, taxRecipient);
    }

    // Test the constructor sets correct initial parameters
    function testConstructorSetsCorrectInitialParameters() public {
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

        agentToken.updateTaxableContract(contractAddress, true);
        assertTrue(agentToken.isContractTaxable(contractAddress));

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
        assertEq(agentToken.balanceOf(taxRecipient), 0);

        // Transfer tokens
        uint256 taxAmount = (transferAmount * taxPercentage) / 10000; // 1% of 1000 = 10
        uint256 expectedTransferAmount = transferAmount - taxAmount;

        vm.prank(sender);
        agentToken.transfer(recipient, transferAmount);

        // Check final balances
        assertEq(agentToken.balanceOf(sender), 0);
        assertEq(agentToken.balanceOf(recipient), expectedTransferAmount);
        assertEq(agentToken.balanceOf(taxRecipient), taxAmount);
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
        assertEq(agentToken.balanceOf(taxRecipient), 0);

        // Transfer tokens
        vm.prank(sender);
        agentToken.transfer(recipient, transferAmount);

        // Check final balances
        assertEq(agentToken.balanceOf(sender), 0);
        assertEq(agentToken.balanceOf(recipient), transferAmount);
        assertEq(agentToken.balanceOf(taxRecipient), 0);
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
        assertEq(agentToken.balanceOf(taxRecipient), 0);
        assertEq(agentToken.allowance(sender, spender), transferAmount);

        // Transfer tokens
        uint256 taxAmount = (transferAmount * taxPercentage) / 10000; // 1% of 1000 = 10
        uint256 expectedTransferAmount = transferAmount - taxAmount;

        agentToken.transferFrom(sender, recipient, transferAmount);

        // Check final balances and remaining allowance
        assertEq(agentToken.balanceOf(sender), 0);
        assertEq(agentToken.balanceOf(recipient), expectedTransferAmount);
        assertEq(agentToken.balanceOf(taxRecipient), taxAmount);
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
        assertEq(agentToken.balanceOf(taxRecipient), 0);
        assertEq(agentToken.allowance(sender, spender), transferAmount);

        // Transfer tokens
        agentToken.transferFrom(sender, recipient, transferAmount);

        // Check final balances and remaining allowance
        assertEq(agentToken.balanceOf(sender), 0);
        assertEq(agentToken.balanceOf(recipient), transferAmount);
        assertEq(agentToken.balanceOf(taxRecipient), 0);
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

    // // Test the permit functionality
    // function testPermit() public {
    //     address owner = address(0x1234);
    //     address spender = address(0x5678);
    //     uint256 value = 1000;
    //     uint256 deadline = block.timestamp + 1 hours;

    //     // Create a new wallet for signing
    //     address signerWallet = vm.addr(1);

    //     // Mint tokens to the owner
    //     agentToken.setAllowedMint(owner, value);
    //     vm.prank(owner);
    //     agentToken.mint();

    //     // Create the permit signature
    //     uint256 nonce = agentToken.nonces(owner);
    //     bytes32 hashStruct = keccak256(
    //         abi.encode(
    //             keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
    //             owner,
    //             spender,
    //             value,
    //             nonce,
    //             deadline
    //         )
    //     );
    //     bytes32 digest = keccak256(abi.encodePacked("\x19\x01", agentToken.DOMAIN_SEPARATOR(), hashStruct));

    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerWallet, digest);

    //     // Permit the spender
    //     agentToken.permit(owner, spender, value, deadline, v, r, s);

    //     // Check the allowance
    //     assertEq(agentToken.allowance(owner, spender), value);
    //     assertEq(agentToken.nonces(owner), nonce + 1);
    // }

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

        vm.expectRevert("Tax recipient cannot be zero address");
        agentToken.updateTaxRecipient(zeroAddress);
    }

    // Test setting the tax recipient to a valid address
    function testSetTaxRecipientToValidAddress() public {
        address newTaxRecipient = address(0x1234);

        agentToken.updateTaxRecipient(newTaxRecipient);
        assertEq(agentToken.getTaxRecipient(), newTaxRecipient);
    }

    // Test enabling and disabling the tax
    function testEnableAndDisableTax() public {
        // Initially, the tax should be enabled
        assertTrue(agentToken.isTaxEnabled());

        // Disable the tax
        agentToken.flipTaxStatus();
        assertFalse(agentToken.isTaxEnabled());

        // Enable the tax
        agentToken.flipTaxStatus();
        assertTrue(agentToken.isTaxEnabled());
    }
}
