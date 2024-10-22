// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {AGENTToken} from "src/AGENTToken.sol";

contract DeployAGENT is Script {
    address public owner = msg.sender;
    string public name = "AGENT Token";
    string public symbol = "AGENT";
    uint256 public maxSupply = 999999999;
    string public uri = "https://token-uri.com";
    uint256 public taxPercentage = 100;
    address public creator = 0x1234567890AbcdEF1234567890aBcdef12345678; // Replace with actual creator address
    address public dao = 0xabCDEF1234567890ABcDEF1234567890aBCDeF12; // Replace with actual DAO address

    function run() external {
        vm.startBroadcast();
        new AGENTToken(owner, name, symbol, maxSupply, uri, taxPercentage, creator, dao);
        vm.stopBroadcast();
    }
}
