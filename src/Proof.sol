// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "./AxiomV2Client.sol";

contract ProofOfIntegrity is AxiomV2Client {

    mapping(address => mapping(uint => uint)) private bundleSizeMap;
    mapping(address => mapping(uint => uint256)) bundleIndexMap;
    mapping(address => bool) whitelist;
    mapping(address => uint) stakeMap;
    mapping(address => mapping(uint => address)) private bundleVerificationMap;

    error InvalidBlockBuilder(address sender);
    error InvalidContractDeployer(address sender);
    error InvalidBundleSize(uint256 size, uint256 actualSize);
    error BundleVerificationFailed(address sender, uint bundleSize, uint bundleIndex);
    error ChallengeFailed(address caller, address blockBuilderAddress);

    event ChallengeSuccess(address caller, uint amount, address blockBuilderAddress);

    address _deployer;

    constructor(
        address deployer_,
        address _axiomV2QueryAddress
    ) AxiomV2Client(_axiomV2QueryAddress) {
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

    function checkStake(address blockBuilderAddress) view public returns(uint stakeAmount) {
      stakeAmount = stakeMap[blockBuilderAddress];
    }

    function checkBundleSize(address senderAddress, uint blockNumber) view public returns(uint256 bundleSize){
      bundleSize = bundleSizeMap[senderAddress][blockNumber];
    }

    function checkBundleVerifier(address senderAddress, uint blockNumber) view public returns(address bundleVerifier){
      bundleVerifier = bundleVerificationMap[senderAddress][blockNumber];
    }

    function checkBundleIndex(address senderAddress, uint blockNumber) view public returns(uint256 bundleIndex){
      bundleIndex = bundleIndexMap[senderAddress][blockNumber];
    }

    function stake() onlyBlockBuilder payable external {
      stakeMap[msg.sender] += msg.value;
    }


    function addBlockBuilder(address blockBuilderAddress) onlyDeployer external {
      whitelist[blockBuilderAddress] = true;
    }

    function verifyBundle(uint bundleSize, address sender, uint blockNumber, uint bundleIndex) external
        onlyBlockBuilder 
    {
      require(blockNumber == block.number, "blockNumber has to be the current block number");
      require(bundleIndex > 0, "bundle index has to be larger than 0");

      // Block builder needs to specify exactly where the bundle is placed
      // otherwise he/she will fail the challenge later and be slashed
      bundleIndexMap[sender][blockNumber] = bundleIndex;
      // record the block builder address as the value in bundleVerificationMap
      bundleVerificationMap[sender][blockNumber] = msg.sender;
    }

    // This function will run twice: once during simulation by the block builder, then on-chain
    // this function will revert during the simulation stage using `eth_call` so that the block builder can know the `bundleIndex` and can verify the `bundleSize`
    // during on-chain execution, this function will revert if the block builder does not include a `verifyBundle` before the `stampBundle()`
    // 
    // If user don't care about the bundleIndex, it should be 0
    function stampBundle(uint bundleSize, uint blockNumber, uint bundleIndex) public {

      // Bundle index has to be larger than one since the top transaction has to be block builder's call to verifyBundle()
      require((bundleIndex == 0 
              || bundleIndex > 1), "bundle index has to be larger than 1");
      bundleSizeMap[msg.sender][blockNumber] = bundleSize;

      // function always reverts without a block builder calling a verifyBundle first
      if(bundleVerificationMap[msg.sender][blockNumber] == address(0)) {
          // logs the  bundleIndex and bundleSize during the simulation using `eth_call`
          revert BundleVerificationFailed(msg.sender, bundleIndex, bundleSize);
      } else {
        // If bundleIndex is not set to zero, it means the sender has specified a particular index, so it checks whether the block builder has input the correct
        // index value in the bundleIndexMap
        if(bundleIndex != 0){
          require(bundleIndexMap[msg.sender][blockNumber] == bundleIndex, "wrong bundle index");
        }
      }
    }


    function _axiomV2Callback(
        uint64 sourceChainId,
        address callerAddr,
        bytes32 querySchema,
        bytes32 queryHash,
        bytes32[] calldata axiomResults,
        bytes calldata callbackExtraData
    ) internal virtual override {

      // minus one because bundle size is no. of tx in a bundle
      // E,g. if the top topTxIdx is 1, and bottom bottomTxIdx is 3, bundle size is 1
      // however the returned result is (bottomTxIdx - topTxIdx) = 2
      uint256 bundleSize = uint256(axiomResults[0]) - 1;
      // minus one because the returned index is the block builder's tx
      uint256 indexNumber = uint256(axiomResults[1]) - 1;
      uint256 blockNumber = uint256(axiomResults[2]);
      address senderAddress = address(uint160(uint256(axiomResults[3])));

      address blockBuilderAddress = bundleVerificationMap[senderAddress][blockNumber];

      require(bundleSizeMap[senderAddress][blockNumber] != 0, "ProofOfIntegrity: wrong senderAddress or blockNumber");
      require(bundleIndexMap[senderAddress][blockNumber] != 0, "ProofOfIntegrity: wrong senderAddress or blockNumber");

      if(
          bundleSize != bundleSizeMap[senderAddress][blockNumber] || 
          indexNumber != bundleIndexMap[senderAddress][blockNumber]
      ){
        uint256 amount = stakeMap[blockBuilderAddress];
        stakeMap[blockBuilderAddress] = 0;
        (bool success, ) = callerAddr.call{value: amount}("");
        require(success, "ProofOfIntegrity: failed to transfer funds");
        emit ChallengeSuccess(
            callerAddr,
            amount,
            blockBuilderAddress
        );
      } else {
        revert ChallengeFailed(callerAddr, blockBuilderAddress);
      }
    }
}
