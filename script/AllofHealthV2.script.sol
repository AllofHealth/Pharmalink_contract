// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AllofHealthv2} from "../src/AllofHealthV2.sol";
import {Script} from "forge-std/Script.sol";

contract Deployer is Script {
    AllofHealthv2 allofHealth;

    function run() external returns (AllofHealthv2) {
        vm.startBroadcast();
        allofHealth = new AllofHealthv2();
        vm.stopBroadcast();

        return allofHealth;
    }
}
