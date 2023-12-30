import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { type BaseContract } from "ethers";

//helper function for getting function sellectors
function getSelectors(contract: BaseContract) {
  const selectors: string[] = [];
  contract.interface.forEachFunction((fn) => {
    selectors.push(fn.selector);
  });
  return selectors;
}

describe("Diamond", function () {
  async function deployDiamond() {
    const [diamondOwner] = await ethers.getSigners();

    //deploy all the contrcts
    const diamond = await ethers.deployContract("Diamond", [
      diamondOwner.address,
    ]);
    const lockFacet = await ethers.deployContract("LockFacet");
    const facet2 = await ethers.deployContract("Facet2");

    //await their deployment
    await diamond.waitForDeployment();
    await lockFacet.waitForDeployment();
    await facet2.waitForDeployment();

    return { diamond, lockFacet, facet2, diamondOwner };
  }

  describe("facet cuts", function () {
    async function facetCut() {
      const { diamond, lockFacet, facet2 } = await loadFixture(deployDiamond);
      const unlockTime = (await time.latest()) + 60 * 60;

      await diamond.diamondCut(
        {
          facetAddress: lockFacet.target,
          functionSelectors: getSelectors(lockFacet),
        },
        lockFacet.target,
        lockFacet.interface.encodeFunctionData("initialize", [unlockTime])
      );

      await diamond.diamondCut(
        {
          facetAddress: facet2.target,
          functionSelectors: getSelectors(facet2),
        },
        ethers.ZeroAddress,
        "0x"
      );
    }

    it("should have lock facet and function selectors", async function () {
      const { diamond, diamondOwner } = await loadFixture(deployDiamond);
      await loadFixture(facetCut);
      const unlockTime = (await time.latest()) + 60 * 60;
      const lockFacet = await ethers.getContractAt("LockFacet", diamond.target);

      expect(
        await lockFacet.addVault({
          owner: diamondOwner,
          unlockTime,
          value: 1_000_000_000n,
        })
      ).to.not.be.reverted;
    });

    it("should have second facet and function selectors", async function () {
      const { diamond } = await loadFixture(deployDiamond);
      await loadFixture(facetCut);
      const facet2 = await ethers.getContractAt("Facet2", diamond.target);

      expect(await facet2.test1Func1()).to.not.be.reverted;
      expect(await facet2.test1Func2()).to.equal(diamond.target);
    });
  });
});
