// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {AGENTToken} from "src/AGENTToken.sol";

contract DeployAGENT is Script {
    address public owner = msg.sender;
    uint256 public maxSupply = 999999999;
    string public uri = "https://token-uri.com";
    uint256 public taxPercentage = 100;
    address public taxRecipient = msg.sender;

    function run() external {
        vm.startBroadcast();
        new AGENTToken(owner, maxSupply, uri, taxPercentage, taxRecipient);
        vm.stopBroadcast();
    }
}
