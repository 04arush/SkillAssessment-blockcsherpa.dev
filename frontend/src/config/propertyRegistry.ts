export const PROPERTY_REGISTRY_ADDRESS = "0xe3B492286030B7230d121A03a68F7cA80744E892";

export const PROPERTY_REGISTRY_ABI = [
    "function registerProperty(string memory _address, uint256 _price) external returns (uint256)",
    "function getProperty(uint256 _propertyId) external view returns (tuple(string propertyAddress, address owner, uint256 price, bool exists))",
    "event PropertyRegistered(uint256 indexed propertyId, address indexed owner, string propertyAddress, uint256 price)"
];

export const AMOY_CHAIN_ID = "0x13882";     // hex of 80002