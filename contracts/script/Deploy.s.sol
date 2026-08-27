// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Script, console } from "forge-std/Script.sol";
import { PropertyRegistry } from "../src/PropertyRegistry.sol";

contract DeployPropertyRegistry is Script {
    
    function run() external returns (PropertyRegistry) {
        vm.startBroadcast();
        PropertyRegistry registry = new PropertyRegistry();
        vm.stopBroadcast();

        console.log("PropertyRegistry deployed at: ", address(registry));
        return registry;
    }
}
