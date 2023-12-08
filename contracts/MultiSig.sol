// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {MultiSigBase} from "./MultiSigBase.sol";

contract MultiSig is MultiSigBase {
  uint private totalTxs;
  mapping(uint => Transaction) private transactions;
  mapping(uint => uint) private confirmationsCount;
  mapping(uint => mapping(address => bool)) private confirmations;

  constructor(address[] memory owners, uint required) MultiSigBase(owners, required) {}

  function transactionCount() external view override returns (uint) {
    return totalTxs;
  }

  function addTransaction(address _to, uint _value, bytes calldata _data) internal override returns (uint idx) {
    transactions[totalTxs] = Transaction(_to, _value, _data, false);
    idx = totalTxs;
    totalTxs++;
  }

  function confirmTransaction(uint id) public override onlyOwners {
    confirmations[id][msg.sender] = true;
    confirmationsCount[id]++;
    if (isConfirmed(id)) {
      executeTransaction(id);
    }
  }

  function executeTransaction(uint id) public override onlyOwners {
    require(isConfirmed(id));
    require(!transactions[id].executed);
    (bool sent, ) = payable(transactions[id].to).call{value: transactions[id].value}(transactions[id].data);
    require(sent);
    transactions[id].executed = true;
  }

  function getConfirmationsCount(uint id) public view override returns (uint) {
    return confirmationsCount[id];
  }

  function isConfirmed(uint id) public view override returns (bool) {
    return confirmationsCount[id] >= required;
  }
}
