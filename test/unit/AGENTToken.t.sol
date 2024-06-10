// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {AGENTToken} from "src/AGENTToken.sol";

contract AGENTTokenTest is Test {
    AGENTToken agentToken;
    address owner;
    address addr1;
    address addr2;
    address addr3;
    address taxRecipient;

    function setUp() public {
        owner = address(this);
        addr1 = address(0x1);
        addr2 = address(0x2);
        addr3 = address(0x3);
        taxRecipient = address(0x4);

        agentToken = new AGENTToken(owner, 1000000 * 10**18, "https://token-uri.com", 100, taxRecipient);
    }

    function testInitialSetup() public view {
        assertEq(agentToken.owner(), owner);
        assertEq(agentToken.getTaxPercentage(), 100);
        assertEq(agentToken.tokenURI(), "https://token-uri.com");
        assertEq(agentToken.getMaxSupply(), 1000000 * 10 ** 18);
    }

    function testSetTokenURI() public {
        vm.prank(owner);
        agentToken.setTokenURI("https://new-token-uri.com");
        assertEq(agentToken.tokenURI(), "https://new-token-uri.com");
    }

    function testTransferWithTax() public {
        vm.startPrank(owner);
        agentToken.mint();
        uint256 initialBalance = agentToken.balanceOf(addr1);
        uint256 taxAmount = 10 * 10 ** 18 / 100; // 10% of 10 tokens
        uint256 transferAmount = 10 * 10 ** 18 - taxAmount;

        agentToken.transfer(addr1, 10 * 10 ** 18);
        assertEq(agentToken.balanceOf(addr1), initialBalance + transferAmount);
        assertEq(agentToken.balanceOf(taxRecipient), taxAmount);
        vm.stopPrank();
    }

    function testSetAllowedMint() public {
        vm.prank(owner);
        agentToken.setAllowedMint(addr1, 500000 * 10 ** 18);
        assertEq(agentToken.getAllowedMint(addr1), 500000 * 10 ** 18);
    }

    function testMint() public {
        vm.startPrank(owner);
        agentToken.setAllowedMint(addr1, 500000 * 10 ** 18);
        vm.stopPrank();

        vm.prank(addr1);
        agentToken.mint();
        assertEq(agentToken.balanceOf(addr1), 500000 * 10 ** 18);
    }

    function testUpdateTaxableContract() public {
        vm.prank(owner);
        agentToken.updateTaxableContract(addr2, true);
        assertTrue(agentToken.isContractTaxable(addr2));
    }

    function testTransferFromWithTax() public {
        vm.startPrank(owner);
        agentToken.mint();
        agentToken.approve(addr2, 20 * 10 ** 18);
        vm.stopPrank();

        vm.prank(addr2);
        agentToken.transferFrom(owner, addr3, 20 * 10 ** 18);
        uint256 taxAmount = 20 * 10 ** 18 / 100; // 10% of 20 tokens
        uint256 transferAmount = 20 * 10 ** 18 - taxAmount;

        assertEq(agentToken.balanceOf(addr3), transferAmount);
        assertEq(agentToken.balanceOf(taxRecipient), taxAmount);
    }
}
