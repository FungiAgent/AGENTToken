// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "src/AGENTToken.sol";

contract DeployAGENT is Script {
    function run() external returns (AGENTToken) {
        vm.startBroadcast();

        /* 
            * Deploy AGENTToken contract
            * 
            * Parameters:
            * - owner: address of the contract owner
            * - maxSupply: maximum supply of the token
            * - uri: token URI (logo image)
            * - taxPercentage: tax percentage in basis points
            * - taxRecipient: address of the tax recipient
        */
        AGENTToken agentToken = new AGENTToken(address(this), 999999999, "https://token-uri.com", 100, address(0x4));
        vm.stopBroadcast();
        return agentToken;
    }
}
