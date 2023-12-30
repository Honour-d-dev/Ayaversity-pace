import { ethers, upgrades } from "hardhat";
import { Lock } from "../typechain-types";

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  const Lock = await ethers.getContractFactory("Lock");
  const LockV2 = await ethers.getContractFactory("LockV2");

  const lock = await upgrades.deployProxy(Lock, [unlockTime]);

  await lock.waitForDeployment();
  const lockAddress = await lock.getAddress();

  const lockV2 = await upgrades.upgradeProxy(lockAddress, LockV2);
  await lockV2.waitForDeployment();

  const lockV2Address = await lockV2.getAddress();

  console.log(
    `proxy deployed to ${lockAddress} \n implementation deployed to ${await upgrades.erc1967.getImplementationAddress(
      lockAddress
    )} \n admin deployed to ${await upgrades.erc1967.getAdminAddress(
      lockAddress
    )} \n
     V2 proxy deployed to ${lockV2Address} \n implementation deployed to ${await upgrades.erc1967.getImplementationAddress(
      lockV2Address
    )} \n admin deployed to ${await upgrades.erc1967.getAdminAddress(
      lockV2Address
    )}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
