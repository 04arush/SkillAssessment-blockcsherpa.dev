// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract PropertyRegistry {

    // ===================== State Variables ====================

    struct Property {
        string propertyAddress;
        address owner;
        uint256 price;
        bool exists;
    }

    mapping(uint256 => Property) private properties;
    uint256 private nextPropertyId;


    // ========================= Events =========================

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


    // ========================= Errors =========================

    error PropertyDoesNotExist(uint256 propertyId);
    error NotPropertyOwner(uint256 propertyId, address caller);
    error InvalidAddress();


    // ======================== Functions =======================

    // ------------------- External Functions -------------------

    /**
     * @notice Registers a new property on-chain and assigns ownership to the caller.
     * @dev Increments `nextPropertyId` and stores the property in the `properties` mapping. Also, Emits {PropertyRegistered}.
     * @param _address Physical address of the property.
     * @param _price Listing price of the property in wei.
     * @return propertyId The unique ID assigned to the newly registered property.
     */
    function registerProperty(
        string memory _address,
        uint256 _price
    ) external returns (uint256) {

        uint256 propertyId = nextPropertyId++;
        properties[propertyId] = Property(_address, msg.sender, _price, true);
        emit PropertyRegistered(propertyId, msg.sender, _address, _price);
        
        return propertyId;
    }

    /**
     * @notice Transfers ownership of a registered property to a new address.
     * @dev Caller must be the current owner. Reverts with {NotPropertyOwner} if not, {PropertyDoesNotExist} if the ID is invalid, or {InvalidAddress} if `_newOwner` is the zero address. Emits {OwnershipTransferred}.
     * @param _propertyId The ID of the property to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(
        uint256 _propertyId,
        address _newOwner
    ) external {

        if (_newOwner == address(0)) revert InvalidAddress();
        Property storage prop = properties[_propertyId];

        if (!prop.exists) revert PropertyDoesNotExist(_propertyId);
        if (msg.sender != prop.owner) revert NotPropertyOwner(_propertyId, msg.sender);

        address previousOwner = prop.owner;
        prop.owner = _newOwner;
        emit OwnershipTransferred(_propertyId, previousOwner, _newOwner);
    }

    /**
     * @notice Returns the full details of a registered property.
     * @dev Reverts with {PropertyDoesNotExist} if `_propertyId` has not been registered.
     * @param _propertyId The ID of the property to retrieve.
     * @return A `Property` struct containing the address, owner, price, and existence flag.
     */
    function getProperty(
        uint256 _propertyId
    ) external view returns (Property memory) {
        
        if (!properties[_propertyId].exists) revert PropertyDoesNotExist(_propertyId);
        return properties[_propertyId];
    }

    /**
     * @notice Returns the next property ID that will be assigned on the next registration.
     * @dev Equivalent to the total number of properties registered so far.
     * @return The current value of `nextPropertyId`.
     */
    function getNextPropertyCount() external view returns (uint256) {
        return nextPropertyId;
    }
}