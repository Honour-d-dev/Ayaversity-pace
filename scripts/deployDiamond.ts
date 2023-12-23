import { type BaseContract } from "ethers";
import { ethers } from "hardhat";

//helper function for getting function sellectors
function getSelectors(contract: BaseContract) {
  const selectors: string[] = [];
  contract.interface.forEachFunction((fn) => {
    selectors.push(fn.selector);
  });
  return selectors;
}

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

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

  //add facets to the diamond
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

  //calling the lockFacet addVault function
  const lockDiamond = await ethers.getContractAt("LockFacet", diamond.target);
  const tx = await lockDiamond.addVault({
    owner: diamondOwner,
    unlockTime,
    value: 0n,
  });

  console.log(
    `diamond address is ${diamond.target}\n lockFacet address is ${lockFacet.target}\n facet2 address is ${facet2.target}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
