// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";
import { PropertyRegistry } from "../src/PropertyRegistry.sol";

contract PropertyRegistryTest is Test {
    PropertyRegistry public registry;

    address public owner = makeAddr("owner");
    address public buyer = makeAddr("buyer");

    event PropertyRegistered(
        uint256 indexed propertyId,
        address indexed owner,
        string propertyAddress,
        uint256 price
    );

    event OwnershipTransferred(
        uint256 indexed propertyId,
        address indexed previousOwner,
        address indexed newOwner
    );

    function setUp() public {
        registry = new PropertyRegistry();
    }


    // --- Registration --------------------------------------------------------

    function test_RegisterProperty_StoresCorrectData() public {
        vm.prank(owner);
        uint256 id = registry.registerProperty("123 NYC", 500_000e18);

        PropertyRegistry.Property memory prop = registry.getProperty(id);
        assertEq(prop.propertyAddress, "123 NYC");
        assertEq(prop.owner, owner);
        assertEq(prop.price, 500_000e18);
        assertTrue(prop.exists);
    }

    function test_RegisterProperty_EmitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit PropertyRegistered(0, owner, "123 NYC", 500_000e18);
        registry.registerProperty("123 NYC", 500_000e18);
    }

    function test_RegisterProperty_IncrementsId() public {
        vm.startPrank(owner);
        uint256 id0 = registry.registerProperty("Addr A", 100e18);
        uint256 id1 = registry.registerProperty("Addr B", 200e18);
        vm.stopPrank();

        assertEq(id0, 0);
        assertEq(id1, 1);
        assertEq(registry.getNextPropertyCount(), 2);
    }


    // --- Ownership Transfer ----------------------------------------------
    
    function test_TransferOwnership_UpdatedOwner() public {
        vm.prank(owner);
        uint256 id = registry.registerProperty("123 NYC", 500_000e18);

        vm.prank(owner);
        registry.transferOwnership(id, buyer);

        PropertyRegistry.Property memory prop = registry.getProperty(id);
        assertEq(prop.owner, buyer);
    }

    function test_TransferOwnership_EmitsEvent() public {
        vm.prank(owner);
        uint256 id = registry.registerProperty("123 NYC", 500_000e18);

        vm.prank(owner);
        vm.expectEmit(true, true, true, false);
        emit OwnershipTransferred(id, owner, buyer);
        registry.transferOwnership(id, buyer);
    }



    // --- Access Control ------------------------------------------------------

    function test_RevertWhen_NonOwnerTransfers() public {
        vm.prank(owner);
        uint256 id = registry.registerProperty("123 NYC", 500_000e18);

        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(PropertyRegistry.NotPropertyOwner.selector, id, buyer)
        );
        registry.transferOwnership(id, buyer);
    }

    function test_RevertWhen_TransferToZeroAddress() public {
        vm.prank(owner);
        uint256 id = registry.registerProperty("123 NYC", 500_000e18);

        vm.prank(owner);
        vm.expectRevert(PropertyRegistry.InvalidAddress.selector);
        registry.transferOwnership(id, address(0));
    }

    function test_RevertWhen_GetNonExistentProperty() public {
        vm.expectRevert(
            abi.encodeWithSelector(PropertyRegistry.PropertyDoesNotExist.selector, 999)
        );
        registry.getProperty(999);
    }

    function test_RevertWhen_TransferNonExistentProperty() public {
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(PropertyRegistry.PropertyDoesNotExist.selector, 999)
        );
        registry.transferOwnership(999, buyer);
    }


    // --- Fuzz Tests ----------------------------------------------------------

    function testFuzz_RegisterProperty_PriceAlwaysMatches(
        uint256 price,
        string memory addr
    ) public {
        vm.prank(owner);
        uint256 id = registry.registerProperty(addr, price);
        assertEq(registry.getProperty(id).price, price);
    }

    function testFuzz_OnlyOwnerCanTransfer(address attacker) public {
        vm.assume(attacker != owner && attacker != address(0));
        vm.prank(owner);
        uint256 id = registry.registerProperty("123 NYC", 100e18);

        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(PropertyRegistry.NotPropertyOwner.selector, id, attacker)
        );
        registry.transferOwnership(id, attacker);
    }
}