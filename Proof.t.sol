pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Proof.sol";

contract ContractBTest is Test {
    uint256 testNumber;
    address constant axiomV2QueryAddress = 0x8DdE5D4a8384F403F888E1419672D94C570440c9;
    address constant sender = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;
    address constant blockBuilder = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;

    ProofOfIntegrity proof;
    address deployer;


    function setUp() public {
      proof = new ProofOfIntegrity(address(this), axiomV2QueryAddress);
      proof.addBlockBuilder(blockBuilder);
    }

    function testGetDeployer() public {
      deployer = proof.deployer();
      assertEq(deployer, address(this));
    }

    function testFail_StampBundle() public {
      proof.stampBundle(1, 1, 0);
    }

    function testVerifyBundle() public {
      vm.roll(100);
      proof.verifyBundle(1, sender, 100, 1);
      uint bundleSize = proof.checkBundleIndex(sender, 100);
      assertEq(bundleSize, 1);
    }

}
