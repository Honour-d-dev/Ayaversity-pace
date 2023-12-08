// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract MultiSigBase {
  struct Transaction {
    address to;
    uint value;
    bytes data;
    bool executed;
  }

  uint public required;
  address[] public owners;
  mapping(address => bool) isOwner;

  constructor(address[] memory _owners, uint _required) payable {
    require(_owners.length > 0);
    require(_required > 0);
    require(_owners.length >= _required);

    for (uint i = 0; i < _owners.length; i++) {
      address owner = _owners[i];

      require(owner != address(0), "invalid owner");
      require(!isOwner[owner], "owner not unique");

      isOwner[owner] = true;
    }

    owners = _owners;
    required = _required;
  }

  function transactionCount() external view virtual returns (uint) {}

  function addTransaction(address _to, uint _value, bytes calldata _data) internal virtual returns (uint) {}

  function confirmTransaction(uint id) public onlyOwners {}

  function submitTransaction(address to, uint value, bytes calldata data) external {
    confirmTransaction(addTransaction(to, value, data));
  }

  function executeTransaction(uint id) public onlyOwners {}

  function getConfirmationsCount(uint id) public view returns (uint) {}

  function isConfirmed(uint id) public view returns (bool) {}

  modifier onlyOwners() {
    require(isOwner[msg.sender]);
    _;
  }

  receive() external payable {}
}
