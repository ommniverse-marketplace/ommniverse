import { ethers, upgrades } from "hardhat";

async function main() {
  const NFTFactoryV2 = await ethers.getContractFactory(
    "NonFungibleCollectionV2"
  );

  const NFTFactoryAddress = ""; // NonFungibleCollection {proxy address}. Not implementation address

  console.log("Upgrading NFTFactory to V2");
  const nftFactoryV2 = await upgrades.upgradeBeacon(
    NFTFactoryAddress,
    NFTFactoryV2
  );
  await nftFactoryV2.deployed();
  console.log(`NFTFactoryV2 Upgraded!!!!`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
