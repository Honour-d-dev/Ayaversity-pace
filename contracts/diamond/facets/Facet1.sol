// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

struct Vault {
  address payable owner;
  uint value;
  uint unlockTime;
}

library LockLibrary {
  bytes32 constant LOCK_STORAGE_POSITION = keccak256("diamond.standard.lock.storage");

  event Withdrawal(uint amount, uint when);

  struct LockStorage {
    Vault[] vaults;
  }

  function lockStorage() internal pure returns (LockStorage storage ds) {
    bytes32 position = LOCK_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function addVault(Vault memory vault) internal {
    LockStorage storage ls = lockStorage();
    ls.vaults.push(vault);
  }

  function withdraw(uint idx) internal {
    LockStorage storage ls = lockStorage();
    Vault storage vault = ls.vaults[idx];

    require(block.timestamp >= vault.unlockTime, "You can't withdraw yet");
    require(msg.sender == vault.owner, "You aren't the owner");

    emit Withdrawal(address(this).balance, block.timestamp);

    vault.owner.transfer(address(this).balance);
  }

  function getVault(uint idx) internal view returns (Vault memory) {
    LockStorage storage ls = lockStorage();
    return ls.vaults[idx];
  }
}

contract LockFacet is Initializable {
  function initialize(uint _unlockTime) public payable initializer {
    require(block.timestamp < _unlockTime, "Unlock time should be in the future");

    LockLibrary.addVault(Vault(payable(msg.sender), msg.value, _unlockTime));
  }

  function withdraw(uint idx) public {
    LockLibrary.withdraw(idx);
  }

  function addVault(Vault memory vault) public {
    LockLibrary.addVault(vault);
  }

  function getVault(uint idx) external view returns (Vault memory) {
    return LockLibrary.getVault(idx);
  }
}
