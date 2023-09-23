// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "./AxiomV2Client.sol";

contract ProofOfIntegrity {

    mapping(address => mapping(uint => uint)) private bundleSizeMap;
    mapping(address => mapping(uint => bytes)) private bundleHash;
    mapping(address => mapping(uint => uint256)) bundleIndexMap;
    mapping(address => bool) whitelist;

    // Only called by verifyBundle
    mapping(address => mapping(uint => bool)) private bundleVerificationMap;

    error InvalidBlockBuilder(address sender);
    error InvalidContractDeployer(address sender);
    error InvalidBundleSize(uint256 size, uint256 actualSize);
    error InvalidBundleHash(bytes calculatedHash, bytes actualHash);
    error BundleVerificationFailed(address sender, uint blockNumber);


    address _deployer;

    constructor(address deployer_) {
      _deployer = deployer_;
    }

    function deployer() public view returns(address) {
        return _deployer;
    }

    modifier onlyBlockBuilder() {
        if(!whitelist[msg.sender]) {
            revert InvalidBlockBuilder(msg.sender);
        }
        _;
    }

    modifier onlyDeployer() {
      if(msg.sender != _deployer) {
        revert InvalidContractDeployer(msg.sender);
      }
      _;
    }

    function addBlockBuilder(address blockBuilderAddress) external {
      whitelist[blockBuilderAddress] = true;
    }

    function verifyBundle(bytes[] calldata txs, address sender, uint blockNumber, bytes calldata calculatedHash) 
        external
        onlyBlockBuilder 
        returns(uint256 bundleIndex) 
    {
        uint size = bundleSizeMap[sender][blockNumber];
        bytes memory hash = bundleHash[sender][blockNumber];

        if(size != txs.length) {
            revert InvalidBundleSize(size, txs.length);
        }
        if(keccak256(calculatedHash) != keccak256(hash)) {
            revert InvalidBundleHash(calculatedHash, hash); // too much data to post
        }

        bundleVerificationMap[sender][blockNumber] = true;

        return bundleIndexMap[sender][blockNumber];
    }

    function stamp(bytes[] calldata txs, uint blockNumber, uint bundleIndex) public {
        bundleSizeMap[msg.sender][blockNumber] = txs.length;


        // bundleHash[msg.sender][blockNumber] = keccak256(txs);
        assembly { 
            let ptr := mload(0x40)
            calldatacopy(ptr, sub(calldatasize(), 48), 48)
            mstore(0x00, caller())
            mstore(0x20, 0x1) // bundleHash slot
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, blockNumber)
            sstore(keccak256(0x00, 0x40), mload(ptr))
        }

        // Optionally allow the sender to specify the index on a block
        // If it's zero, no block slot preference is expressed
        if (bundleIndex != 0) {
            bundleIndexMap[msg.sender][blockNumber] = bundleIndex;
        }

        if(!bundleVerificationMap[msg.sender][blockNumber]) {
            revert BundleVerificationFailed(msg.sender, blockNumber);
        }
    }
}
