// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Lock is Initializable {
  struct Vault {
    address payable owner;
    uint value;
    uint unlockTime;
  }

  Vault[] vaults;

  event Withdrawal(uint amount, uint when);

  function initialize(uint _unlockTime) public payable initializer {
    require(block.timestamp < _unlockTime, "Unlock time should be in the future");

    vaults.push(Vault(payable(msg.sender), msg.value, _unlockTime));
  }

  function withdraw(uint idx) public {
    // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
    // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);
    Vault storage vault = vaults[idx];

    require(block.timestamp >= vault.unlockTime, "You can't withdraw yet");
    require(msg.sender == vault.owner, "You aren't the owner");

    emit Withdrawal(address(this).balance, block.timestamp);

    vault.owner.transfer(address(this).balance);
  }
}
