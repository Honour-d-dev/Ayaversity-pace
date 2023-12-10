// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import {Lock} from "./Lock.sol";

contract LockV2 is Lock {
  event NewVault(uint indexed index);

  function addVault(uint unlockTime) external payable {
    require(block.timestamp < unlockTime, "Unlock time should be in the future");

    emit NewVault(vaults.length);
    vaults.push(Vault(payable(msg.sender), msg.value, unlockTime));
  }
}
