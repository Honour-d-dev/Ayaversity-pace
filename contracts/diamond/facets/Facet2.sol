// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Example library to show a simple example of diamond storage

library LibFacet2 {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.test.storage");

  struct TestState {
    address myAddress;
    uint256 myNum;
  }

  function diamondStorage() internal pure returns (TestState storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function setMyAddress(address _myAddress) internal {
    TestState storage testState = diamondStorage();
    testState.myAddress = _myAddress;
  }

  function getMyAddress() internal view returns (address) {
    TestState storage testState = diamondStorage();
    return testState.myAddress;
  }
}

contract Facet2 {
  event TestEvent(address something);

  function test1Func1() external {
    LibFacet2.setMyAddress(address(this));
  }

  function test1Func2() external view returns (address) {
    return LibFacet2.getMyAddress();
  }
}
