import { formatEther, parseEther } from "viem";
import hre from "hardhat";

async function main() {
  const [owner] = await hre.viem.getWalletClients();
  const Aya = await hre.viem.deployContract("AYA", [owner.account.address]);
  await Aya.write.safeMint([
    owner.account.address,
    "QmVzgvNPUH32AySAcYzFEkYGYKTTRRb6Fuatg8Hv3NodPz",
  ]);

  const uri = await Aya.read.tokenURI([0n]);

  console.log(Aya.address, "\n", uri);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
