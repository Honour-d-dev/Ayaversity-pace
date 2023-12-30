import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { Lock, LockV2 } from "../typechain-types";

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployLock() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

    const lockedAmount = ONE_GWEI;
    const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Lock = await ethers.getContractFactory("Lock");
    const lock = (await upgrades.deployProxy(Lock, [
      unlockTime,
    ])) as unknown as Lock; //neccessary type fix

    return { lock, unlockTime, lockedAmount, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set the right unlockTime", async function () {
      const { lock, unlockTime } = await loadFixture(deployLock);

      expect((await lock.getVault(0)).unlockTime).to.equal(unlockTime);
    });

    it("Should set the right owner", async function () {
      const { lock, owner } = await loadFixture(deployLock);

      expect((await lock.getVault(0)).owner).to.equal(owner.address);
    });

    it("Should fail if the unlockTime is not in the future", async function () {
      // We don't use the fixture here because we want a different deployment
      const latestTime = await time.latest();
      const Lock = await ethers.getContractFactory("Lock");
      await expect(upgrades.deployProxy(Lock, [latestTime])).to.be.revertedWith(
        "Unlock time should be in the future"
      );
    });
  });

  describe("Upgradeability", function () {
    async function upgrade() {
      const { lock } = await loadFixture(deployLock);
      const LockV2 = await ethers.getContractFactory("LockV2");
      const lockAddress = await lock.getAddress();
      const lockV2 = (await upgrades.upgradeProxy(
        lockAddress,
        LockV2
      )) as unknown as LockV2;
      await lockV2.waitForDeployment();

      return { lockV2 };
    }
    it("should upgrade implementation address", async function () {
      const { lock } = await loadFixture(deployLock);
      const prevImplementation =
        await upgrades.erc1967.getImplementationAddress(
          await lock.getAddress()
        );
      const { lockV2 } = await loadFixture(upgrade);
      const newImplementation = await upgrades.erc1967.getImplementationAddress(
        await lockV2.getAddress()
      );
      expect(lock.target).to.equal(lockV2.target);
      expect(prevImplementation).to.not.equal(newImplementation);
    });

    it("should call upgraded methods sucessfully", async function () {
      const { lockV2 } = await loadFixture(upgrade);
      const unlockTime = (await time.latest()) + 60 * 60; //1 hr
      await lockV2.addVault(unlockTime, { value: 10_000_000_000 }); //10 gwei
      expect((await lockV2.getVault(1)).unlockTime).to.equal(unlockTime);
      expect((await lockV2.getVault(1)).value).to.equal(10_000_000_000);
    });
  });
});
