// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AGENTToken.sol";

contract AGENTTokenTest is Test {
    AGENTToken private agentToken;
    address private owner = address(0x123);
    address private taxDestination = address(0x456);
    address private recipient = address(0x789);
    address private exemptedAccount = address(0xAAA);

    function setUp() public {
        agentToken = new AGENTToken(
            owner,
            1000000, // initialSupply
            "https://token.uri",
            true, // __taxed
            100, // __thetax (1%)
            200, // __maxtax (2%)
            50, // __mintax (0.5%)
            taxDestination
        );
    }

    function testInitialState() public view {
        assertEq(agentToken.name(), "AGENT Token");
        assertEq(agentToken.symbol(), "AGENT");
        assertEq(agentToken.totalSupply(), 1000000 * 10 ** agentToken.decimals());
        assertEq(agentToken.tokenURI(), "https://token.uri");
        assertEq(agentToken.thetax(), 100);
        assertEq(agentToken.taxdestination(), taxDestination);
    }

    function testSetTokenURI() public {
        vm.prank(owner);
        agentToken.setTokenURI("https://new.token.uri");
        assertEq(agentToken.tokenURI(), "https://new.token.uri");
    }

    function testUpdateTax() public {
        vm.prank(owner);
        agentToken.updateTax(150);
        assertEq(agentToken.thetax(), 150);
    }

    function testUpdateTaxDestination() public {
        address newDestination = address(0xBBB);
        vm.prank(owner);
        agentToken.updateTaxDestination(newDestination);
        assertEq(agentToken.taxdestination(), newDestination);
    }

    function testTaxExemption() public {
        vm.prank(owner);
        agentToken.setTaxExemption(exemptedAccount, true);
        assertTrue(agentToken.isExemptFromTax(exemptedAccount));

        vm.prank(owner);
        agentToken.setTaxExemption(exemptedAccount, false);
        assertFalse(agentToken.isExemptFromTax(exemptedAccount));
    }

    function testTaxOnAndOff() public {
        vm.prank(owner);
        agentToken.taxOn();
        assertTrue(agentToken.taxed());

        vm.prank(owner);
        agentToken.taxOff();
        assertFalse(agentToken.taxed());
    }

    function testTransferWithTax() public {
        // Transfer from owner to recipient with tax
        uint256 amount = 1000 * 10 ** agentToken.decimals();
        uint256 taxAmount = (amount * agentToken.thetax()) / 10000;

        vm.prank(owner);
        agentToken.transfer(recipient, amount);

        assertEq(agentToken.balanceOf(recipient), amount - taxAmount);
        assertEq(agentToken.balanceOf(taxDestination), taxAmount);
    }

    function testTransferWithoutTax() public {
        // Transfer from exempted account to recipient without tax
        uint256 amount = 1000 * 10 ** agentToken.decimals();

        vm.prank(owner);
        agentToken.setTaxExemption(exemptedAccount, true);

        vm.prank(exemptedAccount);
        agentToken.transfer(recipient, amount);

        assertEq(agentToken.balanceOf(recipient), amount);
    }

    // function testMint() public {
    //     uint256 amount = 1000 * 10 ** agentToken.decimals();
    //     vm.prank(owner);
    //     agentToken._mint(owner, amount);
    //     assertEq(agentToken.totalSupply(), 1001000 * 10 ** agentToken.decimals());
    // }
}
