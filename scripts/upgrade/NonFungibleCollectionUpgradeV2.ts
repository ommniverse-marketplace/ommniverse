import { ethers, upgrades } from "hardhat";

async function main() {
  const NonFungibleCollectionV2 = await ethers.getContractFactory(
    "NonFungibleCollectionV2"
  );

  const NonFungibleCollectionAddress =
    ""; // NonFungibleCollection {proxy address}. Not implementation address

  console.log("Upgrading NonFungibleCollection to  V2");
  const nonFungibleCollectionV2 = await upgrades.upgradeProxy(
    NonFungibleCollectionAddress,
    NonFungibleCollectionV2
  );
  await nonFungibleCollectionV2.deployed();
  console.log(`NonFungibleCollectionV2 Upgraded!!!!`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
